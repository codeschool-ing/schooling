---
title: Errors from the store, and the status each deserves
version: 1
---

The store is where boxoffice's rules live: an event exists or it does not, and a sale either fits
in the seats that are left or it does not happen. **Those refusals are not HTTP errors, and the store
must not speak HTTP.** It will be backed by PostgreSQL in lesson 6 and called by gRPC in lesson 10,
and neither of those has a 404. So the store says what went wrong in its own words, as errors, and
one function at the edge translates.

```go
// boxoffice/store.go
package main

import (
	"errors"
	"slices"
	"sync"
)

var (
	ErrNotFound = errors.New("no such event")
	ErrSoldOut  = errors.New("not enough seats left")
)

// Event is one show the box office sells tickets for.
type Event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

// memStore keeps the events in memory, for as long as the process runs.
type memStore struct {
	mu     sync.RWMutex
	events map[int]Event
	nextID int
}

func newMemStore() *memStore {
	return &memStore{nextID: 3, events: map[int]Event{
		1: {ID: 1, Name: "Jazz at the Docks", Seats: 120, Sold: 0},
		2: {ID: 2, Name: "Chamber Choir", Seats: 80, Sold: 80},
	}}
}

func (s *memStore) List() []Event {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]Event, 0, len(s.events))
	for _, e := range s.events {
		out = append(out, e)
	}
	slices.SortFunc(out, func(a, b Event) int { return a.ID - b.ID })
	return out
}

func (s *memStore) Get(id int) (Event, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	e, ok := s.events[id]
	if !ok {
		return Event{}, ErrNotFound
	}
	return e, nil
}

func (s *memStore) Add(name string, seats int) Event {
	s.mu.Lock()
	defer s.mu.Unlock()
	e := Event{ID: s.nextID, Name: name, Seats: seats}
	s.events[e.ID] = e
	s.nextID++
	return e
}

// Sell takes quantity seats of event id, or none at all.
func (s *memStore) Sell(id, quantity int) (Event, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	e, ok := s.events[id]
	if !ok {
		return Event{}, ErrNotFound
	}
	if e.Seats-e.Sold < quantity {
		return e, ErrSoldOut
	}
	e.Sold += quantity
	s.events[id] = e
	return e, nil
}
```

The two errors at the top are **sentinel errors**, values declared once and compared by identity,
the pattern `go` lesson 35 introduced. `Get` now returns `ErrNotFound` instead of the boolean of
lesson 1, and `Sell` returns `ErrSoldOut` when fewer seats are left than were asked for.

`Sell` does its check and its change **under one lock, from the read to the write**. If it read the
event, released the lock, and then wrote, two buyers of the last seat could both read "one left",
both pass the check, and both be sold it. Holding the write lock across the whole function makes the
sale all or nothing. Lesson 9 meets the same race in PostgreSQL, where a mutex in one process is no
longer enough.

## One place that translates

`fail`, in `problem.go` from section 05, is the translation:

```go
func fail(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		writeProblem(w, http.StatusNotFound, err.Error(), nil)
	case errors.Is(err, ErrSoldOut):
		writeProblem(w, http.StatusConflict, err.Error(), nil)
	default:
		log.Printf("unexpected error: %v", err)
		writeProblem(w, http.StatusInternalServerError, "", nil)
	}
}
```

**`errors.Is` and not `==`**, because from lesson 6 on the store will wrap its errors with context,
`fmt.Errorf("event %d: %w", id, ErrNotFound)`, and `errors.Is` sees through the wrapping where `==`
would not; that is `go` lesson 34. **409 Conflict for a sale that does not fit**: the request was
well formed and valid, and it conflicts with the current state of the event. The same request might
succeed tomorrow if a refund frees seats, which is the difference from a 422. And the `default` case
is the one that catches every error nobody planned for: logged in full, answered with a bare 500.

```
ana@vm:~/boxoffice$ curl -si --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
HTTP/1.1 201 Created
Content-Type: application/json
Vary: Origin
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 70

{"event_id":1,"quantity":2,"email":"ana@example.com","remaining":118}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/2/tickets
{"type":"about:blank","title":"Conflict","status":409,"detail":"not enough seats left"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/9/tickets
{"type":"about:blank","title":"Not Found","status":404,"detail":"no such event"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/nine/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the event id must be a number"}
ana@vm:~/boxoffice$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2,"available":118}
```

The first purchase went through, **201 Created with a receipt**, and the event now shows 2 sold and
118 available. The Chamber Choir refused with 409, an event that does not exist with 404, and an id
that is not a number with 400 before the store was asked anything. Four outcomes of the same route,
each with its own status, and every handler that calls the store from now on gets them by calling
`fail`.
