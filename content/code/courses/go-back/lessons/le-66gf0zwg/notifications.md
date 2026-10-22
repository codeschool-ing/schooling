---
title: Where the news comes from
version: 1
---

A seat is sold in `Sell`, inside the transaction lesson 9 wrote. The obvious place to announce the sale is
right there: after the commit, tell everybody watching. That works for one process and breaks at the
first change of shape. Two copies of boxoffice behind a load balancer each see half the sales. The gRPC
service of lesson 10 writes through the same store. A manager fixing a row by hand in `psql` goes around
the program altogether.

**The database is the one place every sale passes through**, and PostgreSQL can announce changes itself.
`NOTIFY` sends a short message on a named channel; every session that has run `LISTEN` on that channel
receives it. A trigger makes the database send one whenever `sold` changes, so nothing in Go has to
remember to:

```sql
-- boxoffice/migrations/00003_availability_notify.sql
-- +goose Up
-- +goose StatementBegin
CREATE FUNCTION notify_availability() RETURNS trigger AS $$
BEGIN
    PERFORM pg_notify('availability', NEW.id || ' ' || (NEW.seats - NEW.sold));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

CREATE TRIGGER events_availability AFTER UPDATE OF sold ON events
    FOR EACH ROW EXECUTE FUNCTION notify_availability();

-- +goose Down
DROP TRIGGER events_availability ON events;
DROP FUNCTION notify_availability();
```

The function runs after every `UPDATE` that touches `sold`, once per row, and `pg_notify` queues a
message on the channel `availability` carrying the event's id and its seats left, as text: `1 118`.
Three properties make this a good source of news rather than merely a convenient one:

- **The message is delivered when the transaction commits, and never if it rolls back.** A sale that
  failed halfway announces nothing, so a page cannot show a seat as gone that is still for sale.
- **The message says what is true now**, the number of seats left, not "three more sold". A listener that
  missed one message is corrected by the next.
- **It costs no new infrastructure.** The connection boxoffice already has is the channel.

The payload is limited to just under 8000 bytes, which is why it carries an id and a number and not the
whole event. The `StatementBegin` and `StatementEnd` marks are goose's. It sends a migration to the database one
statement at a time, cutting at the semicolons, and a function body is full of semicolons; between the
two marks it sends everything as one statement.

## A hub in the process

The other half is Go. One goroutine listens, and a hub hands each message to every handler watching that
event:

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
}

func newHub() *hub {
	return &hub{subs: map[int]map[chan int]struct{}{}}
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

**`listen` takes one connection out of the pool and never gives it back.** `LISTEN` belongs to a database
session, and a pooled connection returned after it would carry the subscription into whatever query
borrowed it next. So the pool lesson 9 sized at ten now has nine for queries, and `WaitForNotification`
sleeps on the tenth until a message arrives or the context ends.

The hub is a map from an event id to the channels of the handlers watching it. `subscribe` makes a
channel and returns it with the function that removes it again; `publish` offers the number to every
channel of that event. **The offer does not wait.** Each channel holds eight values, and a watcher whose
eight are still unread misses this one. The alternative is worse: `publish` holds the lock while it
sends, so one browser on a bad connection would stop the news for everybody. Dropping is cheap here
because every message is a whole number of seats, and the next sale brings the next one. What it costs is
in section 08.

## Watching it happen

Build boxoffice and start it as before. It applies the new migration on its way up:

```
ana@vm:~/boxoffice$ go vet ./... && go build -o boxoffice . && echo built
built
ana@vm:~/boxoffice$ head -4 .server.log
{"time":"2026-10-22T19:35:32.257885238-03:00","level":"INFO","msg":"migration 00003_availability_notify.sql applied in 3.114951ms"}
{"time":"2026-10-22T19:35:32.261131988-03:00","level":"INFO","msg":"boxoffice listening on localhost:8080"}
{"time":"2026-10-22T19:35:32.26119697-03:00","level":"INFO","msg":"grpc listening on 127.0.0.1:9090"}
```

`psql` can listen too, which shows the database half working before any Go is involved. Ask it to listen
and then sleep for two seconds:

```
ana@vm:~/boxoffice$ psql boxoffice -c 'LISTEN availability' -c 'SELECT pg_sleep(2)'
LISTEN
 pg_sleep 
----------
 
(1 row)

Asynchronous notification "availability" with payload "1 118" received from server process with PID 22518.
```

While it sleeps, buy two seats from a third terminal, as in lesson 3:

```sh
curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
```

The notification appears after the sleep, because `psql` only looks for them between commands. **`1 118`
is event 1 with 118 seats left**, and the process id is the PostgreSQL backend serving boxoffice's
connection, the one whose `UPDATE` fired the trigger. boxoffice's own `listen` received the same message
at the same moment; the next section gives it somewhere to go.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"A sale goes from buyTickets and Sell to PostgreSQL, where the UPDATE fires a trigger that calls pg_notify. On commit the notification reaches listen, which holds one connection with LISTEN availability. listen hands it to the hub, and the hub to liveEvents, which writes data lines to an EventSource page, and to liveSocket, which writes JSON messages to a WebSocket client.\"><defs><marker id=\"gb-l13-flow-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"30\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">buyTickets</text><text x=\"90\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Sell</text><path d=\"M 165 55 L 213 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><rect x=\"215\" y=\"15\" width=\"200\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"315\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UPDATE events</text><text x=\"315\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">pg_notify('availability')</text><path d=\"M 415 55 L 473 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><text x=\"444\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">commit</text><rect x=\"475\" y=\"30\" width=\"200\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">listen</text><text x=\"575\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">LISTEN availability</text><path d=\"M 575 80 L 575 143\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><rect x=\"520\" y=\"145\" width=\"110\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hub</text><path d=\"M 520 158 L 480 158 L 480 137 L 427 137\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><path d=\"M 520 176 L 480 176 L 480 207 L 427 207\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><rect x=\"255\" y=\"115\" width=\"170\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">liveEvents</text><text x=\"340\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">data: 118</text><rect x=\"255\" y=\"185\" width=\"170\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">liveSocket</text><text x=\"340\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{\"available\":118}</text><path d=\"M 255 137 L 167 137\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><path d=\"M 255 207 L 167 207\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><rect x=\"15\" y=\"115\" width=\"150\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"90\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a page</text><text x=\"90\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">EventSource</text><rect x=\"15\" y=\"185\" width=\"150\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"90\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a client</text><text x=\"90\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">WebSocket</text></svg>", "caption": "Every sale passes through the database, so the database announces it. One connection listens, and the hub hands the number to each open page."}
```
