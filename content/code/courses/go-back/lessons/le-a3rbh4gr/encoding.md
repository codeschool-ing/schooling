---
title: Writing JSON
version: 1
---

Lesson 1 made boxoffice answer in tab-separated text, and every client would have had to split
lines and count tabs to read it. **JSON is what an HTTP API speaks by default now**: every language
has a parser for it, a browser reads it natively, and a person can still read it in a terminal.
`go-concurrency` lesson 19 covered `encoding/json` itself, the tags and `omitempty`; this lesson is
about the two places it meets HTTP, the response and the request, and what can go wrong at each.

## The struct is the contract

The `Event` type gains a tag on each field, in section 06's version of the store:

```go
type Event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}
```

**The tags decide the names a client sees**, so the Go names can change without breaking anybody.
Without them the JSON keys would be `ID` and `Name`, the Go spelling, which is legal and unusual
enough that clients in other languages trip over it. And a client never sees an event without a
number nobody stored: how many seats are left is `Seats - Sold`, worked out when the answer is
built, so the handlers send an `eventView` that embeds `Event` and adds `available`. **An embedded
struct's fields appear in the JSON as if they were the outer struct's own**, which is why the
answer below is one flat object.

## Encode first, then send

```go
// boxoffice/json.go
package main

import (
	"encoding/json"
	"log"
	"net/http"
)

// writeJSON sends v as JSON with the status given. The value is encoded
// before anything is sent, so a value that cannot be encoded becomes a 500
// rather than half a response.
func writeJSON(w http.ResponseWriter, status int, v any) {
	body, err := json.Marshal(v)
	if err != nil {
		log.Printf("encoding %T: %v", v, err)
		http.Error(w, "internal server error", http.StatusInternalServerError)
		return
	}
	if w.Header().Get("Content-Type") == "" {
		w.Header().Set("Content-Type", "application/json")
	}
	w.WriteHeader(status)
	w.Write(append(body, '\n'))
}
```

The function makes one decision that matters. **It turns the value into bytes before it sends
anything.** `json.Marshal` can fail, on a channel, a function or a cyclic pointer in the value, and
if it failed halfway through writing to `w` the status would already be 200 and half a body would
be on the wire. Encoding into memory first means a failure can still become an honest 500, with
the reason in the log and not in the response.

It also sets `Content-Type` itself, because lesson 1 section 07 showed what `net/http` guesses for
a body that starts with `[` or `{`: plain text. A caller that set a more precise type before calling
it keeps it, which section 05 needs. The newline at the end is for people: `curl` leaves the prompt
on the line of the last byte otherwise.

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events
[{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120},{"id":2,"name":"Chamber Choir","seats":80,"sold":80,"available":0}]
ana@vm:~/boxoffice$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Type: application/json
Vary: Origin
Date: Fri, 16 Oct 2026 22:36:33 GMT
Content-Length: 73

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120}
```

**`available` sits beside the stored fields, and `sold` is honest about the Chamber Choir**: 80 of
80. The list came back as a JSON array in id order, because `List` sorts.

## When streaming is the better choice

`json.NewEncoder(w).Encode(v)` writes straight to the response without building the bytes first,
and for a list of a hundred thousand rows that saves holding all of them in memory at once. The
price is the one `writeJSON` avoids: an error in the middle arrives after the 200. **For the small
answers of an API, encode first; for exports measured in megabytes, stream, and accept that a
failure shows up as a truncated body** that the client has to detect.
