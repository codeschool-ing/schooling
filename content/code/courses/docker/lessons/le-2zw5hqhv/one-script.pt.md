---
title: O pipeline é um script
version: 1
---

**Um sistema de CI roda comandos numa máquina que não é sua, toda vez que alguém faz push.** Os
comandos são a parte que vale acertar, e as aulas 20 e 25 já os escreveram. Esta aula os põe num
script que um notebook e um runner de CI rodam igual, para que uma falha no pipeline possa ser
reproduzida digitando uma linha, e nada na configuração do próprio sistema de CI precise ser testado
à parte.

## O Dockerfile, pronto para duas arquiteturas

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
COPY probe/ probe/
ARG VERSION=dev
ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -ldflags "-X main.version=${VERSION}" -o /out/shelf . \
 && CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/probe ./probe

FROM build AS test
RUN go vet ./... && go test -v ./...

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
```

Duas mudanças em relação à aula 25. **`FROM --platform=$BUILDPLATFORM`** roda o estágio de build na
arquitetura da própria máquina, seja qual for a imagem sendo feita, e **`GOOS` e `GOARCH`**, a partir
do `TARGETOS` e do `TARGETARCH` do BuildKit, fazem o Go compilar para o alvo. Uma imagem `arm64` é
então construída num runner `amd64` em velocidade total, sem emulação: só o estágio final, que não roda
comando nenhum, é a imagem distroless `arm64`. A aula 13 apresentou esses argumentos.

## O script

```sh
#!/bin/sh
# Tests, scans, builds and publishes shelf. The CI workflow runs exactly this,
# and so can anybody with Docker and a registry to push to.
set -eu

: "${REGISTRY:?set REGISTRY, for example ghcr.io/ana}"
REF_NAME=${REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}
REV=$(git rev-parse --short HEAD)
IMAGE=$REGISTRY/shelf

echo "--- unit tests"
docker build --target test --quiet . > /dev/null

echo "--- integration tests"
status=0
docker compose -f compose.test.yaml run --rm tests > integration.log 2>&1 || status=$?
docker compose -f compose.test.yaml down > /dev/null 2>&1
if [ "$status" -ne 0 ]; then cat integration.log; exit "$status"; fi

echo "--- scan"
docker build --quiet -t shelf:ci . > /dev/null
docker save shelf:ci -o shelf-ci.tar
docker run --rm -v "$PWD":/work -w /work ${TRIVY_CACHE:+-v "$TRIVY_CACHE":/cache} \
  aquasec/trivy:0.75.0 image --input shelf-ci.tar --scanners vuln --quiet \
  --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed \
  ${TRIVY_CACHE:+--cache-dir /cache} ${TRIVY_FLAGS:-}

echo "--- build and push"
case $REF_NAME in
  v*.*.*) version=${REF_NAME#v}
          tags="-t $IMAGE:$version -t $IMAGE:${version%.*} -t $IMAGE:${version%%.*}" ;;
  *)      version=dev
          tags="-t $IMAGE:$REF_NAME" ;;
esac
docker build --platform linux/amd64,linux/arm64 --build-arg VERSION="$version" \
  --cache-from "type=registry,ref=$IMAGE:buildcache" \
  --cache-to "type=registry,ref=$IMAGE:buildcache,mode=max" \
  --sbom=true --provenance=mode=min --metadata-file build.json \
  -t "$IMAGE:sha-$REV" $tags --push . > build.log 2>&1 || { tail -20 build.log; exit 1; }

digest=$(jq -r '."containerimage.digest"' build.json)
echo "pushed $IMAGE@$digest"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "digest=$digest" >> "$GITHUB_OUTPUT"
fi
```

Quatro passos, em ordem de custo, e **o `set -e` faz da primeira falha o último passo**: os testes de
unidade como o estágio de testes da aula 25, os testes de integração com o Compose, a varredura com a
barreira da aula 20, e o build multiplataforma com push. Tudo o que muda entre um notebook e a CI chega
por variáveis de ambiente: para onde enviar, que ref está sendo construída, e, no laboratório, onde
está o banco offline do Trivy.

## A primeira execução

A Ana faz commit dos arquivos e roda o script, enviando para o registry da máquina dela:

```
ana@vm:~/shelf$ git add -A && git -c user.name=Ana -c user.email=ana@example.com commit -qm "ci: one pipeline, run anywhere" && git log --oneline -1
cf9d1cf ci: one pipeline, run anywhere
ana@vm:~/shelf$ REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache TRIVY_FLAGS="--skip-db-update --skip-version-check --offline-scan" sh ci/pipeline.sh; echo "exit $?"
--- unit tests
--- integration tests
--- scan

Report Summary

┌─────────────────────────────┬──────────┬─────────────────┐
│           Target            │   Type   │ Vulnerabilities │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf-ci.tar (debian 12.15) │  debian  │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ probe                       │ gobinary │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf                       │ gobinary │        1        │
└─────────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


shelf (gobinary)
================
Total: 1 (HIGH: 1, CRITICAL: 0)

┌───────────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬─────────────────────────────────────────────────────────────┐
│      Library      │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                            Title                            │
├───────────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
│ golang.org/x/text │ CVE-2026-56852 │ HIGH     │ fixed  │ v0.29.0           │ 0.39.0        │ golang.org/x/text: golang.org/x/text: Denial of Service via │
│                   │                │          │        │                   │               │ invalid UTF-8 input                                         │
│                   │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2026-56852                  │
└───────────────────┴────────────────┴──────────┴────────┴───────────────────┴───────────────┴─────────────────────────────────────────────────────────────┘
exit 1
```

**O pipeline parou na varredura**, no achado que a aula 20 encontrou: `golang.org/x/text` v0.29.0,
alto, com correção. Nada foi construído para release e nada foi enviado, e o status de saída, 1, é o
que deixa uma execução de CI vermelha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"O pipeline como quatro passos em fila, cada um só roda se o anterior passou. Testes de unidade: docker build --target test. Testes de integração: Compose com um Postgres descartável. Varredura: Trivy na imagem, falhando em achados altos ou críticos corrigíveis. Build e push: amd64 e arm64, com o cache no registry, SBOM e proveniência, com tag do commit e, numa tag de versão, da versão. A saída é o digest enviado, que um deploy usa. Na primeira execução da Ana, a varredura parou o pipeline no golang.org/x/text; depois da correção, os quatro passaram.\"><defs><marker id=\"l26flow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26flow-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"125\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"82\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">testes de unidade</text><text x=\"82\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">--target test</text><path d=\"M145 80 L170 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-wire)\"></path><rect x=\"170\" y=\"50\" width=\"125\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"232\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">integração</text><text x=\"232\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">compose run</text><path d=\"M295 80 L320 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-wire)\"></path><rect x=\"320\" y=\"50\" width=\"125\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"382\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">varredura</text><text x=\"382\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">trivy</text><path d=\"M445 80 L470 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-wire)\"></path><rect x=\"470\" y=\"50\" width=\"125\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"532\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">build e push</text><text x=\"532\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">amd64 + arm64</text><path d=\"M595 80 L620 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-wire)\"></path><rect x=\"620\" y=\"55\" width=\"80\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">digest</text><text x=\"660\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para o deploy</text><path d=\"M382 110 L382 150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l26flow-ah-amber)\"></path><text x=\"382\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">primeira execução: parou aqui, x/text v0.29.0</text><text x=\"360\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um passo que falha encerra a execução com o status dele; os seguintes nem começam</text></svg>", "caption": "Cada passo é uma barreira. Nada chega ao registry sem passar por todas as barreiras antes."}
```

Ela aplica a correção da aula 20 e faz commit:

```
ana@vm:~/shelf$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/src -w /src -v ~/gopkg:/go/pkg -e GOCACHE=/tmp/gocache -e GOPROXY=off -e GOFLAGS=-mod=mod golang:1.25 sh -c "go get golang.org/x/text@v0.39.0 && go mod tidy && go mod vendor"
go: upgraded golang.org/x/sync v0.17.0 => v0.21.0
go: upgraded golang.org/x/text v0.29.0 => v0.39.0
ana@vm:~/shelf$ git -c user.name=Ana -c user.email=ana@example.com commit -qam "deps: golang.org/x/text v0.39.0" && git log --oneline -1
cb7eee2 deps: golang.org/x/text v0.39.0
```

```
ana@vm:~/shelf$ REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache TRIVY_FLAGS="--skip-db-update --skip-version-check --offline-scan" sh ci/pipeline.sh; echo "exit $?"
--- unit tests
--- integration tests
--- scan

Report Summary

┌─────────────────────────────┬──────────┬─────────────────┐
│           Target            │   Type   │ Vulnerabilities │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf-ci.tar (debian 12.15) │  debian  │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ probe                       │ gobinary │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf                       │ gobinary │        0        │
└─────────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

--- build and push
pushed localhost:5000/shelf@sha256:0e344483f788353d143a67b428907299e4b8f6443b882f3e29e3c73c4686b6fa
exit 0
ana@vm:~/shelf$ curl -s localhost:5000/v2/shelf/tags/list | jq -c .tags
["buildcache","main","sha-cb7eee2"]
```

**Os quatro passos passaram, e o script imprimiu o digest que enviou.** O registry agora guarda a imagem
sob `main`, o branch, e `sha-cb7eee2`, o commit, mais o `buildcache`, assunto da próxima etapa.
