---
title: boxoffice's store, generated
version: 1
---

`pgStore` keeps its job, satisfying lesson 6's `Store`, and gives up writing SQL. Every method now calls
a generated function and converts its result, so `pgstore.go` is rewritten. **The handlers, the routes
and `main` do not change at all**, because they only ever saw the interface:

```go
// boxoffice/pgstore.go
package main

import (
	"context"
	"errors"
	"fmt"

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
	e, err := s.q().GetEvent(ctx, int32(id))
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

// Sell takes quantity seats in one statement, so two buyers cannot both get the last one.
func (s *pgStore) Sell(ctx context.Context, id, quantity int) (Event, error) {
	e, err := s.q().SellSeats(ctx, db.SellSeatsParams{ID: int32(id), Quantity: int32(quantity)})
	if errors.Is(err, pgx.ErrNoRows) {
		if _, err := s.Get(ctx, id); err != nil {
			return Event{}, err
		}
		return Event{}, fmt.Errorf("event %d: %w", id, ErrSoldOut)
	}
	return fromRow(e), err
}
```

`q()` wraps the pool in the generated `Queries` each time it is called, which costs nothing more than a
small struct: the pool is the expensive thing, and it is shared. `fromRow` converts the generated `Event`
into boxoffice's, field by field. The error handling is lesson 6's, word for word.

`go mod tidy` and `go vet` are quiet, and the server answers as it did in lesson 6:

```
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ curl -s localhost:8080/events
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120},{"id":2,"name":"Chamber Choir","seats":80,"sold":80,"available":0}]
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"quantity":2,"email":"ana@example.com","remaining":118}
ana@vm:~/boxoffice$ curl -s localhost:8080/events/9
{"type":"about:blank","title":"Not Found","status":404,"detail":"event 9: no such event"}
```

## A bug no test above would find

There is one more request worth sending. An event id is a number in the path, and lesson 1 parses it with
`strconv.Atoi`, which accepts anything that fits a Go `int`, 64 bits here. **The column is `integer`, 32
bits, and the conversion `int32(id)` does not check**:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events/4294967297
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2,"available":118}
```

**Event 4294967297 does not exist, and boxoffice answered with event 1.** 4,294,967,297 is 2³² + 1, and
converting it to `int32` keeps the low 32 bits, which are the number 1. Go defines that wrap-around as
the result of the conversion, so nothing panics and nothing is logged; the query asked PostgreSQL, quite
correctly, for event 1.

Lesson 6's hand-written store did not have this bug: it passed the `int` to pgx, which checks that a
value fits the column's type and refuses one that does not, so the same request ended in a 500. That
was not the right answer either, and it was not somebody else's event. **The generated code is typed more precisely,
and the precision moved the check into the line where you convert**, which is the line you write. The fix
is a function that refuses what does not fit, and the store uses it wherever an id goes in:

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

// Sell takes quantity seats in one statement, so two buyers cannot both get the last one.
func (s *pgStore) Sell(ctx context.Context, id, quantity int) (Event, error) {
	id32, err := eventID(id)
	if err != nil {
		return Event{}, err
	}
	e, err := s.q().SellSeats(ctx, db.SellSeatsParams{ID: id32, Quantity: int32(quantity)})
	if errors.Is(err, pgx.ErrNoRows) {
		if _, err := s.Get(ctx, id); err != nil {
			return Event{}, err
		}
		return Event{}, fmt.Errorf("event %d: %w", id, ErrSoldOut)
	}
	return fromRow(e), err
}
```

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events/4294967297
{"type":"about:blank","title":"Not Found","status":404,"detail":"event 4294967297: no such event"}
ana@vm:~/boxoffice$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2,"available":118}
ana@vm:~/boxoffice$ cat .server.log
2026/10/16 20:08:19 boxoffice listening on localhost:8080
2026/10/16 20:08:19 GET /events/4294967297 404 99B 1.013ms
2026/10/16 20:08:19 GET /events/1 200 73B 1.691ms
```

An id outside the column's range is now an event that does not exist, which is what it is. **Whenever
generated types are narrower than your own, the conversion is where to look**; the same applies to
`Seats` and `quantity`, which validation already keeps within 10,000 and 10.
