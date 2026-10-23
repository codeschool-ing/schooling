---
title: Transactions: two writes, one fate
version: 1
---

A sale is now two writes: **take the seats from `events`, and add a row to `tickets`.** If the first
succeeds and the second fails, the event says seats were sold that no ticket records; if they ran in the
other order, a ticket would exist for seats nobody took. Neither half may happen without the other, and
that is what a transaction is for: **a group of statements that the database applies completely or not
at all**, which `sql-databases` lesson 8 covers from the SQL side.

## In psql first

The behaviour is easiest to see by hand. This sells two seats and then tries to record a ticket of 20,
which the `CHECK` in `tickets` refuses:

```
ana@vm:~/boxoffice$ psql boxoffice <<'SQL'
BEGIN;
UPDATE events SET sold = sold + 2 WHERE id = 1;
INSERT INTO tickets (event_id, email, quantity) VALUES (1, 'rui@example.com', 20);
COMMIT;
SELECT sold FROM events WHERE id = 1;
SQL
BEGIN
UPDATE 1
ERROR:  new row for relation "tickets" violates check constraint "tickets_quantity_check"
DETAIL:  Failing row contains (2, 1, rui@example.com, 20, 2026-10-16 23:18:47.999183+00).
ROLLBACK
 sold 
------
    2
(1 row)
```

`BEGIN` opened the transaction and the `UPDATE` succeeded inside it. The `INSERT` failed, and from that
moment the transaction was broken: **`COMMIT` answered `ROLLBACK`**, PostgreSQL's way of saying it threw
the whole group away. The jazz event still shows the 2 seats sold before, not 4. Nothing of the failed
sale survived.

## In Go

`Sell` changes its signature, because a sale now records who bought, and returns the ticket's id with the
event. The interface, and the in-memory store that lesson 15 will test with, change first:

```go
// boxoffice/store.go
package main

import (
	"context"
	"errors"
	"slices"
	"sync"
)

var (
	ErrNotFound  = errors.New("no such event")
	ErrSoldOut   = errors.New("not enough seats left")
	ErrDuplicate = errors.New("an event with that name already exists")
)

// Event is one show the box office sells tickets for.
type Event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

// Store is what the handlers need from wherever the events are kept.
type Store interface {
	List(ctx context.Context) ([]Event, error)
	Get(ctx context.Context, id int) (Event, error)
	Add(ctx context.Context, name string, seats int) (Event, error)
	Sell(ctx context.Context, id, quantity int, email string) (Sale, error)
}

// Sale is what a purchase leaves behind: its ticket, and the event after it.
type Sale struct {
	TicketID int
	Event    Event
}

// memStore keeps the events in memory, for as long as the process runs.
type memStore struct {
	mu         sync.RWMutex
	events     map[int]Event
	nextID     int
	nextTicket int
}

func newMemStore() *memStore {
	return &memStore{nextID: 3, nextTicket: 1, events: map[int]Event{
		1: {ID: 1, Name: "Jazz at the Docks", Seats: 120, Sold: 0},
		2: {ID: 2, Name: "Chamber Choir", Seats: 80, Sold: 80},
	}}
}

func (s *memStore) List(ctx context.Context) ([]Event, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]Event, 0, len(s.events))
	for _, e := range s.events {
		out = append(out, e)
	}
	slices.SortFunc(out, func(a, b Event) int { return a.ID - b.ID })
	return out, nil
}

func (s *memStore) Get(ctx context.Context, id int) (Event, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	e, ok := s.events[id]
	if !ok {
		return Event{}, ErrNotFound
	}
	return e, nil
}

func (s *memStore) Add(ctx context.Context, name string, seats int) (Event, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, e := range s.events {
		if e.Name == name {
			return Event{}, ErrDuplicate
		}
	}
	e := Event{ID: s.nextID, Name: name, Seats: seats}
	s.events[e.ID] = e
	s.nextID++
	return e, nil
}

// Sell takes quantity seats of event id, or none at all.
func (s *memStore) Sell(ctx context.Context, id, quantity int, email string) (Sale, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	e, ok := s.events[id]
	if !ok {
		return Sale{}, ErrNotFound
	}
	if e.Seats-e.Sold < quantity {
		return Sale{}, ErrSoldOut
	}
	e.Sold += quantity
	s.events[id] = e
	sale := Sale{TicketID: s.nextTicket, Event: e}
	s.nextTicket++
	return sale, nil
}
```

Then `pgStore.Sell`, which does both writes in one transaction:

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
		if _, err := s.Get(ctx, id); err != nil {
			return Sale{}, err
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

Four lines carry the pattern, and every transaction in Go has them:

- **`tx, err := s.pool.Begin(ctx)`** takes one connection from the pool and sends `BEGIN` on it. Every
  statement of the transaction must go through `tx`, on that connection.
- **`defer tx.Rollback(ctx)`** runs whatever happens. After a successful `Commit` it does nothing; after
  any early `return` it throws the transaction away. Without it, a `return` in the middle would leave the
  connection inside an open transaction, holding its locks, and give it back to the pool that way.
- **`s.q().WithTx(tx)`** is lesson 8 section 05's `WithTx`: the same generated functions, sent through the
  transaction.
- **`tx.Commit(ctx)`** makes both writes permanent at once. It can fail too, and its error is returned.

The handler passes the e-mail along and puts the ticket's id in the receipt:

```go
// boxoffice/events.go
package main

import (
	"net/http"
	"strconv"
	"strings"
)

// eventView is what a client sees of an event.
type eventView struct {
	Event
	Available int `json:"available"`
}

func view(e Event) eventView {
	return eventView{Event: e, Available: e.Seats - e.Sold}
}

func listEvents(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		events, err := store.List(r.Context())
		if err != nil {
			fail(w, err)
			return
		}
		out := make([]eventView, 0, len(events))
		for _, e := range events {
			out = append(out, view(e))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

// pathID reads the {id} wildcard, and answers 400 itself when it is not a number.
func pathID(w http.ResponseWriter, r *http.Request) (int, bool) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		writeProblem(w, http.StatusBadRequest, "the event id must be a number", nil)
		return 0, false
	}
	return id, true
}

func getEvent(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		e, err := store.Get(r.Context(), id)
		if err != nil {
			fail(w, err)
			return
		}
		writeJSON(w, http.StatusOK, view(e))
	}
}

// purchase is the body of POST /events/{id}/tickets.
type purchase struct {
	Quantity int    `json:"quantity"`
	Email    string `json:"email"`
}

func (p purchase) validate() map[string]string {
	errs := map[string]string{}
	if p.Quantity < 1 || p.Quantity > 10 {
		errs["quantity"] = "must be between 1 and 10"
	}
	if p.Email == "" {
		errs["email"] = "is required"
	} else if !strings.Contains(p.Email, "@") {
		errs["email"] = "must be an e-mail address"
	}
	return errs
}

// receipt is what a successful purchase answers.
type receipt struct {
	TicketID  int    `json:"ticket_id"`
	EventID   int    `json:"event_id"`
	Quantity  int    `json:"quantity"`
	Email     string `json:"email"`
	Remaining int    `json:"remaining"`
}

func buyTickets(store Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		var p purchase
		if err := decodeJSON(w, r, &p); err != nil {
			writeProblem(w, http.StatusBadRequest, err.Error(), nil)
			return
		}
		if errs := p.validate(); len(errs) > 0 {
			writeProblem(w, http.StatusUnprocessableEntity, "the purchase is not valid", errs)
			return
		}
		sale, err := store.Sell(r.Context(), id, p.Quantity, p.Email)
		if err != nil {
			fail(w, err)
			return
		}
		writeJSON(w, http.StatusCreated, receipt{
			TicketID: sale.TicketID, EventID: id, Quantity: p.Quantity, Email: p.Email,
			Remaining: sale.Event.Seats - sale.Event.Sold,
		})
	}
}
```

```
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"ticket_id":1,"event_id":1,"quantity":2,"email":"ana@example.com","remaining":118}
ana@vm:~/boxoffice$ psql boxoffice -c "SELECT * FROM tickets"
 id | event_id |      email      | quantity |          created_at           
----+----------+-----------------+----------+-------------------------------
  1 |        1 | ana@example.com |        2 | 2026-10-16 23:18:47.862476+00
(1 row)
```

**Ticket 1, recorded in the same transaction that took the seats.** `created_at` came from the column's
default, `now()`, and is shown in UTC, the database server's time zone.

There is one line in that `Sell` that will cost boxoffice dearly under load, and nothing in this section
shows it. Section 07 finds it.
