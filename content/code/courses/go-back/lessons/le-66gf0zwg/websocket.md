---
title: A WebSocket of boxoffice's own
version: 1
---

A WebSocket starts as an HTTP request and stops being one. The client sends a `GET` with
`Upgrade: websocket` and a random key; the server agrees with status **101 Switching Protocols**, and from
then on the same TCP connection carries WebSocket frames in both directions, with no requests and no
responses. Either side can send a message at any moment.

Go's standard library has no WebSocket server. The package `golang.org/x/net/websocket` exists, and its
own documentation points to two others as more complete and better maintained:
**`github.com/gorilla/websocket`**, the oldest and most used, and **`github.com/coder/websocket`**,
smaller, with every blocking call taking a context. boxoffice uses the second, because a context is how
everything else in it already stops; section 06 meets the first, underneath a library built on it.

## The handler

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

// liveSocket sends an event's availability over a WebSocket, now and on every change.
func liveSocket(store Store, h *hub) http.HandlerFunc {
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
			OriginPatterns: []string{"tickets.example.com"},
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

It has the same shape as section 04's, with three differences that belong to WebSockets.

**`OriginPatterns` decides which sites' pages may connect.** A browser sends an `Origin` header on every
WebSocket handshake, naming the site whose page opened it, and here the same-origin rules that protect
`fetch` do not apply: any page on any site can open a WebSocket to boxoffice, and if boxoffice signed people in with cookies,
the browser would attach them. The CORS middleware of section 05 of lesson 2 is not consulted either, since
CORS governs `fetch` and not this. So the check is the server's, and `Accept` makes it: an `Origin` naming
the server's own host passes, one matching a pattern in the list passes, and anything else gets a 403. A
request with no `Origin` at all passes, because only browsers send one, and programs such as `curl` and
section 05's client are not where this attack comes from.

**`CloseRead` keeps reading so that the protocol keeps working.** boxoffice expects nothing from the
client, but the connection must still be read: a close or a ping from the client arrives as a frame, and
an unread frame is an unanswered one. `CloseRead` reads in a goroutine of its own, answers those frames,
and returns a context that ends when the connection closes. A data message from the client closes the
connection, because none is expected.

**Every write has five seconds.** A client that stops reading lets the connection's buffers fill, and a
write after that would wait for good. With a timeout, the write fails, the handler returns, and the
deferred `CloseNow` and `unsubscribe` clean up.

What the handler does not need is section 04's `SetWriteDeadline`. `Accept` takes the connection away
from net/http, which net/http calls hijacking, and net/http clears the connection's deadlines when it
hands it over; from then on they are the WebSocket's own business. `Accept` finds the connection through
lesson 2's `statusRecorder` the same way `http.ResponseController` did, by calling `Unwrap`.

## A client to watch with

curl can make the handshake, but it cannot read frames. This small client prints every message a
WebSocket sends for a time, and sends any further arguments first as text messages, which sections 06 and
07 will use:

```go
// boxoffice/cmd/watchws/main.go
package main

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"time"

	"github.com/coder/websocket"
)

// watchws prints what a WebSocket sends for a number of seconds.
func main() {
	limit, _ := time.ParseDuration(os.Args[2])
	ctx, cancel := context.WithTimeout(context.Background(), limit)
	defer cancel()
	c, resp, err := websocket.Dial(ctx, os.Args[1], nil)
	if err != nil {
		fmt.Println("error:", err)
		os.Exit(1)
	}
	defer c.CloseNow()
	fmt.Println("connected:", resp.Status)
	for _, msg := range os.Args[3:] {
		c.Write(ctx, websocket.MessageText, []byte(msg))
	}
	for {
		_, data, err := c.Read(ctx)
		if err != nil {
			fmt.Println("stopped:", ctx.Err())
			return
		}
		fmt.Printf("%s %s\n", time.Now().Format("15:04:05"), bytes.TrimSpace(data))
	}
}
```

## Wiring it in

The two new routes go in `routes.go`, which now takes the hub as well:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store Store, tokens map[string]string, live *hub) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))
	mux.HandleFunc("POST /events/{id}/tickets", buyTickets(store))
	mux.HandleFunc("GET /events/{id}/live", liveEvents(store, live))
	mux.HandleFunc("GET /events/{id}/ws", liveSocket(store, live))

	admin := http.NewServeMux()
	admin.HandleFunc("GET /admin/report", salesReport(store))
	admin.HandleFunc("POST /admin/events", createEvent(store))
	mux.Handle("/admin/", requireStaff(tokens)(admin))

	return chain(mux, requestID, logRequests, recoverPanics, cors("https://tickets.example.com"))
}
```

And `main.go` makes the hub and starts the listener before it starts serving:

```go
// boxoffice/main.go
package main

import (
	"context"
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

	tokens := map[string]string{}
	for role, name := range map[string]string{
		"manager": "BOXOFFICE_MANAGER_TOKEN",
		"door":    "BOXOFFICE_DOOR_TOKEN",
	} {
		if t := os.Getenv(name); t != "" {
			tokens[t] = role
		}
	}
	if len(tokens) == 0 {
		log.Fatal("no staff tokens: set BOXOFFICE_MANAGER_TOKEN")
	}

	url := os.Getenv("DATABASE_URL")
	if url == "" {
		log.Fatal("no database: set DATABASE_URL")
	}
	ctx := context.Background()
	if err := migrate(ctx, url); err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg.MaxConns = 10
	cfg.MaxConnIdleTime = 5 * time.Minute
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
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

	lis, err := net.Listen("tcp", "localhost:9090")
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
		Addr:              "localhost:8080",
		Handler:           routes(store, tokens, live),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

If `listen` fails, the error is logged and the server keeps answering, with live pages that no longer
change. That is a deliberate trade for now, and section 08 returns to it.

## The handshake, by hand

`curl` can send the four headers a handshake needs. The key below is the example from RFC 6455, the
WebSocket specification, and the answer is the one the RFC prints: the server hashes the key with a fixed
string and returns it, which proves the server understood the request was a WebSocket.

```
ana@vm:~/boxoffice$ curl -s -D - -o /dev/null -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -m 2 localhost:8080/events/1/ws
HTTP/1.1 101 Switching Protocols
Connection: Upgrade
Sec-Websocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
Upgrade: websocket
Vary: Origin
X-Request-Id: c5f5c495ac74eb8e
Date: Thu, 22 Oct 2026 22:35:50 GMT

```

The same request with an `Origin` from another site is refused before any upgrade, with the reason in the
body:

```
ana@vm:~/boxoffice$ curl -si -H "Origin: https://elsewhere.example.net" -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -m 2 localhost:8080/events/1/ws
HTTP/1.1 403 Forbidden
Content-Type: text/plain; charset=utf-8
Vary: Origin
X-Content-Type-Options: nosniff
X-Request-Id: 0127182e3c8046a8
Date: Thu, 22 Oct 2026 22:35:52 GMT
Content-Length: 83

request Origin "elsewhere.example.net" is not authorized for Host "localhost:8080"
```

And the client sees the availability when it connects, then a purchase of two seats made while it
watched:

```
ana@vm:~/boxoffice$ ./watchws ws://localhost:8080/events/1/ws 3s
connected: 101 Switching Protocols
19:35:52 {"event_id":1,"available":114}
19:35:53 {"event_id":1,"available":112}
stopped: context deadline exceeded
```

All three requests, and section 04's stream, are in the access log, with status 101 for the upgrades and a
duration that is the time the connection stayed open:

```
ana@vm:~/boxoffice$ grep -e /live -e /ws .server.log
{"time":"2026-10-22T19:35:49.505524262-03:00","level":"INFO","msg":"request","request_id":"08468f766a8feb95","method":"GET","path":"/events/1/live","status":200,"bytes":33,"duration_ms":13996.947}
{"time":"2026-10-22T19:35:52.576858836-03:00","level":"INFO","msg":"request","request_id":"c5f5c495ac74eb8e","method":"GET","path":"/events/1/ws","status":101,"bytes":0,"duration_ms":2002.501}
{"time":"2026-10-22T19:35:52.597473794-03:00","level":"INFO","msg":"request","request_id":"0127182e3c8046a8","method":"GET","path":"/events/1/ws","status":403,"bytes":83,"duration_ms":0.531}
{"time":"2026-10-22T19:35:55.614706057-03:00","level":"INFO","msg":"request","request_id":"96819eed763c7dac","method":"GET","path":"/events/1/ws","status":101,"bytes":0,"duration_ms":3001.872}
```
