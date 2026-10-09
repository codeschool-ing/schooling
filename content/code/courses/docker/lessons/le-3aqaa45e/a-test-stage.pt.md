---
title: Um estágio de testes no Dockerfile
version: 2
---

**Um Dockerfile multiestágio (aula 13) pode levar os testes como mais um estágio.** O estágio parte do
estágio de build, então tem o código, os módulos e o compilador, e roda as verificações. O contexto
de build antes perde todo arquivo do Compose, já que esta aula acrescenta um segundo, e todo `.env`.
Este é o `.dockerignore` da Ana daqui em diante:

```
.git
.env
*.env
compose*.yaml
testdata/
Dockerfile*
.dockerignore
```

E o Dockerfile:

```dockerfile
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
COPY probe/ probe/
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf . \
 && CGO_ENABLED=0 go build -o /out/probe ./probe

FROM build AS test
RUN go vet ./... && go test -v ./...

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
```

O `--target test` pede esse estágio pelo nome:

```
ana@vm:~/shelf$ docker build --target test . 2>&1 | grep -E "^#[0-9]+ [0-9.]+ (=== RUN|--- |PASS|ok)|\[test" | awk '!seen[$0]++'
#13 [test 1/1] RUN go vet ./... && go test -v ./...
#13 5.819 === RUN   TestBooksAnswersWithTheCatalogue
#13 5.819 --- PASS: TestBooksAnswersWithTheCatalogue (0.00s)
#13 5.819 === RUN   TestHealthIsOK
#13 5.819 --- PASS: TestHealthIsOK (0.00s)
#13 5.819 PASS
#13 5.819 ok  	example.com/shelf	0.004s
```

**O `go vet` e os dois testes rodaram dentro do build**, com o cache do estágio de build por trás. Um
build simples da imagem faz outra coisa:

```
ana@vm:~/shelf$ docker build -t shelf:1.7.0 . 2>&1 | grep -oE "\[(build|test|stage-2) [0-9]+/[0-9]+\]" | sort -u
[build 1/8]
[build 2/8]
[build 3/8]
[build 4/8]
[build 5/8]
[build 6/8]
[build 7/8]
[build 8/8]
[stage-2 1/2]
[stage-2 2/2]
```

**Nenhum passo `[test …]`.** O BuildKit trabalha de trás para a frente a partir do estágio pedido, e o
estágio final só copia do `build`, então o `test` nunca é necessário e nunca roda. Os testes não custam
nada quando ninguém os pede, e nenhum arquivo deles chega à imagem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Os três estágios do Dockerfile da Ana como um grafo. O build, a partir da golang:1.25, compila o shelf e o probe. O test parte do build (FROM build) e roda go vet e go test. O estágio final, a partir do distroless, copia os dois binários do build. O docker build --target test roda o build e depois o test. Um docker build simples roda o build e o estágio final, e pula o test, porque nada de que o estágio final precisa vem dele.\"><defs><marker id=\"l25stages-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l25stages-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"80\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">build</text><text x=\"115\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compila shelf, probe</text><rect x=\"300\" y=\"20\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"385\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">test</text><text x=\"385\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">go vet, go test</text><rect x=\"300\" y=\"140\" width=\"170\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"385\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">estágio final</text><text x=\"385\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">distroless e dois binários</text><path d=\"M200 100 L300 55\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l25stages-ah-amber)\"></path><text x=\"232\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">FROM build</text><path d=\"M200 120 L300 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l25stages-ah-phosphor)\"></path><text x=\"250\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">COPY --from</text><text x=\"500\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">--target test</text><text x=\"500\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda build, depois test</text><text x=\"500\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">docker build simples</text><text x=\"500\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda build, depois este; pula o test</text></svg>", "caption": "O BuildKit só roda os estágios de que o alvo precisa. Os testes rodam quando pedidos, e nunca vão para a imagem."}
```

## Quando um teste falha

Uma mudança no código que quebra um teste, a resposta do `/health` em maiúsculas:

```
ana@vm:~/shelf$ sed -i "s/\"ok/\"OK/" main.go && git diff --stat
 main.go | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/shelf$ docker build --target test . > build.log 2>&1; echo "exit $?"
exit 1
ana@vm:~/shelf$ grep -E "main_test.go|FAIL" build.log | head -4
#13 5.646     main_test.go:29: got 200 "OK\n"
#13 5.646 --- FAIL: TestHealthIsOK (0.00s)
#13 5.646 FAIL
#13 5.646 FAIL	example.com/shelf	0.005s
ana@vm:~/shelf$ git checkout main.go
Updated 1 path from the index
```

**O build sai com status 1, e o log traz a mensagem do próprio teste**: `got 200 "OK\n"`. Um pipeline
que roda `docker build --target test` para ali mesmo, e é esse o objetivo: o código que falha nunca
vira imagem. O `git checkout` devolve o arquivo.

Uma propriedade de rodar testes num build vale saber: **o passo entra no cache como qualquer outro.** Se
nada de que ele depende mudou, o próximo build imprime `CACHED` e não roda os testes de novo. Isso está
certo para testes de unidade, cujo resultado depende só do código; é o motivo de um teste que conversa
com um banco ficar na próxima etapa.
