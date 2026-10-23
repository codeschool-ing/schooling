---
title: O estágio de imagem, o registry e o próximo build
version: 1
---

Dois estágios entram no pipeline depois de `build`. **`image` examina a imagem que a execução acabou
de construir, e `push` a põe num registry, nessa ordem**, para que nada chegue ao registry depois de
uma checagem anterior recusar. O registry é de onde o cluster da aula 10 puxa imagens, e aulas
seguintes assinam o que está nele (aula 14) e o descrevem (aula 13).

### Um registry seu

Um registry é um servidor que guarda imagens e responde aos pedidos de pull e push do Docker. O
oficial, `registry`, roda como contêiner. Inicie uma vez; `--restart=always` o traz de volta depois
de um reboot:

```
ana@vm:~/linkbox$ docker run -d --restart=always -p 127.0.0.1:5000:5000 --name registry registry:3.1.2
d2864152d2dacdf7a948056e6740a164052bfb6e9f9ab59c4b3599e891b36163
ana@vm:~/linkbox$ curl -s http://localhost:5000/v2/_catalog
{"repositories":[]}
```

**Ele escuta só em `127.0.0.1`, sem senha e sem TLS**, o que é aceitável para um registry que nada
fora deste computador alcança, e para mais nada. O Docker aceita HTTP sem TLS para `localhost` sem
configuração justamente para esse uso. Um registry compartilhado por um time precisa de TLS e de
autenticação, os dois descritos na documentação do próprio registry e nenhum dos dois montado aqui;
um registry hospedado (o do GitHub, o do GitLab, o de um provedor de nuvem) já vem com os dois.

### Os dois estágios

O scan, com a regra das duas últimas seções. Salve como `ci/image.sh`:

```sh
# The image this run built, scanned before it goes anywhere. A high or
# critical vulnerability that already has a fixed version breaks the build.
# The rest, which no rebuild can fix yet, is counted in the log for whoever
# reviews the base image.
set -uo pipefail
image=linkbox:${CI_COMMIT:-dev}
trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 "$image" || exit 1
echo "everything else, fixed or not:"
trivy image --quiet "$image" | grep '^Total'
exit 0
```

O `|| exit 1` importa mais do que parece. O Trivy sai com 1 tanto quando acha algo quanto quando não
consegue rodar, por exemplo porque a imagem não existe, e **os dois casos precisam quebrar o build**:
é a regra da aula 7, de que um scanner que não rodou não é uma aprovação. O segundo scan só conta,
então o status dele é ignorado e o estágio termina com `exit 0`.

O push. Uma execução em qualquer branch envia a imagem com o commit como tag; uma execução na `main`
também move a tag `main`, que é o que o manifesto da aula 10 nomeia. Salve como `ci/push.sh`:

```sh
# The image, into the registry. It is the last stage, so nothing reaches the
# registry that a stage before it refused. A run on main also moves the tag
# main, which is what the cluster's manifest names.
set -euo pipefail
tag=localhost:5000/linkbox:${CI_COMMIT:-dev}
docker tag "linkbox:${CI_COMMIT:-dev}" "$tag"
docker push -q "$tag"
if [ "${CI_BRANCH:-}" = main ]; then
  docker tag "$tag" localhost:5000/linkbox:main
  docker push -q localhost:5000/linkbox:main
fi
```

E a lista, com os dois no fim, como `ci/stages`:

```
secrets
test
sast
sca
build
image
push
```

### A primeira execução

Faça commit do Dockerfile e dos três arquivos, e envie. As linhas `INF` são o hook de pre-commit da
aula 6 conferindo se o commit tem segredos:

```
ana@vm:~/linkbox$ git add Dockerfile ci
ana@vm:~/linkbox$ git commit -q -m "a two-stage image on a distroless base, scanned and pushed to the registry"
1:53AM INF 0 commits scanned.
1:53AM INF scanned ~1619 bytes (1.62 KB) in 202ms
1:53AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 8fe5800        
remote: secrets: passed in 1s        
remote: test: passed in 1s        
remote: sast: passed in 2s        
remote: sca: passed in 8s        
remote: build: passed in 1s        
remote: image: passed in 0s        
remote: push: passed in 1s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   f7930f5..8fe5800  main -> main
```

**Sete estágios, todos aprovados, e o estágio de imagem levou menos de um segundo**, porque lê o banco
que esta máquina já tem. O log diz o que o portão olhou e o que ele só contou:

```
ana@vm:~/linkbox$ cat ~/ci/runs/1/logs/image.log

Report Summary

┌────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                     Target                     │    Type    │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ linkbox:8fe5800 (debian 13.7)                  │   debian   │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/blinker-1.9.0.dist-info/METADATA      │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/click-8.1.7.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/flask-3.1.3.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/gunicorn-22.0.0.dist-info/METADATA    │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/itsdangerous-2.2.0.dist-info/METADATA │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/jinja2-3.1.6.dist-info/METADATA       │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/markupsafe-2.1.3.dist-info/METADATA   │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/packaging-26.3.dist-info/METADATA     │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/werkzeug-3.1.9.dist-info/METADATA     │ python-pkg │        0        │    -    │
└────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

everything else, fixed or not:
Total: 162 (UNKNOWN: 0, LOW: 49, MEDIUM: 87, HIGH: 26, CRITICAL: 0)
ana@vm:~/linkbox$ curl -s http://localhost:5000/v2/linkbox/tags/list
{"name":"linkbox","tags":["8fe5800","main"]}
```

O resumo tem uma linha para cada lista que o Trivy leu, o banco do Debian e um `METADATA` por pacote
em `/packages`, e **0 em todas**, porque só foram pedidos achados altos e críticos corrigíveis.
Embaixo, a contagem de tudo: os mesmos 162. O registry agora guarda a imagem duas vezes, com a tag do
commit e com `main`.

O outro jeito de o estágio quebrar vale ser visto uma vez. Peça a ele para examinar uma imagem que
não existe, aqui passando um commit que ninguém construiu:

```
ana@vm:~/linkbox$ CI_COMMIT=0000000 bash ci/image.sh; echo "exit $?"
2026-10-23T01:54:12-03:00	FATAL	Fatal error	run error: image scan error: scan error: unable to initialize a scan service: unable to initialize artifact: unable to initialize container image: unable to find the specified image "linkbox:0000000" in ["docker" "containerd" "podman" "remote"]: 4 errors occurred:
	* docker error: unable to inspect the image (linkbox:0000000): Error response from daemon: No such image: linkbox:0000000
	* containerd error: failed to list images from containerd client: connection error: desc = "transport: Error while dialing: dial unix /run/containerd/containerd.sock: connect: permission denied"
	* podman error: unable to initialize Podman client: no podman socket found: stat podman/podman.sock: no such file or directory
	* remote error: GET https://index.docker.io/v2/library/linkbox/manifests/0000000: UNAUTHORIZED: authentication required; [map[Action:pull Class: Name:library/linkbox Type:repository]]


exit 1
```

**O Trivy não conseguiu rodar, disse isso e saiu com 1, e o estágio repassou.** Se o `ci/image.sh`
lesse a saída do Trivy em vez do status, ou terminasse com um `exit 0` incondicional, uma tag
renomeada teria transformado a checagem de imagem num estágio que aprova toda imagem para sempre.

### O que o portão faz com a imagem antiga

Para ver o estágio quebrar, ponha o Dockerfile da aula 1 de volta numa branch própria e envie. Todo
estágio antes de `image` passa, porque nada no código mudou. A tabela que o scanner imprime é larga
demais para esta página, então as linhas da tabela são filtradas da saída do push aqui, e o segundo
comando imprime os mesmos achados, um por linha:

```
ana@vm:~/linkbox$ git switch -q -c old-base
ana@vm:~/linkbox$ git checkout main~1 -- Dockerfile
ana@vm:~/linkbox$ git commit -q -m "the single-stage image, to see what the gate says"
1:54AM INF 0 commits scanned.
1:54AM INF scanned ~140 bytes (140 bytes) in 220ms
1:54AM INF no leaks found
ana@vm:~/linkbox$ git push ci old-base 2>&1 | grep -v '[│├└┌]'
remote: run 2: old-base at 1afc223        
remote: secrets: passed in 1s        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: sca: passed in 7s        
remote: build: passed in 1s        
remote: image: FAILED in 13s, the end of image.log:        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      old-base -> old-base
ana@vm:~/linkbox$ trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed --format json linkbox:$(git rev-parse --short HEAD) | jq -r '.Results[].Vulnerabilities[]? | "\(.PkgName) \(.InstalledVersion)  \(.VulnerabilityID)  \(.Severity)  fixed in \(.FixedVersion)"'
msgpack 1.1.2  GHSA-6v7p-g79w-8964  HIGH  fixed in 1.2.1
setuptools 70.3.0  CVE-2025-47273  HIGH  fixed in 78.1.1
urllib3 2.7.0  CVE-2026-97687  HIGH  fixed in 2.8.0
urllib3 2.7.0  CVE-2026-97689  HIGH  fixed in 2.8.0
```

**O estágio de imagem quebrou o build por quatro achados, e nenhum deles está no código ou nas
dependências do linkbox.** São do pip do `python:3.13`, achados pela lista do próprio pip, como a
primeira seção desta aula mostrou. A imagem nunca chegou ao registry, porque `push` vem depois de
`image` e a execução parou.

### O próximo build

Um scan responde pelo dia em que rodou. A imagem no registry não muda, e os avisos sobre ela mudam: o
banco de amanhã sabe coisas que o de hoje não sabe, e uma imagem base que passa limpa hoje não vai
passar daqui a um mês. Dois hábitos acompanham isso, e a aula 2 já montou o primeiro.

**A lista noturna reconstrói a imagem do zero.** O `ci/nightly` roda `rebuild`, um
`docker build --no-cache`, então tudo o que o build busca é buscado de novo mesmo quando nenhum commit
mudou. Mas leia esse estágio com esta aula em mente: `--no-cache` refaz toda camada e reaproveita a
imagem base que já está na máquina. Pegar um `distroless` ou `slim` mais novo exige perguntar de novo
ao registry, que é o que `docker build --pull` faz. A aula 15 vai além e nomeia a base pelo digest,
para que trocar de imagem base seja um commit que alguém revisa.

**E o que está rodando é examinado de novo, não só o que está sendo construído.** A imagem que um
cluster puxou na semana passada foi examinada na semana passada. A aula 13 guarda um SBOM de cada
imagem que o pipeline envia, para que um aviso novo possa ser conferido contra tudo o que foi
entregue em minutos, sem baixar uma imagem sequer.
