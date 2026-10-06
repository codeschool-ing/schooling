---
title: Alvos e plataformas
version: 1
---

**Um Dockerfile multiestágio são várias imagens num arquivo só, e duas opções escolhem qual você
recebe e para qual processador.** O `--target` para num estágio com nome; o `--platform` constrói o
resultado para outras arquiteturas. As duas aparecem assim que um projeto tem testes ou uma colega
com outro notebook.

## `--target`: uma imagem para cada propósito

O estágio de build tem o compilador, o código e os arquivos de teste. Construir só esse estágio dá
uma imagem onde rodar os testes, a partir do mesmo Dockerfile que constrói a versão de entrega:

```
ana@vm:~/shelf$ docker build -q --target build -t shelf:build .
sha256:52a2640724799ee551c6a1b0f13065b2b17b1366c4aa1dc6773df4f9cbff5e85
ana@vm:~/shelf$ docker run --rm shelf:build go test ./...
ok  	example.com/shelf	0.004s
```

Os testes de unidade rodaram dentro do estágio de build e passaram. **Um Dockerfile, duas imagens**: o
estágio de build para conferir o código, o último estágio para entregá-lo. A aula 25 monta um
pipeline exatamente sobre isso, inclusive com um estágio cujo único trabalho é rodar os testes.

## `--platform`: uma tag para dois processadores

A aula 3 mostrou que a `alpine:3.22` é um índice de imagens, uma por plataforma, e a aula 5, que um
Mac com Apple silicon quer `arm64`. As imagens da Ana até agora são só `amd64`. Para publicar as duas,
ela muda duas coisas no Dockerfile:

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/shelf .

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/shelf /shelf
CMD ["/shelf"]
```

O **`FROM --platform=$BUILDPLATFORM`** roda o estágio de build na arquitetura da própria máquina,
para o compilador rodar nativo em vez de emulado; o **`TARGETOS` e o `TARGETARCH`**, definidos pelo
builder para cada plataforma pedida, dizem ao Go que binário produzir. O Go faz compilação cruzada
sozinho, e é por isso que o laboratório, sem emulador, consegue construir um binário `arm64`:

```
ana@vm:~/shelf$ docker build -q --platform linux/amd64,linux/arm64 -t shelf:multi .
sha256:66f9e6d8778b3f48d483041f3d8ad512e67c0c9b6ef0b7378d1d1411ffebd5d0
ana@vm:~/shelf$ docker image ls --tree shelf:multi
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:multi          66f9e6d8778b       35.3MB         15.1MB   U    
├─ linux/amd64       942837d936de         28MB         7.84MB   U    
└─ linux/arm64       079f7bafb934        7.3MB          7.3MB        
```

**Uma tag, duas imagens**, como o `--tree` mostra: `linux/amd64`, 28MB, desempacotada porque está em
uso, e `linux/arm64`, 7.3MB, guardada mas nunca desempacotada nesta máquina. A base do estágio final,
o distroless, é publicada para as duas, então cada plataforma ganhou a própria base também. O Docker
roda a que combina com a máquina, e pedir a outra dá o erro da aula 2:

```
ana@vm:~/shelf$ docker run --rm -d --name multi-amd64 shelf:multi
510ab13d4a0e4c68b9d7d926defd52b40613ce357d2967bfa479ea1defabbbe7
ana@vm:~/shelf$ docker logs multi-amd64
2026/10/06 17:24:15 catalogue: built in, 3 books
2026/10/06 17:24:15 shelf dev listening on :8080
ana@vm:~/shelf$ docker run --rm --platform linux/arm64 shelf:multi
exec /shelf: exec format error
```

A imagem `arm64` está certa; este processador só não consegue rodá-la. Um Mac com Apple silicon que
baixe a `shelf:multi` de um registry recebe essa variante e a roda nativamente, e a aula 26 envia uma
imagem dessas a partir de um pipeline. Linguagens que não fazem compilação cruzada tão fácil quanto o
Go constroem o estágio da outra plataforma sob emulação QEMU, o que funciona e é bem mais lento.
