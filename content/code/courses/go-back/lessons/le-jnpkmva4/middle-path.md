---
title: The middle path: libraries, not a framework
version: 1
---

Between writing everything and adopting a framework there is a third way, and it is the one this
course recommends for the needs section 02 left open. **A library does one thing and leaves the shape
of your program alone; a framework decides the shape and lets you fill it in.** The test is the
handler's signature: if it stays `func(w http.ResponseWriter, r *http.Request)`, everything else in
this course keeps working.

## A router that stays a router

`chi` is the clearest example. It is a router and a set of middlewares, nothing else, and its routes
take ordinary `http.HandlerFunc`s. Here is the yardstick API of lesson 4 with `chi` in place of
`ServeMux`:

```go
// fw/chi/main.go
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

type event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

type purchase struct {
	Quantity int    `json:"quantity"`
	Email    string `json:"email"`
}

var (
	mu     sync.Mutex
	events = map[int]*event{1: {ID: 1, Name: "Jazz at the Docks", Seats: 120}}
)

func send(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func fail(w http.ResponseWriter, status int, msg string) {
	send(w, status, map[string]string{"error": msg})
}

func main() {
	router := chi.NewRouter()
	router.Use(middleware.Logger)
	router.Get("/events/{id}", func(w http.ResponseWriter, r *http.Request) {
		id, err := strconv.Atoi(chi.URLParam(r, "id"))
		if err != nil {
			fail(w, http.StatusBadRequest, "the event id must be a number")
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			fail(w, http.StatusNotFound, "no such event")
			return
		}
		send(w, http.StatusOK, e)
	})
	router.Post("/events/{id}/tickets", func(w http.ResponseWriter, r *http.Request) {
		id, _ := strconv.Atoi(chi.URLParam(r, "id"))
		var p purchase
		if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
			fail(w, http.StatusBadRequest, err.Error())
			return
		}
		if p.Quantity < 1 || p.Quantity > 10 {
			fail(w, http.StatusUnprocessableEntity, "quantity must be between 1 and 10")
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			fail(w, http.StatusNotFound, "no such event")
			return
		}
		if e.Seats-e.Sold < p.Quantity {
			fail(w, http.StatusConflict, "not enough seats left")
			return
		}
		e.Sold += p.Quantity
		send(w, http.StatusCreated, map[string]int{"event_id": id, "remaining": e.Seats - e.Sold})
	})
	log.Fatal(http.ListenAndServe("localhost:8080", router))
}
```

Only the routing lines changed: `chi.NewRouter()`, `router.Get` and `router.Post`, and
`chi.URLParam(r, "id")` where the standard library says `r.PathValue("id")`. The handlers are the
standard library's, word for word, and so are the helpers.

```
ana@vm:~/fw/chi$ go mod tidy
go: finding module for package github.com/go-chi/chi/v5
go: finding module for package github.com/go-chi/chi/v5/middleware
go: downloading github.com/go-chi/chi/v5 v5.5.0
go: downloading github.com/go-chi/chi v1.5.5
go: found github.com/go-chi/chi/v5 in github.com/go-chi/chi/v5 v5.5.0
go: found github.com/go-chi/chi/v5/middleware in github.com/go-chi/chi/v5 v5.5.0
ana@vm:~/fw/chi$ go build -o server . && ls -l server && go list -m all
-rwxr-xr-x 1 ana ana 11216898 Oct 16 19:48 server
example.com/fw/chi
github.com/go-chi/chi/v5 v5.5.0
ana@vm:~/fw/chi$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}
ana@vm:~/fw/chi$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"error":"quantity must be between 1 and 10"}
ana@vm:~/fw/chi$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 405 Method Not Allowed
Allow: GET
Date: Fri, 16 Oct 2026 22:48:53 GMT
Content-Length: 0

ana@vm:~/fw/chi$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:48:53 GMT
Content-Length: 19

404 page not found
ana@vm:~/fw/chi$ cat .server.log
2026/10/16 19:48:53 "GET http://localhost:8080/events/1 HTTP/1.1" from 127.0.0.1:54580 - 200 57B in 106.817µs
2026/10/16 19:48:53 "POST http://localhost:8080/events/1/tickets HTTP/1.1" from 127.0.0.1:54594 - 422 46B in 145.349µs
2026/10/16 19:48:53 "DELETE http://localhost:8080/events/1 HTTP/1.1" from 127.0.0.1:54604 - 405 0B in 5.274µs
2026/10/16 19:48:53 "GET http://localhost:8080/nothing HTTP/1.1" from 127.0.0.1:54608 - 404 19B in 11.089µs
```

**One module besides your own**, `chi` itself, and a binary of 11.2 MB against the standard library's
9.8. The answers match the standard version's except in two details: chi's 405 lists only `GET`, not
the `HEAD` that `ServeMux` adds, and sends no body. The log line came from `middleware.Logger`, one of
the middlewares `chi` ships, which has the standard shape and would wrap a `ServeMux` just as well.

## When the router is worth adding

With Go 1.22's patterns, a router like `chi` earns its module when you need what `ServeMux` still does
not do: patterns with regular expressions in them, like `{id:[0-9]+}`, or groups of routes mounted with
their own middleware in a few lines. **If none of that is needed, `ServeMux` is the
router**, and boxoffice keeps it.

## The same idea for everything else

The same reasoning applies to each gap in section 02's list. Validation: `go-playground/validator` on
its own, called from a handler, or methods as boxoffice does. Rate limiting: `golang.org/x/time/rate`, a
small package from the Go team, inside a middleware of the standard shape. Request ids, compression,
timeouts: middlewares in the standard shape, from a library or written in thirty lines. **Each piece is
replaceable on its own, and none of them owns your handlers.**
