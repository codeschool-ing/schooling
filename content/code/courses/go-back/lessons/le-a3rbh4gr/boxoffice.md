---
title: boxoffice speaks JSON
version: 1
---

Sections 02 to 06 added four files, `json.go`, `decode.go`, `problem.go` and the new `store.go`
and `events.go`. This section changes the rest to match, adds the one route staff were missing, and
runs everything. **The staff routes get JSON too**, and a way to create an event:

```go
// boxoffice/admin.go
package main

import (
	"fmt"
	"net/http"
	"strings"
)

// newEvent is the body of POST /admin/events.
type newEvent struct {
	Name  string `json:"name"`
	Seats int    `json:"seats"`
}

func (n newEvent) validate() map[string]string {
	errs := map[string]string{}
	if strings.TrimSpace(n.Name) == "" {
		errs["name"] = "is required"
	} else if len(n.Name) > 100 {
		errs["name"] = "must be at most 100 bytes"
	}
	if n.Seats < 1 || n.Seats > 10000 {
		errs["seats"] = "must be between 1 and 10000"
	}
	return errs
}

// requireManager answers 403 itself unless the caller is a manager.
func requireManager(w http.ResponseWriter, r *http.Request) bool {
	if staffRole(r.Context()) != "manager" {
		writeProblem(w, http.StatusForbidden, "only a manager may do this", nil)
		return false
	}
	return true
}

func createEvent(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireManager(w, r) {
			return
		}
		var n newEvent
		if err := decodeJSON(w, r, &n); err != nil {
			writeProblem(w, http.StatusBadRequest, err.Error(), nil)
			return
		}
		if errs := n.validate(); len(errs) > 0 {
			writeProblem(w, http.StatusUnprocessableEntity, "the event is not valid", errs)
			return
		}
		e := store.Add(n.Name, n.Seats)
		w.Header().Set("Location", fmt.Sprintf("/events/%d", e.ID))
		writeJSON(w, http.StatusCreated, view(e))
	}
}

func salesReport(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !requireManager(w, r) {
			return
		}
		writeJSON(w, http.StatusOK, store.List())
	}
}
```

`requireManager` is lesson 2's role check pulled out into a helper, because two handlers now need it.
`createEvent` follows the same four steps as `buyTickets`, and answers **201 Created with a
`Location` header** saying where the new event can be read, which is what 201 promises a client.

The two middlewares that wrote text in lesson 2 now write problems. In `requireStaff` only the
refusal changed:

```go
// boxoffice/auth.go
package main

import (
	"context"
	"crypto/subtle"
	"net/http"
	"strings"
)

type roleKey struct{}

// requireStaff lets a request through only if it carries one of the tokens,
// and puts the role that token belongs to into the request's context.
func requireStaff(tokens map[string]string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			role := ""
			if got, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer "); ok {
				for token, owner := range tokens {
					if subtle.ConstantTimeCompare([]byte(got), []byte(token)) == 1 {
						role = owner
					}
				}
			}
			if role == "" {
				w.Header().Set("WWW-Authenticate", `Bearer realm="boxoffice"`)
				writeProblem(w, http.StatusUnauthorized, "a staff token is required", nil)
				return
			}
			ctx := context.WithValue(r.Context(), roleKey{}, role)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// staffRole is the role requireStaff found, or "" outside it.
func staffRole(ctx context.Context) string {
	role, _ := ctx.Value(roleKey{}).(string)
	return role
}
```

And in `recoverPanics`, the `http.Error` became a `writeProblem` with no detail, for the reason
section 05 gave:

```go
// boxoffice/recover.go
package main

import (
	"log"
	"net/http"
	"runtime/debug"
)

func recoverPanics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			v := recover()
			if v == nil {
				return
			}
			if v == http.ErrAbortHandler {
				panic(v)
			}
			log.Printf("panic serving %s %s: %v\n%s", r.Method, r.URL.Path, v, debug.Stack())
			writeProblem(w, http.StatusInternalServerError, "", nil)
		}()
		next.ServeHTTP(w, r)
	})
}
```

The routes gain the purchase and the new staff route:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store *memStore, tokens map[string]string) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))
	mux.HandleFunc("POST /events/{id}/tickets", buyTickets(store))

	admin := http.NewServeMux()
	admin.HandleFunc("GET /admin/report", salesReport(store))
	admin.HandleFunc("POST /admin/events", createEvent(store))
	mux.Handle("/admin/", requireStaff(tokens)(admin))

	return chain(mux, logRequests, recoverPanics, cors("https://tickets.example.com"))
}
```

`main.go` is lesson 2's, unchanged.

## Running it

```
ana@vm:~/boxoffice$ ls
admin.go
auth.go
cors.go
decode.go
events.go
go.mod
json.go
main.go
middleware.go
problem.go
recover.go
routes.go
store.go
ana@vm:~/boxoffice$ go vet ./...
```

Thirteen files, still one package. With the two tokens exported as in lesson 2:

```
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_DOOR_TOKEN" --json '{"name": "Organ Recital", "seats": 60}' localhost:8080/admin/events
{"type":"about:blank","title":"Forbidden","status":403,"detail":"only a manager may do this"}
ana@vm:~/boxoffice$ curl -si -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json '{"name": "Organ Recital", "seats": 60}' localhost:8080/admin/events
HTTP/1.1 201 Created
Content-Type: application/json
Location: /events/3
Vary: Origin
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 67

{"id":3,"name":"Organ Recital","seats":60,"sold":0,"available":60}
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json '{"name": "", "seats": 0}' localhost:8080/admin/events
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"the event is not valid","errors":{"name":"is required","seats":"must be between 1 and 10000"}}
ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" localhost:8080/admin/report
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":2},{"id":2,"name":"Chamber Choir","seats":80,"sold":80},{"id":3,"name":"Organ Recital","seats":60,"sold":0}]
```

The door token is refused with a problem, the manager's creates **event 3 with its `Location`**, an
empty event is refused with both fields named, and the report now lists the new event and the two
tickets section 06 sold. The server's log holds every request of this lesson in order:

```
ana@vm:~/boxoffice$ cat .server.log
2026/10/16 19:36:33 boxoffice listening on localhost:8080
2026/10/16 19:36:33 GET /events 200 142B 115µs
2026/10/16 19:36:33 GET /events/1 200 73B 41µs
2026/10/16 19:36:33 POST /events/1/tickets 400 87B 84µs
2026/10/16 19:36:33 POST /events/1/tickets 400 109B 87µs
2026/10/16 19:36:33 POST /events/1/tickets 400 113B 50µs
2026/10/16 19:36:33 POST /events/1/tickets 400 121B 91µs
2026/10/16 19:36:33 POST /events/1/tickets 400 108B 74µs
2026/10/16 19:36:33 POST /events/1/tickets 400 125B 50µs
2026/10/16 19:36:33 POST /events/1/tickets 400 107B 4.845ms
2026/10/16 19:36:33 POST /events/1/tickets 422 175B 36µs
2026/10/16 19:36:33 POST /events/1/tickets 422 189B 54µs
2026/10/16 19:36:33 POST /events/1/tickets 422 153B 62µs
2026/10/16 19:36:33 POST /events/1/tickets 201 70B 49µs
2026/10/16 19:36:33 POST /events/2/tickets 409 88B 49µs
2026/10/16 19:36:33 POST /events/9/tickets 404 81B 31µs
2026/10/16 19:36:33 POST /events/nine/tickets 400 99B 30µs
2026/10/16 19:36:33 GET /events/1 200 73B 25µs
2026/10/16 19:36:33 POST /admin/events 401 96B 21µs
2026/10/16 19:36:33 POST /admin/events 403 94B 29µs
2026/10/16 19:36:33 POST /admin/events 201 67B 80µs
2026/10/16 19:36:33 POST /admin/events 422 171B 71µs
2026/10/16 19:36:33 GET /admin/report 200 164B 84µs
2026/10/16 19:36:33 DELETE /events 405 19B 32µs
```

**Every status in this lesson is in that log, and only the 405 was not written by boxoffice.** What
none of it survives is a restart: stop the server and the Organ Recital and the two tickets are
gone, because the store is a map in memory. Lesson 6 puts it in PostgreSQL. Before that, lessons 4
and 5 stop to ask whether this much hand-written code was the right way to get here.
