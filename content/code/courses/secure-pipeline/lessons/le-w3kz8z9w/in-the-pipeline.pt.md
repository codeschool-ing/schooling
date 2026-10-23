---
title: Segredos primeiro no pipeline
version: 1
---

O servidor é onde a checagem é imposta: o hook pode ser pulado e a proteção de push da plataforma
pode nem existir, mas todo push chega à CI, e a CI guarda todos os branches. **O estágio varre o
histórico inteiro do commit enviado**, não só a mudança, então um segredo que chegou num merge, num
rebase ou num branch de alguém sem o hook é encontrado do mesmo jeito.

### O estágio

Salve como `ci/secrets.sh`:

```sh
# Secret scanning: every commit the repository holds, not only the files as
# they are now, because a secret deleted in a later commit is still in the
# history. A finding breaks the build. .gitleaksignore lists the findings
# that were rotated and are dead.
set -euo pipefail
gitleaks git --no-banner --no-color --redact --verbose .
```

`--redact` importa mais aqui do que em qualquer outro lugar. **Um log de CI é lido por todo mundo com
acesso aos builds do projeto, e muitas vezes é guardado por mais tempo que o código**, então um
scanner que imprimisse o segredo nele o publicaria uma segunda vez, num lugar em que ninguém pensa
na hora de limpar. `--verbose` mantém o arquivo, a linha e o commit, que é tudo de que uma pessoa
precisa para agir.

### Por que ele vem primeiro

Salve a nova ordem como `ci/stages`:

```
secrets
test
sast
sca
build
```

Três motivos, do mais pesado para o mais leve. Um segredo é o único achado cuja resposta nunca
depende do resto da execução: diga o que disserem os testes, um segredo enviado é revogado. É também
o estágio mais barato, uma fração de segundo para um histórico deste tamanho, como mostra o log dele
no fim desta seção, então pô-lo primeiro não custa nada aos outros estágios. E os estágios seguintes copiam o repositório para lugares que duram
mais que a execução: a imagem que o estágio de build produz contém todo arquivo do checkout que o
`.dockerignore` não exclui, e a partir da aula 8 uma imagem é enviada para um registry. **Uma execução
que para em `secrets` não copia o segredo para lugar novo nenhum.**

O estágio não tem nível de alerta. A aula 7 constrói a distinção entre achados que quebram o build e
achados que só alertam, e um segredo cai de um lado dela sem discussão: quem o enviou pode agir na
hora, revogando-o.

### A cópia de staging agora precisa de um token

`settings.py` se recusa a subir sem `LINKBOX_TOKEN`, e a imagem não carrega um, o que está certo: uma
imagem é copiada para registries e laptops, e um token embutido nela seria mais uma cópia de um
segredo. Então a imagem, iniciada sem nada, para:

```
ana@vm:~/linkbox$ docker build -q -t linkbox:dev . && docker run --rm linkbox:dev 2>&1 | tail -n 5
sha256:efc899b7dd57ca52ce9432b1a77465ae44ac64a55b5bcf2d06a0c2087f3f3c1d
KeyError: 'LINKBOX_TOKEN'
[2026-10-23 05:00:28 +0000] [7] [INFO] Worker exiting (pid: 7)
[2026-10-23 05:00:28 +0000] [1] [ERROR] Worker (pid:7) exited with code 3
[2026-10-23 05:00:28 +0000] [1] [ERROR] Shutting down: Master
[2026-10-23 05:00:28 +0000] [1] [ERROR] Reason: Worker failed to boot.
```

O worker levantou o mesmo `KeyError` que os testes, e o gunicorn desistiu, que é a recusa de duas
seções atrás funcionando um nível acima. A varredura dinâmica da aula 4 sobe essa imagem numa rede
só dela, então precisa passar um token. **Ela cria um para a execução, da fonte aleatória do sistema
operacional, e nada o guarda**: o contêiner é removido quando a varredura termina, e o token com ele.
Salve como `ci/dast.sh`:

```sh
# Dynamic analysis: the image this run built, started on a network of its
# own, and ZAP's baseline scan against it from a second container. The scan
# only looks: it reads what the application answers and sends it nothing
# meant to break it. A rule set to FAIL in ci/zap-rules.conf breaks the build.
set -euo pipefail
net=linkbox-staging-$$
docker network create "$net" >/dev/null
trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
docker run -d --rm --name "$net-app" --network "$net" \
  -e LINKBOX_TOKEN="$(head -c 18 /dev/urandom | base64)" "linkbox:${CI_COMMIT:-dev}" >/dev/null
sleep 2
docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
  zap-baseline.py -t "http://$net-app:8000" -c zap-rules.conf -I -z -silent
```

O valor aparece na linha de comando do `docker run`, onde outro usuário da mesma máquina poderia lê-lo
na lista de processos durante a varredura. Para um token que abre um contêiner numa rede só dele, por
um minuto, isso é aceitável; para um de verdade não seria, e a aula 17 troca valores assim por
outros que o pipeline busca na hora da execução.

### A execução

Faça o commit dos três arquivos e o push. O hook da última seção varre o commit no caminho, e diz
isso:

```
ana@vm:~/linkbox$ git add ci
ana@vm:~/linkbox$ git commit -q -m "secret scanning first in the pipeline, and a token for the staging copy"
2:00AM INF 0 commits scanned.
2:00AM INF scanned ~494 bytes (494 bytes) in 263ms
2:00AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at bd8e771        
remote: secrets: passed in 1s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 8s        
remote: build: passed in 1s        
remote: pipeline passed        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   19d0738..bd8e771  main -> main
```

O estágio `secrets` passou, e o log dele diz o que essa aprovação significa:

```
ana@vm:~/linkbox$ cat ~/ci/runs/1/logs/secrets.log
2:00AM INF Unknown SCM platform. Use --platform to include links in findings. host=
2:00AM INF 8 commits scanned.
2:00AM INF scanned ~10040 bytes (10.04 KB) in 275ms
2:00AM INF no leaks found
```

**Oito commits varridos e nada encontrado**, porque o único achado que o histórico guarda está
registrado como morto no `.gitleaksignore`. Se esse arquivo faltasse, a execução teria parado no
primeiro estágio, com o fingerprint do token no log, mascarado. De agora em diante, todo push para o
servidor lê o histórico inteiro antes de qualquer outra coisa rodar.
