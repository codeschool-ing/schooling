---
title: Two endpoints, two questions
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

`live` answers 200 with the version, and nothing else: if the process can run a handler, it is alive.
Including the version costs nothing and answers the first question anybody asks during a deploy, which
build is running where. `ready` answers 503 while the process is draining, and otherwise pings the
database **with a one-second limit**, because a readiness check that waits as long as the database does
answers too late to be useful, and a platform calling it every few seconds would pile the calls up. Both
answer JSON with the same `writeJSON` as every other handler.

Section 07 puts them on the ops listener as `/healthz` and `/readyz`, names that are a convention rather
than a standard. The transcripts in this lesson come from that finished server, built and started as
before:

```
ana@vm:~/boxoffice$ go vet ./... && go test -count=1 ./... | head -1 && go build -o boxoffice . && echo built
ok  	example.com/boxoffice	0.040s
built
ana@vm:~/boxoffice$ head -1 .server.log
{"time":"2026-10-22T20:12:49.670448004-03:00","level":"INFO","msg":"starting","version":"dev","config":{"http":"localhost:8080","grpc":"localhost:9090","ops":"localhost:9100","max_conns":10,"write_timeout":"10s","shutdown_timeout":"8s","origin":"https://tickets.example.com","database_url":"[hidden]","staff_tokens":1}}
```

The first line of the log now names the ops address and the shutdown timeout, which section 06 explains.

## Asking

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

Both 200. Now stop the database under it, as a failure would:

```
ana@vm:~/boxoffice$ sudo pg_ctlcluster 16 main stop
ana@vm:~/boxoffice$ curl -s localhost:9100/healthz; curl -s localhost:9100/readyz; curl -s localhost:8080/events/1
{"status":"ok","version":"dev"}
{"status":"no database"}
{"type":"about:blank","title":"Internal Server Error","status":500}
```

**Alive, not ready, and an ordinary request fails with lesson 3's 500.** That is the right answer to each
question: the process is fine and should not be restarted; it cannot serve, and should not be sent
traffic. Start the database again, and readiness comes back by itself, because the pool opens new
connections when the old ones are gone:

```
ana@vm:~/boxoffice$ sudo pg_ctlcluster 16 main start; sleep 1; curl -s localhost:9100/readyz
{"status":"ready"}
```

## What the log says, and what readiness missed

```
ana@vm:~/boxoffice$ grep -e "not ready" -e "listening for" -e "unexpected" .server.log
{"time":"2026-10-22T20:12:49.938693528-03:00","level":"ERROR","msg":"listening for availability","err":"FATAL: terminating connection due to administrator command (SQLSTATE 57P01)"}
{"time":"2026-10-22T20:12:50.062340805-03:00","level":"WARN","msg":"not ready","err":"write failed: write unix @->/var/run/postgresql/.s.PGSQL.5432: write: broken pipe"}
{"time":"2026-10-22T20:12:50.068439723-03:00","level":"INFO","msg":"unexpected error: failed to connect to `user=ana database=boxoffice`: /var/run/postgresql/.s.PGSQL.5432 (/var/run/postgresql): dial error: dial unix /var/run/postgresql/.s.PGSQL.5432: connect: no such file or directory"}
```

The second line is readiness noticing. The third is the 500's cause, logged at `INFO` because `fail` still
uses the old `log.Printf` that lesson 12 bridged into slog without converting.

**The first line is the important one.** When the database went down, lesson 13's `listen` lost its
connection and returned, as it was written to; `main` logged the error, and nothing started it again.
Readiness came back to "ready", every request works, and **every live page is frozen**, because nobody is
listening for notifications any more. The health check checked what it was told to check. Lesson 13's
section 08 named the fix, a loop that reconnects and listens again; the other half is making readiness
include it, so a process whose live updates are dead says so. Both are a few lines, and they are left to
you.
