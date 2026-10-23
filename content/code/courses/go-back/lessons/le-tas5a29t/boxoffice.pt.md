---
title: O boxoffice, configurado
version: 1
---

O `main` agora começa com o `load`, e tudo o que ele lia ou tinha escrito no código vem do `config`:

```go
// boxoffice/main.go
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log"
	"log/slog"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	slog.SetDefault(newLogger(os.Stdout))

	cfg, err := load(os.Args[1:], os.Getenv)
	if errors.Is(err, flag.ErrHelp) {
		return
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "boxoffice: %v\n", err)
		os.Exit(2)
	}
	slog.Info("starting", "config", cfg)

	ctx := context.Background()
	if err := migrate(ctx, string(cfg.DatabaseURL)); err != nil {
		log.Fatalf("database: %v", err)
	}
	pcfg, err := pgxpool.ParseConfig(string(cfg.DatabaseURL))
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	pcfg.MaxConns = int32(cfg.MaxConns)
	pcfg.MaxConnIdleTime = 5 * time.Minute
	pool, err := pgxpool.NewWithConfig(ctx, pcfg)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("database: %v", err)
	}
	store := &pgStore{pool: pool}
	live := newHub()
	go func() {
		if err := listen(ctx, pool, live); err != nil {
			slog.Error("listening for availability", "err", err)
		}
	}()

	lis, err := net.Listen("tcp", cfg.GRPCAddr)
	if err != nil {
		log.Fatalf("grpc: %v", err)
	}
	go func() {
		log.Printf("grpc listening on %s", lis.Addr())
		if err := newGRPCServer(store).Serve(lis); err != nil {
			log.Fatalf("grpc: %v", err)
		}
	}()

	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           routes(store, cfg, live),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      cfg.WriteTimeout,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

**O `flag.ErrHelp` não é uma falha**: a ajuda já foi impressa e o programa termina com status 0. Qualquer
outro erro é impresso e o termina com status 2, como os do próprio pacote flag. A configuração é registrada
no log antes de qualquer outra coisa acontecer, e o tamanho do pool, os endereços e o timeout de escrita
vêm dela.

O `routes` recebe a configuração inteira em vez de só os tokens, e entrega o site aos dois lugares que
precisam dele:

```go
// boxoffice/routes.go
package main

import (
	"net/http"
	"net/url"
)

func routes(store Store, cfg config, live *hub) http.Handler {
	site, _ := url.Parse(cfg.Origin) // load has refused an origin that does not parse

	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))
	mux.HandleFunc("POST /events/{id}/tickets", buyTickets(store))
	mux.HandleFunc("GET /events/{id}/live", liveEvents(store, live))
	mux.HandleFunc("GET /events/{id}/ws", liveSocket(store, live, site.Host))

	admin := http.NewServeMux()
	admin.HandleFunc("GET /admin/report", salesReport(store))
	admin.HandleFunc("POST /admin/events", createEvent(store))
	mux.Handle("/admin/", requireStaff(cfg.Tokens)(admin))

	return chain(mux, requestID, logRequests, recoverPanics, cors(cfg.Origin))
}
```

O `liveSocket` recebe o host do site, `tickets.example.com`, que é a forma com que o `OriginPatterns`
compara, em vez de uma cópia própria do nome:

```go
// boxoffice/ws.go
package main

import (
	"context"
	"net/http"
	"time"

	"github.com/coder/websocket"
	"github.com/coder/websocket/wsjson"
)

type availability struct {
	EventID   int `json:"event_id"`
	Available int `json:"available"`
}

// liveSocket sends an event's availability over a WebSocket, now and on every
// change. Pages from site, a host such as tickets.example.com, may open one.
func liveSocket(store Store, h *hub, site string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		ch, unsubscribe := h.subscribe(id) // before reading, so no sale falls between the two
		defer unsubscribe()
		e, err := store.Get(r.Context(), id)
		if err != nil {
			fail(w, err)
			return
		}
		c, err := websocket.Accept(w, r, &websocket.AcceptOptions{
			OriginPatterns: []string{site},
		})
		if err != nil {
			return // Accept has already answered the client
		}
		defer c.CloseNow()

		ctx := c.CloseRead(r.Context()) // nothing is read; a close from the client ends ctx
		send := func(n int) error {
			wctx, cancel := context.WithTimeout(ctx, 5*time.Second)
			defer cancel()
			return wsjson.Write(wctx, c, availability{EventID: id, Available: n})
		}
		if send(e.Seats-e.Sold) != nil {
			return
		}
		for {
			select {
			case <-ctx.Done():
				c.Close(websocket.StatusNormalClosure, "")
				return
			case n := <-ch:
				if send(n) != nil {
					return
				}
			}
		}
	}
}
```

## Fora do profile

Tire as duas linhas `export BOXOFFICE_…_TOKEN` do `~/.profile` e abra um terminal novo, para que elas
sumam do ambiente dele. O resto desta seção roda nesse terminal.

## Pedindo ajuda

```
ana@vm:~/boxoffice$ go vet ./... && go build -o boxoffice . && ./boxoffice -h; echo "exit $?"
Usage of boxoffice:
  -grpc address
    	address the gRPC service listens on ($BOXOFFICE_GRPC) (default "localhost:9090")
  -http address
    	address the HTTP API listens on ($BOXOFFICE_HTTP) (default "localhost:8080")
  -max-conns int
    	most database connections open at once ($BOXOFFICE_MAX_CONNS) (default 10)
  -origin site
    	the site whose pages may call the API ($BOXOFFICE_ORIGIN) (default "https://tickets.example.com")
  -write-timeout duration
    	longest an ordinary response may take to write ($BOXOFFICE_WRITE_TIMEOUT) (default 10s)
exit 0
```

Cada flag, com padrão e variável, a partir das declarações no `load`.

## Recusando

Três variáveis definidas errado de propósito, e o `DATABASE_URL` retirado só para este comando:

```
ana@vm:~/boxoffice$ env -u DATABASE_URL BOXOFFICE_MAX_CONNS=1 BOXOFFICE_WRITE_TIMEOUT=ten BOXOFFICE_ORIGIN=tickets.example.com ./boxoffice; echo "exit $?"
boxoffice: BOXOFFICE_WRITE_TIMEOUT="ten": parse error
DATABASE_URL: not set
BOXOFFICE_MANAGER_TOKEN: not set, so no staff could sign in
max-conns 1: at least 2 are needed, one for LISTEN and one for queries
origin "tickets.example.com": want a site such as https://tickets.example.com
exit 2
```

Quatro erros, e uma quinta linha para o token que este terminal não tem mais: todos os problemas de uma
vez, e nada iniciou. Nenhuma migração rodou e nenhuma porta foi aberta. O timeout é informado com a
variável que o trouxe. Um arquivo que falta é informado como faltando, e o token que ele deveria fornecer,
como ausente:

```
ana@vm:~/boxoffice$ BOXOFFICE_MANAGER_TOKEN_FILE=/nowhere ./boxoffice; echo "exit $?"
boxoffice: BOXOFFICE_MANAGER_TOKEN_FILE: open /nowhere: no such file or directory
BOXOFFICE_MANAGER_TOKEN: not set, so no staff could sign in
exit 2
```

Uma flag escrita errado recebe a mensagem e a ajuda do pacote flag, e depois a linha do próprio boxoffice,
a última:

```
ana@vm:~/boxoffice$ ./boxoffice -htp localhost:8080 2>&1 | tail -1
boxoffice: flag provided but not defined: -htp
```

## Iniciando

Crie um arquivo para o token do gerente, legível só por você. Os parênteses rodam o `umask 077` num
subshell, para o arquivo já nascer privado em vez de ficar privado um instante depois de existir:

```
ana@vm:~/boxoffice$ mkdir -p ~/.config/boxoffice && (umask 077; openssl rand -hex 16 > ~/.config/boxoffice/manager-token) && ls -l ~/.config/boxoffice
total 4
-rw------- 1 ana ana 33 Oct 22 19:43 manager-token
```

Inicie o boxoffice com o caminho do arquivo, um tamanho de pool no ambiente e outro diferente como flag:

```
ana@vm:~/boxoffice$ BOXOFFICE_MANAGER_TOKEN_FILE=~/.config/boxoffice/manager-token BOXOFFICE_MAX_CONNS=4 ./boxoffice -max-conns 6
```

A primeira linha do log é a configuração com que ele começou:

```
ana@vm:~/boxoffice$ head -2 .server.log
{"time":"2026-10-22T19:43:17.553287632-03:00","level":"INFO","msg":"starting","config":{"http":"localhost:8080","grpc":"localhost:9090","max_conns":6,"write_timeout":"10s","origin":"https://tickets.example.com","database_url":"[hidden]","staff_tokens":1}}
{"time":"2026-10-22T19:43:17.561100504-03:00","level":"INFO","msg":"boxoffice listening on localhost:8080"}
```

**`max_conns` é 6**: a flag venceu a variável, como a ordem da seção 07 manda. A URL do banco aparece como
`[hidden]`, e os tokens, como uma contagem. E o token do arquivo funciona:

```
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $(cat ~/.config/boxoffice/manager-token)" localhost:8080/admin/report
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0},{"id":2,"name":"Chamber Choir","seats":80,"sold":80}]
```

Um token da portaria funciona do mesmo jeito, com `BOXOFFICE_DOOR_TOKEN_FILE`. A aula 16 entrega ao
boxoffice os endereços por essas mesmas variáveis, dentro de um container.
