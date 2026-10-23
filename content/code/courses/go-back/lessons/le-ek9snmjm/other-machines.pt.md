---
title: Imagens para outras máquinas
version: 1
---

Provedores de nuvem muitas vezes alugam servidores `arm64` por menos que os `amd64`, e um laptop com chip da
Apple também é `arm64`. Uma imagem construída nesta máquina é `amd64` e não roda em nenhum dos dois. A
seção 04 já produz o binário; **a imagem não precisa de nada além de copiá-lo**, e é por isso que o
Dockerfile nomeou o binário com o `TARGETARCH`:

```
ana@vm:~/boxoffice$ CGO_ENABLED=0 GOARCH=arm64 go build -trimpath -ldflags "-s -w -X main.version=v0.16.0" -o dist/boxoffice-linux-arm64 . && docker buildx build -q --platform linux/arm64 -t boxoffice:v0.16.0-arm64 --load .
sha256:6ddf079a2a22ff325159b631e82e0c540e41ee3e886933638d34950e2dbe4c3c
ana@vm:~/boxoffice$ docker image inspect --format "{{.Os}}/{{.Architecture}}" boxoffice:v0.16.0 boxoffice:v0.16.0-arm64
linux/amd64
linux/arm64
```

O `docker buildx build --platform linux/arm64` constrói para essa plataforma: pega a variante `arm64` do
distroless, define o `TARGETARCH` como `arm64` e copia o `dist/boxoffice-linux-arm64`. **Nada foi
emulado**, porque nada no Dockerfile roda; o único passo que precisava acontecer em `arm64` era a
compilação, e o Go a fez em `amd64`. O `--load` põe o resultado entre as imagens da máquina, onde o
`inspect` mostra as duas arquiteturas lado a lado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"O código do boxoffice passa duas vezes pelo go build numa máquina amd64, com CGO_ENABLED=0 e GOARCH amd64 ou arm64. Cada build gera um binário em dist. O mesmo Dockerfile copia cada binário sobre a variante correspondente do distroless static, gerando duas imagens, linux/amd64 e linux/arm64.\"><defs><marker id=\"gb-l16-two-images-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"90\" width=\"110\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"70\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">boxoffice</text><text x=\"70\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">código</text><path d=\"M 125 115 L 145 115 L 145 65 L 163 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"165\" y=\"40\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">go build</text><text x=\"240\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GOARCH=amd64</text><path d=\"M 315 65 L 343 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"345\" y=\"40\" width=\"165\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"427\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">boxoffice-linux-amd64</text><path d=\"M 510 65 L 538 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"540\" y=\"40\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"612\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">linux/amd64</text><text x=\"612\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">distroless + COPY</text><path d=\"M 125 115 L 145 115 L 145 175 L 163 175\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"165\" y=\"150\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">go build</text><text x=\"240\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GOARCH=arm64</text><path d=\"M 315 175 L 343 175\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"345\" y=\"150\" width=\"165\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"427\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">boxoffice-linux-arm64</text><path d=\"M 510 175 L 538 175\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l16-two-images-ah)\"></path><rect x=\"540\" y=\"150\" width=\"145\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"612\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">linux/arm64</text><text x=\"612\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">distroless + COPY</text><text x=\"240\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">CGO_ENABLED=0, numa amd64</text></svg>", "caption": "O Go compila para o outro processador; o Dockerfile só copia. Nada é emulado.", "same": ["distroless + COPY"]}
```

Esta máquina não roda a segunda:

```
ana@vm:~/boxoffice$ docker run --rm boxoffice:v0.16.0-arm64; echo "exit $?"
WARNING: The requested image's platform (linux/arm64) does not match the detected host platform (linux/amd64/v4) and no specific platform was requested
exec /boxoffice: exec format error
exit 255
```

O kernel recebeu um programa `arm64` num processador `amd64` e disse isso: `exec format error`. Num
servidor `arm64` ela roda como a outra roda aqui. Com as duas imagens num registry sob um nome só, uma
imagem multiplataforma, cada servidor baixa a variante do seu próprio processador; o `docker buildx build`
com `--platform linux/amd64,linux/arm64` e `--push` constrói e publica isso num comando.

## Construindo dentro da imagem

Gerar o binário na sua máquina e copiá-lo é rápido e fácil de ler, e amarra a imagem ao jeito como a sua
máquina está montada. A outra forma comum constrói dentro de um container, em dois estágios, para que
qualquer máquina com Docker produza a mesma imagem a partir do código:

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.27.1 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags "-s -w" -o /boxoffice .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /boxoffice /boxoffice
ENV BOXOFFICE_HTTP=:8080 BOXOFFICE_GRPC=:9090
EXPOSE 8080 9090
ENTRYPOINT ["/boxoffice"]
```

O primeiro estágio tem o toolchain do Go inteiro, cerca de um gigabyte, e nada dele chega à imagem: o
`COPY --from=build` leva um arquivo. O `--platform=$BUILDPLATFORM` roda esse estágio no próprio
processador do builder e deixa o Go compilar cruzado, em vez de emular o processador do alvo no build
inteiro, o que é muitas vezes mais lento. Copiar o `go.mod` e o `go.sum` e baixar antes de copiar o código
deixa o cache do Docker guardar os módulos baixados enquanto só o código muda. **Este arquivo não foi
rodado para este curso**: o laboratório não conseguiu baixar o `golang:1.27.1`, porque o Docker Hub o
recusou com `429 Too Many Requests`, o seu limite para pulls anônimos. Ele também precisa que o código
gerado pelo sqlc e pelo protoc nas aulas 8 e 10 esteja no diretório, onde o boxoffice o guarda.
