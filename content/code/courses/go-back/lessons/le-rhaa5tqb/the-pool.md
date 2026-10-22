---
title: The pool, and how big it should be
version: 1
---

Lesson 6 section 05 said a `sql.DB` is a pool, and `pgxpool.Pool` is the same idea: a set of open
connections, lent to whoever asks and given back when they finish. **A connection is expensive on both
sides**: PostgreSQL starts a process for each one, and opening one costs a round trip and an
authentication. The pool exists so that a busy server opens a few and reuses them. Its size decides two
things, how many queries can run at once, and what happens to the rest.

## A pool of two, six queries

This program gives the pool two connections and starts six queries that each take a second, with a
limit of 2.5 seconds on each:

```go
// poolwait/main.go
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	ctx := context.Background()
	cfg, err := pgxpool.ParseConfig(os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}
	cfg.MaxConns = 2
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	start := time.Now()
	var wg sync.WaitGroup
	for i := 1; i <= 6; i++ {
		wg.Go(func() {
			qctx, cancel := context.WithTimeout(ctx, 2500*time.Millisecond)
			defer cancel()
			_, err := pool.Exec(qctx, "SELECT pg_sleep(1)")
			fmt.Printf("query %d finished at %.1fs: %v\n", i, time.Since(start).Seconds(), err)
		})
	}
	wg.Wait()

	s := pool.Stat()
	fmt.Printf("max %d, acquired %d times, %d waited for a connection, %d gave up waiting\n",
		s.MaxConns(), s.AcquireCount(), s.EmptyAcquireCount(), s.CanceledAcquireCount())
}
```

```
ana@vm:~/poolwait$ psql boxoffice -c "SHOW max_connections"
 max_connections 
-----------------
 100
(1 row)

ana@vm:~/poolwait$ go run .
query 6 finished at 1.0s: <nil>
query 3 finished at 1.0s: <nil>
query 1 finished at 2.0s: <nil>
query 2 finished at 2.0s: <nil>
query 5 finished at 2.5s: timeout: context deadline exceeded
query 4 finished at 2.5s: timeout: context deadline exceeded
max 2, acquired 6 times, 6 waited for a connection, 0 gave up waiting
```

**Two at a time, in waves.** The first two finished at 1.0 s, the next two at 2.0 s, and the last two got
their connection at 2.0 s and had half a second left of their 2.5, so their queries were cancelled
mid-way, `timeout: context deadline exceeded`. **A query waiting for a connection spends its own
deadline waiting**, and nothing about the database was slow: it was the pool. `Stat` counts it, six
acquires and all six waited, which is what a pool too small for its load looks like from the inside.

## How big

`max_connections` is 100 on this server, Ubuntu's default, and every process connecting to the database
shares that number. **The sum of every pool's maximum must stay below it**, with room for `psql` and
for migrations: three copies of boxoffice with `MaxConns` 10 use 30. pgxpool's default maximum is four, or
the number of processors if that is larger; boxoffice sets 10 in `main`, section 04, and lets connections
idle for five minutes before closing them. Bigger is not better past a point: PostgreSQL does real work
per connection, and **a few busy connections usually serve more queries than many idle ones**.

## The line that stopped the pool

Section 06 left a program that sends twenty buyers at once. Here it is against an event with five seats,
with section 05's `pgStore`:

```
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json '{"name": "Organ Recital", "seats": 5}' localhost:8080/admin/events
{"id":3,"name":"Organ Recital","seats":5,"sold":0,"available":5}
ana@vm:~/rush$ go run . 3
201: 5  409: 0  no answer in 5s: 15
ana@vm:~/rush$ curl -s -m 3 localhost:8080/events; echo "exit $?"
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2,"available":118},{"id":2,"name":"Chamber Choir","seats":80,"sold":80,"available":0},{"id":3,"name":"Organ Recital","seats":5,"sold":5,"available":0}]
exit 0
ana@vm:~/rush$ psql boxoffice -c "SELECT count(*) FROM pg_stat_activity WHERE datname = 'boxoffice' AND state = 'idle in transaction'"
 count 
-------
     0
(1 row)

ana@vm:~/boxoffice$ tail -3 .server.log
2026/10/16 20:18:58 unexpected error: selling: context canceled
2026/10/16 20:18:58 POST /events/3/tickets 500 68B 5.000906s
2026/10/16 20:18:58 GET /events 200 207B 1.893ms
```

**Five sales, then fifteen requests with no answer at all for five seconds.** They had not failed; they
were stuck. The log shows how they ended: when `rush` gave up, the clients disconnected, `net/http`
cancelled each request's context, and the waiting calls returned `context canceled` after 5.000906 s,
as 500s. Only then did `curl` get its list, and by then no transaction was open any more.

The cause is one line in `Sell`, for a buyer who arrives when the seats are gone:

```go
if _, err := s.Get(ctx, id); err != nil {
```

At that moment the request **holds a connection, the transaction's, and asks the pool for a second one**
for `Get`. Ten requests at once, `MaxConns` of 10, each holding one and waiting for another: the pool is
empty, nobody gives a connection back, and nobody can proceed. **A deadlock inside the pool**, with every
part of it correct on its own. Without the client's five-second limit, nothing would have ended it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 255\" role=\"img\" aria-label=\"A pool drawn as ten slots, every one taken by a sale's transaction. Below, the same ten sales each ask the pool for a second connection, and their arrows end at the pool with nothing free. Ten more requests queue behind them.\"><defs><marker id=\"gb-l9-poolwait-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"670\" height=\"70\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"25\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the pool, MaxConns 10: all taken</text><rect x=\"25\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"54\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 1</text><rect x=\"90\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"119\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 2</text><rect x=\"155\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"184\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 3</text><rect x=\"220\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"249\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 4</text><rect x=\"285\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"314\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 5</text><rect x=\"350\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"379\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 6</text><rect x=\"415\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 7</text><rect x=\"480\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"509\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 8</text><rect x=\"545\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"574\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 9</text><rect x=\"610\" y=\"40\" width=\"58\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"639\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tx 10</text><rect x=\"25\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 1</text><path d=\"M 54 130 L 54 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"90\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"119\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 2</text><path d=\"M 119 130 L 119 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"155\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"184\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 3</text><path d=\"M 184 130 L 184 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"220\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"249\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 4</text><path d=\"M 249 130 L 249 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"285\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"314\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 5</text><path d=\"M 314 130 L 314 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"350\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"379\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 6</text><path d=\"M 379 130 L 379 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"415\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"444\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 7</text><path d=\"M 444 130 L 444 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"480\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"509\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 8</text><path d=\"M 509 130 L 509 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"545\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"574\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 9</text><path d=\"M 574 130 L 574 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><rect x=\"610\" y=\"130\" width=\"58\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"639\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get 10</text><path d=\"M 639 130 L 639 88\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gb-l9-poolwait-ah)\"></path><text x=\"350\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each sale asks for a second connection, and waits</text><rect x=\"15\" y=\"205\" width=\"670\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"350\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ten more buyers, waiting for their first connection</text></svg>", "caption": "MaxConns is 10. Each sold-out buyer holds one connection and waits for another, so none is ever given back."}
```

The fix is to ask through the connection already held, the transaction's:

```go
// boxoffice/pgstore.go
package main

import (
	"context"
	"errors"
	"fmt"
	"math"

	"example.com/boxoffice/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// pgStore keeps the events in PostgreSQL, through the code sqlc generated.
type pgStore struct {
	pool *pgxpool.Pool
}

func (s *pgStore) q() *db.Queries {
	return db.New(s.pool)
}

func fromRow(e db.Event) Event {
	return Event{ID: int(e.ID), Name: e.Name, Seats: int(e.Seats), Sold: int(e.Sold)}
}

// eventID converts an id for the int4 column, refusing what does not fit.
func eventID(id int) (int32, error) {
	if id < 1 || id > math.MaxInt32 {
		return 0, fmt.Errorf("event %d: %w", id, ErrNotFound)
	}
	return int32(id), nil
}

func (s *pgStore) List(ctx context.Context) ([]Event, error) {
	rows, err := s.q().ListEvents(ctx)
	if err != nil {
		return nil, fmt.Errorf("listing events: %w", err)
	}
	events := make([]Event, 0, len(rows))
	for _, r := range rows {
		events = append(events, fromRow(r))
	}
	return events, nil
}

func (s *pgStore) Get(ctx context.Context, id int) (Event, error) {
	id32, err := eventID(id)
	if err != nil {
		return Event{}, err
	}
	e, err := s.q().GetEvent(ctx, id32)
	if errors.Is(err, pgx.ErrNoRows) {
		return Event{}, fmt.Errorf("event %d: %w", id, ErrNotFound)
	}
	return fromRow(e), err
}

func (s *pgStore) Add(ctx context.Context, name string, seats int) (Event, error) {
	e, err := s.q().AddEvent(ctx, db.AddEventParams{Name: name, Seats: int32(seats)})
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return Event{}, fmt.Errorf("%q: %w", name, ErrDuplicate)
	}
	return fromRow(e), err
}

// Sell takes quantity seats and records the ticket, both or neither.
func (s *pgStore) Sell(ctx context.Context, id, quantity int, email string) (Sale, error) {
	id32, err := eventID(id)
	if err != nil {
		return Sale{}, err
	}
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Sale{}, fmt.Errorf("selling: %w", err)
	}
	defer tx.Rollback(ctx)
	q := s.q().WithTx(tx)

	e, err := q.SellSeats(ctx, db.SellSeatsParams{ID: id32, Quantity: int32(quantity)})
	if errors.Is(err, pgx.ErrNoRows) {
		// Ask through the transaction's own connection: s.Get would wait for a
		// second one while this one is held.
		if _, err := q.GetEvent(ctx, id32); errors.Is(err, pgx.ErrNoRows) {
			return Sale{}, fmt.Errorf("event %d: %w", id, ErrNotFound)
		}
		return Sale{}, fmt.Errorf("event %d: %w", id, ErrSoldOut)
	}
	if err != nil {
		return Sale{}, fmt.Errorf("selling: %w", err)
	}
	ticket, err := q.InsertTicket(ctx, db.InsertTicketParams{
		EventID: id32, Email: email, Quantity: int32(quantity),
	})
	if err != nil {
		return Sale{}, fmt.Errorf("recording the ticket: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return Sale{}, fmt.Errorf("committing the sale: %w", err)
	}
	return Sale{TicketID: int(ticket), Event: fromRow(e)}, nil
}
```

```
ana@vm:~/rush$ go run . 3
201: 5  409: 15  no answer in 5s: 0
ana@vm:~/rush$ psql boxoffice -c "SELECT count(*), sum(quantity) FROM tickets WHERE event_id = 3" -c "SELECT sold, seats FROM events WHERE id = 3"
 count | sum 
-------+-----
     5 |   5
(1 row)

 sold | seats 
------+-------
    5 |     5
(1 row)

ana@vm:~/rush$ curl -s -m 3 localhost:8080/events/3
{"id":3,"name":"Organ Recital","seats":5,"sold":5,"available":0}
ana@vm:~/boxoffice$ grep -c "tickets 201" .server.log; grep -c "tickets 409" .server.log
5
15
```

**Five tickets, fifteen honest 409s, and the table agrees: five sold of five.** The rule to keep from this
is short. **Inside a transaction, every query goes through the transaction**, and more generally, code
that holds one pooled resource must never wait for another from the same pool.
