---
title: A handler, a request and a recorder
version: 1
---

The closest distance calls a handler as a function. `httptest.NewRequest` builds a request without any
network, `httptest.NewRecorder` is a `ResponseWriter` that keeps what the handler wrote, and the handler
is called with the two. boxoffice's handlers are made by functions that take the store, so the test hands
each one a fresh `newMemStore()`, with lesson 1's two events in it:

```go
// boxoffice/events_test.go
package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestGetEvent(t *testing.T) {
	tests := []struct {
		name   string
		id     string
		status int
	}{
		{"an event that exists", "1", http.StatusOK},
		{"an event that does not", "9", http.StatusNotFound},
		{"an id that is not a number", "one", http.StatusBadRequest},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/events/"+tt.id, nil)
			req.SetPathValue("id", tt.id) // no mux here to fill it in
			rec := httptest.NewRecorder()

			getEvent(newMemStore())(rec, req)

			if rec.Code != tt.status {
				t.Fatalf("status %d, want %d; body %s", rec.Code, tt.status, rec.Body)
			}
		})
	}
}

func TestBuyTickets(t *testing.T) {
	tests := []struct {
		name   string
		id     string
		body   string
		status int
		want   string // a piece of the body that must be there
	}{
		{"a good purchase", "1", `{"quantity": 2, "email": "ana@example.com"}`, http.StatusCreated, `"remaining":118`},
		{"too many at once", "1", `{"quantity": 11, "email": "ana@example.com"}`, http.StatusUnprocessableEntity, `"quantity":"must be between 1 and 10"`},
		{"a sold-out event", "2", `{"quantity": 1, "email": "ana@example.com"}`, http.StatusConflict, `not enough seats left`},
		{"a field nobody declared", "1", `{"quantity": 1, "email": "ana@example.com", "price": 0}`, http.StatusBadRequest, `unknown field \"price\"`},
		{"an event that does not exist", "9", `{"quantity": 1, "email": "ana@example.com"}`, http.StatusNotFound, `no such event`},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest("POST", "/events/"+tt.id+"/tickets", strings.NewReader(tt.body))
			req.SetPathValue("id", tt.id)
			rec := httptest.NewRecorder()

			buyTickets(newMemStore())(rec, req)

			if rec.Code != tt.status {
				t.Fatalf("status %d, want %d; body %s", rec.Code, tt.status, rec.Body)
			}
			if !strings.Contains(rec.Body.String(), tt.want) {
				t.Errorf("body %s does not contain %s", rec.Body, tt.want)
			}
			if rec.Code >= 400 {
				var p problem
				if err := json.Unmarshal(rec.Body.Bytes(), &p); err != nil || p.Status != rec.Code {
					t.Errorf("not a problem document for %d: %s", rec.Code, rec.Body)
				}
				if ct := rec.Header().Get("Content-Type"); ct != "application/problem+json" {
					t.Errorf("Content-Type %q", ct)
				}
			}
		})
	}
}
```

Three details carry most of the weight.

- **`SetPathValue` stands in for the mux.** `getEvent` reads `r.PathValue("id")`, and the value is put
  there by the `ServeMux` when it matches the pattern `/events/{id}`. Calling the handler directly skips
  the mux, so the test sets the value by hand; forget it, and `PathValue` returns
  an empty string, which `pathID` refuses: every case would answer 400.
- **Every case gets its own store.** The purchase of two seats changes the store, and a store shared
  between cases would make the result of one depend on the order they run in.
- **An error is checked as a problem document**, not only by its status. Lesson 3 promised that every
  error answers `application/problem+json` with a `status` matching the response's; the table checks that
  promise once for every failing case, so a handler that answered `http.Error`'s plain text would fail
  here.

Each case is a line in a table, named in words, and `t.Run` turns each into a subtest of its own:

```
ana@vm:~/boxoffice$ go vet ./... && go test -run "TestGetEvent|TestBuyTickets" -v .
=== RUN   TestGetEvent
=== RUN   TestGetEvent/an_event_that_exists
=== RUN   TestGetEvent/an_event_that_does_not
=== RUN   TestGetEvent/an_id_that_is_not_a_number
--- PASS: TestGetEvent (0.00s)
    --- PASS: TestGetEvent/an_event_that_exists (0.00s)
    --- PASS: TestGetEvent/an_event_that_does_not (0.00s)
    --- PASS: TestGetEvent/an_id_that_is_not_a_number (0.00s)
=== RUN   TestBuyTickets
=== RUN   TestBuyTickets/a_good_purchase
=== RUN   TestBuyTickets/too_many_at_once
=== RUN   TestBuyTickets/a_sold-out_event
=== RUN   TestBuyTickets/a_field_nobody_declared
=== RUN   TestBuyTickets/an_event_that_does_not_exist
--- PASS: TestBuyTickets (0.00s)
    --- PASS: TestBuyTickets/a_good_purchase (0.00s)
    --- PASS: TestBuyTickets/too_many_at_once (0.00s)
    --- PASS: TestBuyTickets/a_sold-out_event (0.00s)
    --- PASS: TestBuyTickets/a_field_nobody_declared (0.00s)
    --- PASS: TestBuyTickets/an_event_that_does_not_exist (0.00s)
PASS
ok  	example.com/boxoffice	(cached)
```

`go vet` ran first and said nothing, which is what it should say. The names in the output are the names
in the table with the spaces made underscores, and **a single case can be run alone** with
`-run 'TestBuyTickets/a_sold-out_event'`. When one fails, `t.Fatalf` prints the status and the body, so the
failure says what came back instead of only that it was wrong.
