---
title: Why Go has routers and frameworks at all
version: 1
---

Lesson 1 built boxoffice on `net/http` alone, and lessons 2 and 3 added what it lacked by hand: a
chain of middlewares, a JSON writer, a decoder that refuses bad bodies, one shape for errors.
**Most Go web services in production were not written that way.** They use a router or a framework
from outside the standard library, and for a long time there was a good reason to.

## What was missing before 1.22

Until February 2024, `ServeMux` could not route by method and had no wildcards, as lesson 1
section 05 said. A route like `GET /events/{id}` had to be one handler for the subtree `/events/`,
with an `if r.Method != "GET"` at the top and a `strings.TrimPrefix` to dig the id out of the path.
Three projects filled that gap and shaped everything since:

| project | since | what it brought |
|---|---|---|
| `julienschmidt/httprouter` | 2013 | methods and `:id` parameters, matched in a tree, very fast; Gin's router began as a copy of it |
| `gorilla/mux` | 2012 | methods, `{id}` variables, regular expressions, host matching; archived in 2022, taken over by new maintainers in 2023 |
| `go-chi/chi` | 2016 | a router whose handlers stay `http.Handler`, with middleware in the standard shape |

**A framework goes further than a router.** Besides routing it brings its own request type that
carries the response too, functions that decode a body straight into a struct and validate it from
tags, a central place where errors become responses, and a catalogue of ready middleware. This
lesson builds the same small API four times, in Gin, Echo, Fiber and Beego, and lesson 5 judges what
that bought.

## The yardstick

To compare, there has to be a baseline. Here is the API every version implements, in the standard
library and nothing else, in the plain style lesson 1 started with rather than boxoffice's:

```go
// fw/std/main.go
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"
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
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events/{id}", func(w http.ResponseWriter, r *http.Request) {
		id, err := strconv.Atoi(r.PathValue("id"))
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
	mux.HandleFunc("POST /events/{id}/tickets", func(w http.ResponseWriter, r *http.Request) {
		id, _ := strconv.Atoi(r.PathValue("id"))
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
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

Two routes, a mutex around a map, a quantity check, and four statuses. Each framework version below
keeps the same store, the same check and the same statuses, so that what differs is the framework.
Every version was then built and asked the same six questions:

```
ana@vm:~/fw/std$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 9807673 Oct 16 19:42 server
```

```
ana@vm:~/fw/std$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Type: application/json
Date: Fri, 16 Oct 2026 22:42:48 GMT
Content-Length: 57

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}
ana@vm:~/fw/std$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}
ana@vm:~/fw/std$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"error":"quantity must be between 1 and 10"}
ana@vm:~/fw/std$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"error":"json: cannot unmarshal string into Go struct field purchase.quantity of type int"}
ana@vm:~/fw/std$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 405 Method Not Allowed
Allow: GET, HEAD
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:42:48 GMT
Content-Length: 19

Method Not Allowed
ana@vm:~/fw/std$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:42:48 GMT
Content-Length: 19

404 page not found
```

One event, a purchase, an invalid quantity, a string where a number belongs, the wrong method and a
path that does not exist. **Hold on to the last two answers**: the 405 with its `Allow` header and the plain
404 are the standard library's, and the four frameworks each answer them differently.
