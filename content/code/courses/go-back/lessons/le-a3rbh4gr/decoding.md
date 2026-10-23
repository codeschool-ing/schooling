---
title: Reading JSON, and refusing what is not
version: 1
---

Writing JSON is the easy direction, because the server controls the value. Reading it is the
other: **the body comes from a stranger, and it can be empty, broken, enormous, the wrong shape or
several things at once.** The obvious one-liner handles none of that well:

```go
json.NewDecoder(r.Body).Decode(&p)
```

It reads as much as the client sends, with no limit. It silently ignores fields it does not know,
so a client that misspells `quantity` as `quantiy` gets a purchase of zero tickets and no
complaint. It stops after the first value, so anything after it is never looked at. And the errors
it returns are written for Go programmers, not for whoever sent the request. boxoffice reads every
body through one function that closes each of those doors:

```go
// boxoffice/decode.go
package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
)

// maxBody is the most a request body may hold: 1 MiB.
const maxBody = 1 << 20

// decodeJSON reads exactly one JSON object from the body into dst, and
// refuses everything else with an error a client can act on.
func decodeJSON(w http.ResponseWriter, r *http.Request, dst any) error {
	r.Body = http.MaxBytesReader(w, r.Body, maxBody)
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		var syntaxErr *json.SyntaxError
		var typeErr *json.UnmarshalTypeError
		var tooBig *http.MaxBytesError
		switch {
		case errors.Is(err, io.EOF):
			return errors.New("the body is empty")
		case errors.Is(err, io.ErrUnexpectedEOF):
			return errors.New("the body ends in the middle of a JSON value")
		case errors.As(err, &syntaxErr):
			return fmt.Errorf("the body is not valid JSON (at byte %d)", syntaxErr.Offset)
		case errors.As(err, &typeErr):
			return fmt.Errorf("the field %q has the wrong type: want %s", typeErr.Field, typeErr.Type)
		case errors.As(err, &tooBig):
			return fmt.Errorf("the body is larger than %d bytes", tooBig.Limit)
		case strings.HasPrefix(err.Error(), "json: unknown field "):
			return fmt.Errorf("the body has an unknown field %s",
				strings.TrimPrefix(err.Error(), "json: unknown field "))
		default:
			return err
		}
	}
	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return errors.New("the body must hold one JSON object and nothing after it")
	}
	return nil
}
```

Four lines do the guarding before anything is decoded or after it:

- **`http.MaxBytesReader`** wraps the body so that reading past 1 MiB fails, and tells the server to
  close the connection rather than read the rest. A purchase is under a hundred bytes; a megabyte
  is generous and still bounded.
- **`DisallowUnknownFields`** turns a field the struct does not have into an error instead of
  something quietly dropped.
- **The second `Decode`** must find the end of the input. Anything else after the object, even
  another valid object, is refused.
- The **`switch`** turns each kind of failure into a sentence that names the problem in the client's
  terms. The unknown-field case reads the error's text because `encoding/json` reports that one as a
  plain message with no type of its own to match.

## Seven bodies, seven answers

Section 06 of this lesson adds the route these were sent to, `POST /events/{id}/tickets`, and section
05 the JSON shape of the errors; read the `detail` of each. `curl --json` sends its argument as the
body with `Content-Type: application/json`, and `-X POST` with no body sends nothing at all:

```
ana@vm:~/boxoffice$ curl -s -X POST localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body is empty"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2,}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body is not valid JSON (at byte 16)"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body ends in the middle of a JSON value"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the field \"quantity\" has the wrong type: want int"}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "seat": "A1"}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body has an unknown field \"seat\""}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2}{"quantity": 9}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body must hold one JSON object and nothing after it"}
ana@vm:~/boxoffice$ python3 -c 'print("{\"email\": \"" + "a" * 2000000 + "\"}")' | curl -s --json @- localhost:8080/events/1/tickets
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body is larger than 1048576 bytes"}
```

In order: **nothing, a trailing comma, a missing brace, a string where a number belongs, a field
that does not exist, two objects, and two million characters.** Each answer is a 400, because each
is a request the server cannot even read, and each says which of those it was. The byte offset
in the second points at the `}` after the comma. The last one was refused at the megabyte without
reading the rest, and the server's log, shown in section 07, has it taking 4.845 ms against
tens of microseconds for the others: reading a megabyte is the cost.

**None of these reached the store.** Every one of them failed before a single line of boxoffice's
own logic ran, which is exactly where a malformed request belongs.

## A word on `Content-Type`

boxoffice does not refuse a body because its `Content-Type` is not `application/json`. Some APIs do,
answering `415 Unsupported Media Type`, and it is a defensible rule: it stops an HTML form posted
from another site from being read as JSON. boxoffice's protection against that is lesson 2's: the
routes that change anything for staff need a bearer token, which a form cannot send.
