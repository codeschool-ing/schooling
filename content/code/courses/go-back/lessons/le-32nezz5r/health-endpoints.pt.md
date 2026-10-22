---
title: Dois endpoints, duas perguntas
version: 1
---

```go
// boxoffice/health.go
package main

import (
	"context"
	"net/http"
	"sync/atomic"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// health is what boxoffice says about itself to whatever runs it.
type health struct {
	pool     *pgxpool.Pool
	draining atomic.Bool // set when shutdown begins
}

// live answers whether the process is working at all. It touches nothing
// outside the process, so a database that is down never makes it fail.
func (h *health) live(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok", "version": version})
}

// ready answers whether this process should be sent requests now.
func (h *health) ready(w http.ResponseWriter, r *http.Request) {
	if h.draining.Load() {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "shutting down"})
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), time.Second)
	defer cancel()
	if err := h.pool.Ping(ctx); err != nil {
		logger(r.Context()).Warn("not ready", "err", err)
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "no database"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}
```

O `live` responde 200 com a versão, e mais nada: se o processo consegue rodar um handler, ele está vivo.
Incluir a versão não custa nada e responde a primeira pergunta que qualquer pessoa faz num deploy, qual
build está rodando onde. O `ready` responde 503 enquanto o processo está drenando e, fora isso, faz um ping
no banco **com limite de um segundo**, porque uma verificação de prontidão que espera tanto quanto o banco
responde tarde demais para servir, e uma plataforma chamando-a a cada poucos segundos empilharia as
chamadas. Os dois respondem JSON com o mesmo `writeJSON` de todo outro handler.

A seção 07 os põe no listener de ops como `/healthz` e `/readyz`, nomes que são uma convenção e não um
padrão. As transcrições desta aula vêm desse servidor pronto, gerado e iniciado como antes:

```
ana@vm:~/boxoffice$ go vet ./... && go test -count=1 ./... | head -1 && go build -o boxoffice . && echo built
ok  	example.com/boxoffice	0.040s
built
ana@vm:~/boxoffice$ head -1 .server.log
{"time":"2026-10-22T20:12:49.670448004-03:00","level":"INFO","msg":"starting","version":"dev","config":{"http":"localhost:8080","grpc":"localhost:9090","ops":"localhost:9100","max_conns":10,"write_timeout":"10s","shutdown_timeout":"8s","origin":"https://tickets.example.com","database_url":"[hidden]","staff_tokens":1}}
```

A primeira linha do log agora nomeia o endereço de ops e o timeout de desligamento, que a seção 06 explica.

## Perguntando

```
ana@vm:~/boxoffice$ curl -si localhost:9100/healthz; curl -si localhost:9100/readyz
HTTP/1.1 200 OK
Content-Type: application/json
Date: Thu, 22 Oct 2026 23:12:49 GMT
Content-Length: 32

{"status":"ok","version":"dev"}
HTTP/1.1 200 OK
Content-Type: application/json
Date: Thu, 22 Oct 2026 23:12:49 GMT
Content-Length: 19

{"status":"ready"}
```

Os dois 200. Agora pare o banco por baixo dele, como uma falha faria:

```
ana@vm:~/boxoffice$ sudo pg_ctlcluster 16 main stop
ana@vm:~/boxoffice$ curl -s localhost:9100/healthz; curl -s localhost:9100/readyz; curl -s localhost:8080/events/1
{"status":"ok","version":"dev"}
{"status":"no database"}
{"type":"about:blank","title":"Internal Server Error","status":500}
```

**Vivo, não pronto, e uma requisição comum falha com o 500 da aula 3.** É a resposta certa para cada
pergunta: o processo está bem e não deve ser reiniciado; não consegue atender, e não deve receber tráfego.
Inicie o banco de novo, e a prontidão volta sozinha, porque o pool abre conexões novas quando as antigas
somem:

```
ana@vm:~/boxoffice$ sudo pg_ctlcluster 16 main start; sleep 1; curl -s localhost:9100/readyz
{"status":"ready"}
```

## O que o log diz, e o que a prontidão deixou passar

```
ana@vm:~/boxoffice$ grep -e "not ready" -e "listening for" -e "unexpected" .server.log
{"time":"2026-10-22T20:12:49.938693528-03:00","level":"ERROR","msg":"listening for availability","err":"FATAL: terminating connection due to administrator command (SQLSTATE 57P01)"}
{"time":"2026-10-22T20:12:50.062340805-03:00","level":"WARN","msg":"not ready","err":"write failed: write unix @->/var/run/postgresql/.s.PGSQL.5432: write: broken pipe"}
{"time":"2026-10-22T20:12:50.068439723-03:00","level":"INFO","msg":"unexpected error: failed to connect to `user=ana database=boxoffice`: /var/run/postgresql/.s.PGSQL.5432 (/var/run/postgresql): dial error: dial unix /var/run/postgresql/.s.PGSQL.5432: connect: no such file or directory"}
```

A segunda linha é a prontidão percebendo. A terceira é a causa do 500, registrada em `INFO` porque o `fail`
ainda usa o velho `log.Printf` que a aula 12 ligou ao slog sem converter.

**A primeira linha é a importante.** Quando o banco caiu, o `listen` da aula 13 perdeu a conexão e
retornou, como foi escrito para fazer; o `main` registrou o erro, e nada o iniciou de novo. A prontidão
voltou a "ready", toda requisição funciona, e **toda página ao vivo está congelada**, porque ninguém está
mais escutando notificações. A verificação de saúde verificou o que mandaram verificar. A seção 08 da aula
13 nomeou a correção, um laço que reconecta e volta a escutar; a outra metade é fazer a prontidão incluí-lo,
para um processo cujas atualizações ao vivo morreram dizer isso. As duas são poucas linhas, e ficam para
você.
