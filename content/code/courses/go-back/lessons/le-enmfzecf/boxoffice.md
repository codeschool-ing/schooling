---
title: boxoffice, the service this course builds
version: 1
---

Every lesson from here to lesson 17 adds to one program: **boxoffice, the back end of a small venue
that sells tickets to its events.** It starts in memory and plain text, because that is what this
lesson has taught, and it ends as a single binary in a container, reading PostgreSQL, answering JSON
and gRPC, pushing seat counts to browsers and shutting down without dropping a sale. Each file is
shown whole every time it changes, so the project on your disk is always the one the lesson is
talking about.

It begins as four files in `~/boxoffice`, the directory section 02 created. **The store** holds the
events and knows nothing about HTTP:

```go
// boxoffice/store.go
package main

import (
	"slices"
	"sync"
)

// Event is one show the box office sells tickets for.
type Event struct {
	ID    int
	Name  string
	Seats int
	Sold  int
}

// memStore keeps the events in memory, for as long as the process runs.
type memStore struct {
	mu     sync.RWMutex
	events map[int]Event
}

func newMemStore() *memStore {
	return &memStore{events: map[int]Event{
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

func (s *memStore) Get(id int) (Event, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	e, ok := s.events[id]
	return e, ok
}
```

Two details are there on purpose. The map is guarded by a `sync.RWMutex` because, as section 04
showed, every request runs in its own goroutine; reads take the shared lock and can run together.
And `List` sorts, because **a Go map has no order and iterating one twice can give two orders**,
which an API listing events must never do.

**The handlers** turn requests into calls on the store. Each is a function that takes the store and
returns an `http.HandlerFunc`, a closure, so the store reaches the handler without a global
variable:

```go
// boxoffice/events.go
package main

import (
	"fmt"
	"net/http"
	"strconv"
)

func listEvents(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		for _, e := range store.List() {
			fmt.Fprintf(w, "%d\t%s\t%d of %d seats left\n", e.ID, e.Name, e.Seats-e.Sold, e.Seats)
		}
	}
}

func getEvent(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, err := strconv.Atoi(r.PathValue("id"))
		if err != nil {
			http.Error(w, "event id must be a number", http.StatusBadRequest)
			return
		}
		e, ok := store.Get(id)
		if !ok {
			http.Error(w, "no such event", http.StatusNotFound)
			return
		}
		fmt.Fprintf(w, "%s: %d of %d seats left\n", e.Name, e.Seats-e.Sold, e.Seats)
	}
}
```

`getEvent` reads the wildcard, and **it answers 400 when the id is not a number and 404 when it is
a number nobody has**, two different mistakes with two different statuses. Each `http.Error` is
followed by `return`, the habit section 07 asked for.

**The routes** are one function that builds the mux, so the whole of the API can be read in one
place:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store *memStore) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))
	return mux
}
```

**And `main`** builds the server with the four deadlines from section 08 and starts it:

```go
// boxoffice/main.go
package main

import (
	"log"
	"net/http"
	"time"
)

func main() {
	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           routes(newMemStore()),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

## Running it

```
ana@vm:~/boxoffice$ ls
events.go
go.mod
main.go
routes.go
store.go
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ go run .
2026/10/16 19:12:17 boxoffice listening on localhost:8080
```

`go vet` printed nothing, which is its way of finding nothing. **All four files are `package main`
in one directory, so `go run .` builds them as one program**; the order of the files does not
matter. From the second terminal:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events
1	Jazz at the Docks	120 of 120 seats left
2	Chamber Choir	0 of 80 seats left
ana@vm:~/boxoffice$ curl -s localhost:8080/events/2
Chamber Choir: 0 of 80 seats left
ana@vm:~/boxoffice$ curl -si localhost:8080/events/9
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:12:18 GMT
Content-Length: 14

no such event
ana@vm:~/boxoffice$ curl -si localhost:8080/events/nine
HTTP/1.1 400 Bad Request
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:12:18 GMT
Content-Length: 26

event id must be a number
ana@vm:~/boxoffice$ curl -si -X POST localhost:8080/events
HTTP/1.1 405 Method Not Allowed
Allow: GET, HEAD
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:12:18 GMT
Content-Length: 19

Method Not Allowed
```

Every answer is one the lesson predicted: the list in id order, one event by id, **404 for an id
that does not exist, 400 for one that is not an id**, and 405 with an `Allow` header for a method
nobody registered. The Chamber Choir is sold out from the start, which gives lesson 3 a sale to refuse.

What it cannot do yet is just as clear. It speaks tab-separated text that no program should have to
parse, nothing records who asked for what, and anybody can call anything. **Lesson 2 wraps these
handlers in middleware, and lesson 3 makes them speak JSON.**

