---
title: Como o cache decide
version: 1
---

**Cada instrução de um Dockerfile produz uma camada, e o builder guarda cada uma com uma chave: a
camada sobre a qual ela foi construída, mais a instrução, mais, no caso do `COPY`, o checksum de cada
arquivo copiado.** No build seguinte, uma instrução cuja chave bate não roda; a camada antiga é
reaproveitada. Essa regra única decide se um build leva um terço de segundo ou vinte.

A Ana parte do Dockerfile simples da aula 11 e o constrói uma vez, com o cache vazio:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o /usr/local/bin/shelf .
CMD ["shelf"]
```

```
ana@vm:~/shelf$ time docker build -q -t shelf:dev .
sha256:190e7499645fd64e21608781bb5ecae079f675aceb36961af9c505062360c62a

real	0m30.232s
user	0m0.222s
sys	0m0.145s
```

## As camadas que ele criou

O `docker history` lista as camadas de uma imagem, a mais nova em cima, com a instrução que fez cada
uma e o tamanho:

```
ana@vm:~/shelf$ docker history shelf:dev
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
190e7499645f   6 seconds ago    CMD ["shelf"]                                   0B        buildkit.dockerfile.v0
<missing>      6 seconds ago    RUN /bin/sh -c go build -o /usr/local/bin/sh…   146MB     buildkit.dockerfile.v0
<missing>      20 seconds ago   COPY . . # buildkit                             8.73MB    buildkit.dockerfile.v0
<missing>      20 seconds ago   WORKDIR /src                                    8.19kB    buildkit.dockerfile.v0
<missing>      6 weeks ago      WORKDIR /go                                     4.1kB     buildkit.dockerfile.v0
<missing>      6 weeks ago      RUN /bin/sh -c mkdir -p "$GOPATH/src" "$GOPA…   16.4kB    buildkit.dockerfile.v0
<missing>      6 weeks ago      COPY /target/ / # buildkit                      255MB     buildkit.dockerfile.v0
<missing>      6 weeks ago      ENV PATH=/go/bin:/usr/local/go/bin:/usr/loca…   0B        buildkit.dockerfile.v0
<missing>      6 weeks ago      ENV GOPATH=/go                                  0B        buildkit.dockerfile.v0
<missing>      6 weeks ago      ENV GOTOOLCHAIN=local                           0B        buildkit.dockerfile.v0
<missing>      6 weeks ago      ENV GOLANG_VERSION=1.25.14                      0B        buildkit.dockerfile.v0
<missing>      6 weeks ago      RUN /bin/sh -c set -eux;  apt-get update;  a…   287MB     buildkit.dockerfile.v0
<missing>      2 months ago     RUN /bin/sh -c set -eux;  apt-get update;  a…   202MB     buildkit.dockerfile.v0
<missing>      2 months ago     RUN /bin/sh -c set -eux;  apt-get update;  a…   65MB      buildkit.dockerfile.v0
<missing>      2 months ago     # debian.sh --arch 'amd64' out/ 'trixie' '@1…   134MB     debuerreotype 0.17
```

As quatro linhas de cima são as instruções da Ana, e tudo abaixo veio com a `golang:1.25`, até o
sistema de arquivos Debian `trixie` na base. **A camada do `RUN go build` tem 146MB**, muito mais que
um programa: ela também guarda o cache de build do Go, que o `go build` gravou em `/root/.cache`
enquanto compilava a biblioteca padrão e o pgx. A aula 13 deixa tudo isso para trás.

## O mesmo build, de novo

Nada mudou, então todas as chaves batem. A saída do build é longa, então daqui em diante a Ana a
filtra com `awk` para as linhas que nomeiam um passo do Dockerfile dela e dizem como ele terminou:

```
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [2/4] WORKDIR /src
#6 CACHED
#7 [3/4] COPY . .
#7 CACHED
#8 [4/4] RUN go build -o /usr/local/bin/shelf .
#8 CACHED

real	0m0.313s
user	0m0.109s
sys	0m0.107s
```

**Todos os passos `CACHED`, e o build inteiro levou 0.313 segundo.** Nenhum arquivo foi copiado e
nada foi compilado; o builder conferiu as chaves e apontou a `shelf:dev` para as camadas que já tinha.

## O que conta como mudança

A chave de um `COPY` vem do conteúdo dos arquivos que ele copia, então mudar um byte de um deles muda
a chave. E quando a chave de um passo muda, **todo passo depois dele é reconstruído**, porque a chave
de cada um inclui a camada de baixo, que agora é outra. A próxima etapa transforma essa regra de um
fato numa decisão de projeto.

| o que mudou | o que é reconstruído |
| --- | --- |
| nada | nada; todo passo fica `CACHED` |
| um arquivo que um `COPY` copia | esse `COPY` e todo passo depois dele |
| uma linha do Dockerfile | essa instrução e todo passo depois dela |
| a imagem base, depois de um novo pull | tudo |
| um arquivo que o `.dockerignore` exclui | nada; o builder nunca o viu |
