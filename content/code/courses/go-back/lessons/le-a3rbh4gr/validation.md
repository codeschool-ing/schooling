---
title: Decoded is not valid
version: 1
---

A body that decodes cleanly has the right shape. It can still ask for forty tickets, or zero, or
give `ana` as an e-mail address. **The decoder answers "is this the JSON I expected"; only the
handler can answer "does this make sense"**, because only the handler knows what a purchase is.
That second check is validation, and in boxoffice it is a method on the request type, beside the
handler that uses it:

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

func listEvents(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		events := store.List()
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

func getEvent(store *memStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		e, err := store.Get(id)
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
	EventID   int    `json:"event_id"`
	Quantity  int    `json:"quantity"`
	Email     string `json:"email"`
	Remaining int    `json:"remaining"`
}

func buyTickets(store *memStore) http.HandlerFunc {
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
		e, err := store.Sell(id, p.Quantity)
		if err != nil {
			fail(w, err)
			return
		}
		writeJSON(w, http.StatusCreated, receipt{
			EventID: id, Quantity: p.Quantity, Email: p.Email, Remaining: e.Seats - e.Sold,
		})
	}
}
```

`validate` looks at every field and **collects every problem before answering**, rather than
stopping at the first. A client that gets "quantity is wrong", fixes it, and then hears "and so is
the e-mail" has been made to send two requests to learn what one could have said. The map keys are
the JSON names, not the Go ones, because they are for the client.

`buyTickets` then runs the checks in the order of their cost: the id in the path, then the body's
shape, then its values, and only then the store. Each step that fails answers and returns, so **the
store never sees a request that failed an earlier step**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Four checks in a row: the id in the path, the body's JSON, the values, and the store's sale. Each check that fails leaves the row downwards with its own status: 400, 400, 422, and 404 or 409. Only a request that passes all four reaches 201 Created on the right.\"><defs><marker id=\"gb-l3-gates-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pathID</text><text x=\"75\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">id in the path</text><path d=\"M 75 90 L 75 133\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"30\" y=\"135\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">400</text><path d=\"M 135 65 L 153 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"155\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">decodeJSON</text><text x=\"215\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the JSON</text><path d=\"M 215 90 L 215 133\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"170\" y=\"135\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"215\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">400</text><path d=\"M 275 65 L 293 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"295\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">validate</text><text x=\"355\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the values</text><path d=\"M 355 90 L 355 133\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"310\" y=\"135\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">422</text><path d=\"M 415 65 L 433 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"435\" y=\"40\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"495\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">store.Sell</text><text x=\"495\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the seats</text><path d=\"M 495 90 L 495 133\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"450\" y=\"135\" width=\"90\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"495\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">404 / 409</text><path d=\"M 555 65 L 573 65\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l3-gates-ah)\"></path><rect x=\"575\" y=\"40\" width=\"110\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">201 Created</text><text x=\"630\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a receipt</text><text x=\"15\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cheapest check first</text><text x=\"15\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a failure answers and returns</text></svg>", "caption": "buyTickets checks from the cheapest to the dearest, and each failure answers on its own."}
```

```
ana@vm:~/boxoffice$ curl -s --json '{}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"the purchase is not valid","errors":{"email":"is required","quantity":"must be between 1 and 10"}}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"the purchase is not valid","errors":{"email":"must be an e-mail address","quantity":"must be between 1 and 10"}}
ana@vm:~/boxoffice$ curl -si --json '{"quantity": 0, "email": "ana@example.com"}' localhost:8080/events/1/tickets
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/problem+json
Vary: Origin
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 153

{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"the purchase is not valid","errors":{"quantity":"must be between 1 and 10"}}
```

`{}` decodes perfectly into a `purchase`: both fields simply keep their zero values, `0` and `""`.
**`encoding/json` cannot tell a missing field from one sent as zero**, so "must be between 1 and 10"
covers both cases here. When the difference matters, for a field where zero is a legitimate value
and absence is not, the field becomes a pointer, `*int`, which stays `nil` when the key is missing.

## 400 or 422

The decoding failures of section 03 were 400s and these are 422s. **400 Bad Request says the server
could not read the request; 422 Unprocessable Content says it read it and the values are wrong.**
(Go's `http.StatusText` still prints the older name, Unprocessable Entity.) Plenty of APIs answer 400
for both, and that is fine too: what matters is that a client can tell "fix your JSON" from "fix
your values", here by the status and the `errors` object together.

## What the e-mail check is not

`strings.Contains(p.Email, "@")` catches typing the name into the wrong box and nothing more. That
is deliberate. **The only real test of an e-mail address is sending a message to it**, and a stricter
pattern rejects real addresses sooner or later while letting typos through anyway. Validation at
the edge of an API is for mistakes a person makes in good faith; the rules of the business, like
whether there are seats left, belong to the store, which section 06 is about.

## Struct tags instead of methods

Many Go projects write the same rules as tags, `validate:"required,min=1,max=10"`, and let the
library `go-playground/validator` read them by reflection. Lesson 4 meets it, because Gin uses it.
The method above is more typing and has no magic in it: it is ordinary code that a test can call
and a reader can follow without knowing a tag language.
