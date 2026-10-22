---
title: Finishing what was started
version: 1
---

Lesson 16 ended with `docker stop` taking a fifth of a second, because boxoffice did nothing about
`SIGTERM` and Go's default is to exit on the spot. A purchase in the middle of its transaction is rolled
back by the database, and one that had just committed loses its answer, so its customer sees an error for
a sale that went through. **A graceful shutdown is the opposite order**: stop accepting new work, finish
the work in flight, then exit. Every deploy stops the old process, so this is not a rare path; it runs every time a new
version ships.

## The order of things

`main`, in section 07, waits for the signal with `signal.NotifyContext`, which returns a context that ends
at the first `SIGINT` or `SIGTERM`. Then, in order:

1. **Readiness says no.** `draining` is set, `/readyz` answers 503, and a load balancer that asks stops
   sending new requests here.
2. **`srv.Shutdown` closes the listeners**, so no new connection is accepted, closes the idle ones, and
   waits for the active ones to finish their requests, up to the shutdown timeout.
3. **The gRPC server's `GracefulStop`** does the same for gRPC calls, with the same deadline.
4. The ops server stops last, so readiness can be asked until the end, and `main` returns, closing the
   pool on its way out.

A second signal while this runs is not caught any more, because `stop` was called after the first; it
kills the process, which is what somebody pressing Ctrl-C twice means.

## Streams never finish

`Shutdown` waits for requests to end, and lesson 13's streams are requests built never to end. **Left
alone, every open stream would hold the shutdown to its deadline and then be cut.** `Shutdown` also does
not track hijacked connections at all, so every WebSocket would simply be dropped when `main` returned.
`RegisterOnShutdown` runs a function when shutdown begins, and the hub gets one to run: `close` closes a
channel, `done`, and every stream handler watches it.

```go
// boxoffice/live.go
package main

import (
	"context"
	"fmt"
	"log/slog"
	"sync"

	"github.com/jackc/pgx/v5/pgxpool"
)

// hub hands each change of an event's availability to everybody watching it.
type hub struct {
	mu   sync.Mutex
	subs map[int]map[chan int]struct{}
	done chan struct{} // closed when the server shuts down
	once sync.Once
}

func newHub() *hub {
	return &hub{subs: map[int]map[chan int]struct{}{}, done: make(chan struct{})}
}

// close tells every stream to end. It is safe to call more than once.
func (h *hub) close() {
	h.once.Do(func() { close(h.done) })
}

// count is how many subscriptions are open, for the metrics.
func (h *hub) count() int {
	h.mu.Lock()
	defer h.mu.Unlock()
	n := 0
	for _, subs := range h.subs {
		n += len(subs)
	}
	return n
}

// subscribe returns a channel of availabilities for one event, and the
// function that ends the subscription.
func (h *hub) subscribe(id int) (chan int, func()) {
	ch := make(chan int, 8)
	h.mu.Lock()
	if h.subs[id] == nil {
		h.subs[id] = map[chan int]struct{}{}
	}
	h.subs[id][ch] = struct{}{}
	h.mu.Unlock()
	return ch, func() {
		h.mu.Lock()
		delete(h.subs[id], ch)
		h.mu.Unlock()
	}
}

func (h *hub) publish(id, available int) {
	h.mu.Lock()
	defer h.mu.Unlock()
	for ch := range h.subs[id] {
		select {
		case ch <- available:
		default: // a watcher that is not keeping up misses this one, and nobody waits for it
		}
	}
}

// listen relays PostgreSQL's availability notifications to the hub until ctx ends.
func listen(ctx context.Context, pool *pgxpool.Pool, h *hub) error {
	conn, err := pool.Acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if _, err := conn.Exec(ctx, "LISTEN availability"); err != nil {
		return err
	}
	for {
		n, err := conn.Conn().WaitForNotification(ctx)
		if ctx.Err() != nil {
			return nil // shutting down is not a failure
		}
		if err != nil {
			return err
		}
		var id, available int
		if _, err := fmt.Sscan(n.Payload, &id, &available); err != nil {
			slog.Warn("unreadable notification", "payload", n.Payload)
			continue
		}
		h.publish(id, available)
	}
}
```

`close` uses `sync.Once`, because closing a closed channel panics. `count` is what section 04's gauge
reads. And `listen` now returns `nil` when its context ended, since a shutdown is not an error worth
logging as one.

```go
// boxoffice/sse.go
package main

import (
	"fmt"
	"net/http"
	"time"
)

// liveEvents streams an event's availability as server-sent events.
func liveEvents(store Store, h *hub) http.HandlerFunc {
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

		rc := http.NewResponseController(w)
		rc.SetWriteDeadline(time.Time{}) // this response is meant to outlive WriteTimeout
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-store")
		fmt.Fprintf(w, "data: %d\n\n", e.Seats-e.Sold)
		rc.Flush()
		for {
			select {
			case <-r.Context().Done():
				return
			case <-h.done:
				return // the server is shutting down; EventSource will reconnect elsewhere
			case n := <-ch:
				fmt.Fprintf(w, "data: %d\n\n", n)
				if err := rc.Flush(); err != nil {
					return
				}
			}
		}
	}
}
```

The server-sent event handler returns, which ends the response cleanly; `EventSource` reconnects, and with
another copy of boxoffice behind the load balancer it lands there.

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
			case <-h.done:
				c.Close(websocket.StatusGoingAway, "server shutting down")
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

The WebSocket sends a close frame with status 1001, `GoingAway`, the code the protocol defines for a server
going down, so the client knows to reconnect rather than treat it as an error.

## Watching it

Four terminals: the server, started in the foreground this time so its output is on screen; a stream; a purchase sent slowly, twenty bytes a second, so it is still in
flight when the signal arrives; and the signal itself, followed by a readiness check. The stream:

```
ana@vm:~/boxoffice$ curl -sN localhost:8080/events/1/live; echo "exit $?"
data: 120

exit 0
```

It received the current availability, then ended when shutdown began, with curl's status 0: the server
closed the response properly instead of dropping the connection. The slow purchase:

```
ana@vm:~/boxoffice$ curl -s -w ' %{http_code} after %{time_total}s\n' --limit-rate 20 --json '{"quantity": 1, "email": "slow@example.com"}' localhost:8080/events/1/tickets
{"ticket_id":1,"event_id":1,"quantity":1,"email":"slow@example.com","remaining":119}
 201 after 2.200352s
```

**201, after 2.2 seconds, more than a second after the signal.** The signal and the readiness check:

```
ana@vm:~/boxoffice$ kill -TERM $(pgrep -x boxoffice); sleep 0.2; curl -s localhost:9100/readyz
{"status":"shutting down"}
```

And the server's terminal, which was running it:

```
ana@vm:~/boxoffice$ BOXOFFICE_MANAGER_TOKEN_FILE=~/.config/boxoffice/manager-token ./boxoffice 2>&1 | cut -c1-200; echo "exit ${PIPESTATUS[0]}"
{"time":"2026-10-22T20:12:57.615841138-03:00","level":"INFO","msg":"starting","version":"dev","config":{"http":"localhost:8080","grpc":"localhost:9090","ops":"localhost:9100","max_conns":10,"write_tim
{"time":"2026-10-22T20:12:57.6236321-03:00","level":"INFO","msg":"grpc listening on 127.0.0.1:9090"}
{"time":"2026-10-22T20:12:57.623719353-03:00","level":"INFO","msg":"boxoffice listening on localhost:8080"}
{"time":"2026-10-22T20:12:59.130443613-03:00","level":"INFO","msg":"shutting down","timeout":"8s"}
{"time":"2026-10-22T20:12:59.130644811-03:00","level":"INFO","msg":"request","request_id":"b2ba5fd8a498ad9d","method":"GET","path":"/events/1/live","status":200,"bytes":11,"duration_ms":1299.89}
{"time":"2026-10-22T20:13:00.140507093-03:00","level":"INFO","msg":"request","request_id":"ba6d47aedaf8a80a","method":"POST","path":"/events/1/tickets","status":201,"bytes":85,"duration_ms":2005.712}
{"time":"2026-10-22T20:13:00.17202297-03:00","level":"INFO","msg":"stopped"}
exit 0
```

Read the times. The signal arrived at :59.130, and the stream's request was logged at the same
millisecond, ended by the hub. The purchase finished a second later, its 201 logged at :00.140, and only
then did the process report `stopped` and exit with status 0. **Nothing in flight was lost, and nothing
new was accepted.** `cut` shortens every line to 200 characters, which only the first one needed; and
`PIPESTATUS[0]` is boxoffice's exit status rather than `cut`'s.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 220\" role=\"img\" aria-label=\"A timeline of the shutdown in section 06, from the signal at 0 to exit at 1.04 seconds. At 0, SIGTERM: readiness turns 503, the listeners close, and the hub ends the open stream at once. The slow purchase, which started 1.0 seconds before the signal, carries on and is answered 201 at 1.01 seconds. The process logs stopped and exits with status 0 at 1.04 seconds.\"><defs><marker id=\"gb-l17-shutdown-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M 30 170 L 680 170\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M 116.9 165 L 116.9 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"116.9\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">−1.0 s</text><path d=\"M 373.3 165 L 373.3 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"373.3\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M 501.5 165 L 501.5 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"501.5\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.5 s</text><path d=\"M 640.0 165 L 640.0 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"640.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1.04 s</text><rect x=\"116.9\" y=\"112\" width=\"515.4\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"124.9\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">slow purchase, 20 bytes a second</text><text x=\"626.3\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">201</text><rect x=\"40.0\" y=\"76\" width=\"333.3\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"48.0\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">stream</text><path d=\"M 373.3 22 L 373.3 72\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><path d=\"M 373.3 142 L 373.3 165\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"379.3\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SIGTERM</text><text x=\"379.3\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">/readyz 503 · listeners closed · hub closed</text><path d=\"M 640.0 60 L 640.0 165\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"634.0\" y=\"66\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">stopped, exit 0</text></svg>", "caption": "Section 06's run, measured from the signal. New work stops at once; work in flight runs to its end."}
```

## How long to wait

The shutdown timeout is eight seconds by default, a lesson 14 setting like the others, and it has to be
shorter than the time the platform allows before it sends `SIGKILL`: ten seconds for `docker stop`, thirty
for Kubernetes by default. A process still draining when `SIGKILL` arrives loses everything it was doing,
and the timeout is there so that boxoffice cuts the last stragglers off itself, cleanly, first.

Kubernetes adds one more wrinkle: it removes a stopping pod from the load balancer and sends the signal at
about the same moment, so for a second or two requests can still arrive after the listener closed. A
common answer is to keep serving for a few seconds after readiness turns 503, before calling `Shutdown`.
boxoffice does not, and on a platform that needs it, that delay is one more setting.
