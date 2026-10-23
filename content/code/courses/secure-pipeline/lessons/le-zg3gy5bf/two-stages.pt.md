---
title: Dois estágios, e nada no segundo que o serviço não rode
version: 1
---

A aula 13 de `docker` construiu uma imagem multi-stage para deixá-la menor. Aqui o motivo é o que as
duas últimas seções encontraram: **as ferramentas que constroem uma imagem são um passivo na imagem
que roda.** O pip trouxe os únicos achados corrigíveis da base slim, e um shell é a primeira coisa que
procura quem consegue rodar código num contêiner. Um build em dois estágios deixa os dois do lado do
build, onde são necessários, e entrega o resultado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l08-stages\" aria-label=\"Os dois estágios do Dockerfile do linkbox. O estágio de build, a partir de python:3.13-slim, tem pip, um shell e apt, e produz dois diretórios, /packages e /data. Só esses dois passam para o estágio de execução, a partir da imagem distroless nonroot, que acrescenta app.py e settings.py em /app e roda python3 como o usuário 65532. O pip, o shell e o apt ficam para trás.\"><defs><marker id=\"sp-l08-stages-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"300\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estágio de build</text><text x=\"30\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">python:3.13-slim</text><rect x=\"405\" y=\"15\" width=\"300\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"420\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estágio de execução</text><text x=\"420\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">distroless/python3:nonroot</text><rect x=\"35\" y=\"75\" width=\"80\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"75.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pip</text><rect x=\"125\" y=\"75\" width=\"80\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"165.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sh</text><rect x=\"215\" y=\"75\" width=\"80\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"255.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">apt</text><text x=\"165\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ficam para trás</text><rect x=\"35\" y=\"150\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/packages</text><rect x=\"35\" y=\"210\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/data</text><rect x=\"425\" y=\"150\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/packages</text><rect x=\"425\" y=\"210\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/data</text><text x=\"555.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">do usuário 65532</text><rect x=\"425\" y=\"75\" width=\"125\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">/app</text><text x=\"487.5\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">app.py settings.py</text><rect x=\"560\" y=\"75\" width=\"125\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">python3</text><text x=\"622.5\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">roda como 65532</text><path d=\"M295 170 L423 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-stages-ah-phosphor)\"></path><path d=\"M295 230 L423 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l08-stages-ah-phosphor)\"></path><text x=\"360\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">COPY</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">--from=build</text></svg>", "caption": "Dois diretórios passam do build para a imagem que é entregue. Tudo o que os construiu fica onde foi usado."}
```

### O Dockerfile

O Dockerfile novo substitui inteiro o da aula 1. Salve como `Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "# Build: the pinned dependencies, installed into one directory by the pip\n# of an image that has one.\nFROM python:3.13-slim AS build", "note": "O estágio de build parte do slim, que tem pip. Nada deste estágio chega à imagem final a menos que um `COPY --from=build` abaixo o nomeie."}, {"code": "COPY requirements.txt /", "note": "Só o arquivo de requisitos entra, então esta camada e a seguinte são refeitas quando um pin muda e reaproveitadas quando só o código muda."}, {"code": "RUN pip install --no-cache-dir --target /packages -r /requirements.txt", "note": "`--target` instala os pacotes num diretório comum em vez de no Python desta imagem. Esse diretório é todo o resultado do estágio; o pip fica para trás."}, {"code": "RUN mkdir /data", "note": "A imagem final não tem shell para rodar `mkdir`, então o diretório do banco é criado aqui e copiado."}, {"code": "\n# Run: the same Python and nothing else. No shell, no package manager, no\n# pip, and a user that is not root.\nFROM gcr.io/distroless/python3-debian13:nonroot", "note": "O estágio de execução: o Python distroless do Google, na mesma versão do Debian, na variante `nonroot`, cujo usuário padrão é o 65532."}, {"code": "COPY --from=build /packages /packages", "note": "Os pacotes instalados, como estão."}, {"code": "COPY --from=build --chown=nonroot:nonroot /data /data", "note": "O diretório de dados pertence ao usuário que roda a aplicação; todo o resto continua sendo do root e a aplicação não consegue alterar."}, {"code": "COPY app.py settings.py /app/", "note": "Os dois arquivos de que o serviço precisa. Nem os testes, nem `ci/`, nem o Dockerfile: um `COPY . .` teria levado tudo isso."}, {"code": "WORKDIR /app\nENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db", "note": "`PYTHONPATH` é como o Python acha pacotes num diretório onde não foram instalados por ele."}, {"code": "EXPOSE 8000\nENTRYPOINT [\"python3\", \"-m\", \"gunicorn\", \"--bind\", \"0.0.0.0:8000\", \"app:app\"]", "note": "`python3 -m gunicorn` em vez de `gunicorn`: o script que o pip escreveu em `/packages/bin` começa com o caminho do Python do estágio de build, que não existe nesta imagem."}]}
```

**O `pip install --target` é o que faz a separação funcionar.** Um `pip install` comum escreve no
próprio Python da imagem de build, misturado com o pip e com tudo o mais que essa imagem tem, e não
existe um jeito limpo de copiar só o que ele acrescentou. O `--target` põe os pacotes, e nada além
deles, num diretório próprio; esse diretório passa para o segundo estágio, e o pip não. Um pacote com
partes compiladas é construído para uma versão menor do Python, e por isso os dois estágios são 3.13
sobre a mesma versão do Debian.

Três decisões menores decorrem da base. A imagem não tem shell, então o diretório de dados é criado
no primeiro estágio e copiado. Os arquivos da aplicação são do root e a aplicação roda como o usuário
65532, então ela consegue escrever o banco e não consegue mudar o próprio código. E o
`COPY app.py settings.py` nomeia arquivos em vez de copiar o diretório, então os testes, os scripts
do pipeline e o diretório `.git` ficam de fora, diga o `.dockerignore` o que disser.

### Construa e olhe dentro

```
ana@vm:~/scans$ cd ~/linkbox
ana@vm:~/linkbox$ docker build -q -t linkbox:dev .
sha256:74a999810b693c84b198c67645d7df6d3764dc9a532279988d9ef967b2253a3f
ana@vm:~/linkbox$ docker images --format "{{.Repository}}:{{.Tag}}  {{.Size}}" linkbox:dev
linkbox:dev  100MB
ana@vm:~/linkbox$ docker image inspect --format "{{.Config.User}}" linkbox:dev
65532
```

**100 MB, contra 1,64 GB da imagem da aula 1**, e a imagem declara o usuário `65532`, que a variante
`nonroot` do distroless define por você. O jeito mais seguro de ver o que não está nela é pedir:

```
ana@vm:~/linkbox$ docker run --rm --entrypoint sh linkbox:dev
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "sh": executable file not found in $PATH

Run 'docker run --help' for more information
ana@vm:~/linkbox$ docker run --rm --entrypoint python3 linkbox:dev -m pip --version
/usr/bin/python3: No module named pip
ana@vm:~/linkbox$ docker run --rm --entrypoint python3 linkbox:dev -c "import os; print(os.getuid(), os.getgid())"
65532 65532
```

Não há `sh` para iniciar, não há pip para importar, e o processo é o usuário 65532 no grupo 65532.
**A falta de shell não é uma barreira de segurança por si só**: quem conseguir rodar código neste
contêiner ainda pode rodar Python, que é uma linguagem de programação completa. O que ela tira é o
caminho fácil, os comandos de uma linha com que começam a maioria dos ataques automatizados e das
intrusões feitas à mão, e tira todos os achados que pertenciam aos programas deixados de fora.

Ela também muda o jeito de depurar. `docker exec -it linkbox sh` não funciona mais, então investigar
um contêiner em execução passa pelos logs, por `docker exec` com `python3` ou por um contêiner de
depuração ligado a ele; o Kubernetes tem `kubectl debug` para isso, que o cluster da aula 10 poderia
usar.

### Ela continua fazendo o trabalho

```
ana@vm:~/linkbox$ docker run -d --name linkbox -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
6da0618d9b9aabadef11b490fbcacfd2963aabddcd35e1acb8cad7de3ca92b87
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links
{"code":"HB3suw"}
ana@vm:~/linkbox$ docker logs linkbox 2>&1 | head -n 4
[2026-10-23 04:53:51 +0000] [1] [INFO] Starting gunicorn 22.0.0
[2026-10-23 04:53:51 +0000] [1] [INFO] Listening at: http://0.0.0.0:8000 (1)
[2026-10-23 04:53:51 +0000] [1] [INFO] Using worker: sync
[2026-10-23 04:53:51 +0000] [7] [INFO] Booting worker with pid: 7
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

**O serviço responde como antes**, agora pelo gunicorn iniciado como `python3 -m gunicorn`. O token
é um valor provisório para um teste local, passado como variável de ambiente do jeito que a aula 6
arrumou.

### E o scan

```
ana@vm:~/linkbox$ trivy image --quiet --format json linkbox:dev | jq -r -f ~/scans/count.jq
debian: 162 found (HIGH 26, LOW 49, MEDIUM 87), 0 with a fix
python-pkg: nothing found
```

**Os mesmos 162 achados da base distroless pura, e nada dos pacotes do próprio linkbox.** Cada pacote
em `/packages` foi lido, porque cada um manteve o seu `.dist-info/METADATA`, e os pins da aula 5 não
têm aviso neste banco. Nada do que o estágio de build tinha, o pip incluído, aparece. Essa é a imagem
que o pipeline entrega daqui em diante.
