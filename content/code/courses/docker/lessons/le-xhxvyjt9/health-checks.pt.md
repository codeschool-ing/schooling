---
title: Health checks
version: 1
---

**O `docker ps` diz `Up` quando o processo está rodando. Ele não tem como dizer se o programa está
fazendo o seu trabalho.** Um servidor web travado, ou escutando na porta errada, está `Up` do mesmo
jeito. Um **health check** é um comando que o Docker roda dentro do container de tempos em tempos:
status de saída 0 quer dizer saudável, qualquer outro quer dizer que não.

## Uma verificação para uma imagem sem shell

O exemplo de costume é `curl -f http://localhost/health`, e o distroless não tem `curl`, nem `wget`,
nem shell para rodá-los, de propósito (aula 14). Então o `shelf` ganha uma verificação própria: um
segundo programa Go, minúsculo, construído no mesmo estágio e copiado ao lado dele.

```go
// probe exits 0 when a GET of its one argument answers 200, and 1 otherwise.
// It is the health check for an image that has no shell and no curl.
package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	c := http.Client{Timeout: 2 * time.Second}
	r, err := c.Get(os.Args[1])
	if err != nil || r.StatusCode != http.StatusOK {
		os.Exit(1)
	}
}
```

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

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /out/probe /
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=2s --start-period=5s --retries=3 \
  CMD ["/probe", "http://127.0.0.1:8080/health"]
CMD ["/shelf"]
```

**As opções dizem quanta paciência ter.** A cada 5 segundos, rodar o `/probe`, desistir dele depois de
2, ignorar falhas nos primeiros 5 enquanto o programa inicia, e considerar o container não saudável
depois de 3 falhas seguidas. Os padrões do Docker são 30 segundos tanto para o intervalo quanto para o
timeout, nenhum período inicial e 3 tentativas; o `shelf` inicia em milissegundos, então números
menores não custam nada aqui.

```
ana@vm:~/shelf$ docker run -d --name web shelf:1.4.0
ca80a22cedbe6b4c1dd540e238384efc19e54d9a502cf1958fc7a7b06d3240ed
ana@vm:~/shelf$ docker ps --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
web       Up Less than a second (health: starting)
ana@vm:~/shelf$ docker ps --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
web       Up 8 seconds (healthy)
ana@vm:~/shelf$ docker inspect web --format "{{json .State.Health}}" | jq "{Status, FailingStreak, last: .Log[-1]}"
{
  "Status": "healthy",
  "FailingStreak": 0,
  "last": {
    "Start": "2026-10-06T18:06:14.52663257Z",
    "End": "2026-10-06T18:06:14.583389803Z",
    "ExitCode": 0,
    "Output": ""
  }
}
```

`health: starting` na primeira olhada, `healthy` oito segundos depois, e o `.State.Health` guarda os
últimos resultados com os códigos de saída.

## Como é um container não saudável

A Ana inicia um segundo container com `PORT=9090`, então o `shelf` escuta na 9090 enquanto a
verificação pergunta na 8080:

```
ana@vm:~/shelf$ docker run -d --name web-9090 -e PORT=9090 shelf:1.4.0
d97bc4897c4d2e94e20b60bcb1226de4ffdf894deddadae78ffab4a4250941d7
ana@vm:~/shelf$ docker ps --format "table {{.Names}}\t{{.Status}}"
NAMES      STATUS
web-9090   Up 25 seconds (unhealthy)
web        Up 33 seconds (healthy)
ana@vm:~/shelf$ docker inspect web-9090 --format "{{json .State.Health}}" | jq "{Status, FailingStreak, last: .Log[-1]}"
{
  "Status": "unhealthy",
  "FailingStreak": 4,
  "last": {
    "Start": "2026-10-06T18:06:38.018910328Z",
    "End": "2026-10-06T18:06:38.078279822Z",
    "ExitCode": 1,
    "Output": ""
  }
}
```

**`Up 25 seconds (unhealthy)`, quatro falhas seguidas.** Sem a verificação, este container pareceria
exatamente igual ao saudável, e só um usuário descobriria. Esse é o valor do health check: ele testa
aquilo para que o programa existe, de dentro, num horário fixo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os três estados de saúde de um container com HEALTHCHECK. Ele começa em starting. A verificação roda a cada intervalo, cinco segundos no shelf; falhas durante o período inicial de cinco segundos não contam. Uma verificação que passa o leva a healthy. De healthy, três verificações seguidas que falham, os retries, o levam a unhealthy, e uma que passa o traz de volta a healthy. O Docker sozinho não faz nada em unhealthy: o container continua rodando, e um orquestrador ou uma pessoa precisa agir sobre o estado.\"><defs><marker id=\"l18health-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18health-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.8\"></rect><text x=\"100\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">starting</text><rect x=\"290\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">healthy</text><rect x=\"550\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></rect><text x=\"620\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">unhealthy</text><path d=\"M170 105 L290 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l18health-ah-phosphor)\"></path><text x=\"230\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma passa</text><path d=\"M430 95 L550 95\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l18health-ah-amber)\"></path><text x=\"490\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">retries=3 falham</text><path d=\"M550 118 L430 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l18health-ah-phosphor)\"></path><text x=\"490\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma passa</text><text x=\"100\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">start-period=5s:</text><text x=\"100\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falhas não contam</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">verificado a cada</text><text x=\"360\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">interval=5s</text><text x=\"620\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">continua rodando:</text><text x=\"620\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o Docker não faz nada</text><text x=\"360\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada verificação: /probe http://127.0.0.1:8080/health, saída 0 passa, qualquer outra falha, timeout=2s</text></svg>", "caption": "Um health check informa; ele não conserta. O estado é o sinal para outra coisa agir.", "same": ["start-period=5s:"]}
```

**E o Docker, sozinho, não faz nada a respeito.** O container continua rodando, não saudável, até algo
agir sobre o estado. O Compose consegue esperar um serviço ficar saudável antes de iniciar os que
dependem dele, e a aula 19 usa isso para o banco. O Swarm substitui containers não saudáveis. O
Kubernetes ignora o `HEALTHCHECK` por completo e tem as próprias probes, que a aula 22 do curso
`kubernetes` cobre; o endpoint `/health` é o que elas chamam, então o trabalho aproveita.
