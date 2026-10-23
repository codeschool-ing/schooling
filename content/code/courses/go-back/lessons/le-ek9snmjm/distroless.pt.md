---
title: Uma imagem com um programa dentro
version: 1
---

Uma imagem de container é um sistema de arquivos e algumas configurações. A maioria das imagens parte de
uma distribuição, Debian ou Alpine, com um shell, um gerenciador de pacotes e centenas de programas,
porque a maioria dos programas precisa de alguns deles na execução. **Um binário Go estático não precisa de
nenhum.** Ele precisa de alguns arquivos que um programa espera encontrar, e de mais nada.

**As imagens distroless** são exatamente isso. O Google as publica em `gcr.io/distroless`, construídas a
partir de pacotes do Debian com tudo o que um programa não precisa deixado de fora. A `static-debian12` é
a menor, feita para binários estáticos: certificados de CA, para o TLS funcionar; dados de fuso horário; o
`/etc/passwd` com três usuários; e nenhum shell, nenhum gerenciador de pacotes, nenhuma biblioteca C. A tag
`nonroot` faz do seu usuário padrão o `nonroot`, uid 65532, em vez do root.

## O Dockerfile

```dockerfile
# boxoffice/Dockerfile
FROM gcr.io/distroless/static-debian12:nonroot
ARG TARGETARCH
COPY dist/boxoffice-linux-${TARGETARCH} /boxoffice
ENV BOXOFFICE_HTTP=:8080 BOXOFFICE_GRPC=:9090
EXPOSE 8080 9090
ENTRYPOINT ["/boxoffice"]
```

Seis instruções. **A imagem copia um binário gerado fora dela**, pelo comando da seção 05; o `TARGETARCH` é uma
variável que o builder define com a arquitetura para a qual está construindo, `amd64` aqui, de modo que o
mesmo arquivo pode pegar o `dist/boxoffice-linux-arm64` na seção 08. As duas linhas `ENV` fazem a imagem
escutar em todas as interfaces, que é a configuração da aula 14 fazendo o trabalho para o qual foi
escrita: dentro de um container, `localhost` é o próprio container, e um endereço preso ali não é
alcançado de fora dele. O `EXPOSE` documenta as portas e não publica nada; isso é trabalho do `docker run`.

O contexto de build, tudo o que o `docker build` manda ao daemon, é o diretório. O `.dockerignore` o limita
ao que o Dockerfile copia:

```
# boxoffice/.dockerignore
*
!dist/boxoffice-linux-*
```

Ignore tudo, depois deixe os binários de release voltarem. Sem isso, o contexto incluiria os builds de
teste de `dist/`, o código e o que mais estivesse no diretório, um arquivo de segredo inclusive.

## Primeiro, o binário da seção 04

A imagem base vem do registry do Google, e esta máquina já a tinha:

```
ana@vm:~/boxoffice$ docker pull gcr.io/distroless/static-debian12:nonroot
nonroot: Pulling from distroless/static-debian12
Digest: sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
Status: Image is up to date for gcr.io/distroless/static-debian12:nonroot
gcr.io/distroless/static-debian12:nonroot
```

Ponha o build nativo da seção 04, o ligado dinamicamente, onde o Dockerfile procura, construa e rode:

```
ana@vm:~/boxoffice$ cp dist/try-linux-amd64 dist/boxoffice-linux-amd64 && docker build -q -t boxoffice:dynamic . && docker run --rm boxoffice:dynamic; echo "exit $?"
sha256:bf477361cde3fb553f14b4d7c7de6e8a41942119f9e468d33c1515b8d8670e37
exec /boxoffice: no such file or directory
exit 255
```

**`exec /boxoffice: no such file or directory`**, sobre um arquivo que com certeza está lá. O kernel leu o
cabeçalho do binário, viu que ele precisa do interpretador `/lib64/ld-linux-x86-64.so.2`, e esse é o
arquivo que não existe: a imagem não tem biblioteca C nem loader. A mensagem nomeia o programa porque foi
ele o executado. **Todo programa Go que falha assim numa imagem mínima foi gerado com o cgo ligado**, e o
`CGO_ENABLED=0` é a correção.

## A de verdade

```
ana@vm:~/boxoffice$ CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=v0.16.0" -o dist/boxoffice-linux-amd64 . && docker build -q -t boxoffice:v0.16.0 .
sha256:4c353c6a273fbd43931cd7d0e94d1da89b3a012a7002f0ddb31974bb440725ea
ana@vm:~/boxoffice$ docker image ls | grep -e IMAGE -e boxoffice:v -e distroless
IMAGE                                       ID             DISK USAGE   CONTENT SIZE   EXTRA
boxoffice:v0.16.0                           4c353c6a273f       30.6MB         7.35MB        
gcr.io/distroless/static-debian12:nonroot   afa5c872c891        6.9MB         1.44MB        
```

**O `CONTENT SIZE` é o que um registry guarda e um servidor baixa: 7,35 MB**, dos quais 1,44 MB são do
distroless e o resto é o boxoffice, comprimido. O `DISK USAGE` é isso mais as camadas desempacotadas nesta
máquina.

E não há mais nada nela:

```
ana@vm:~/boxoffice$ docker run --rm --entrypoint sh boxoffice:v0.16.0; echo "exit $?"
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "sh": executable file not found in $PATH

Run 'docker run --help' for more information
exit 127
```

Sem shell, então nada de `docker exec -it boxoffice sh` para olhar em volta. Isso é um custo na depuração,
e é o ponto quando outra pessoa entra: um processo invadido não encontra shell, nem gerenciador de
pacotes, nem ferramentas para baixar mais. Quando você precisar mesmo olhar dentro, o `docker cp` copia
arquivos para fora de um container, e um segundo container iniciado com `--pid container:boxoffice` vê os
processos dele com as ferramentas da sua própria imagem.
