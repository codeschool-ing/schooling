---
title: Writing the response, in the right order
version: 1
---

An HTTP response goes out in a fixed order: **the status line, then the headers, then the body**.
Once the first byte of the body has left, the status and the headers have left with it, and
nothing can change them. `ResponseWriter` follows that order exactly, and its three methods are
the three parts:

| method | does |
|---|---|
| `w.Header()` | returns the header map, to be changed **before** anything is sent |
| `w.WriteHeader(code)` | sends the status line and the headers, once |
| `w.Write(bytes)` | sends body; if `WriteHeader` has not been called, calls it with 200 first |

**Most mistakes with a `ResponseWriter` are these three called in the wrong order**, and none of
them is a compile error. This program makes each one on purpose:

```go
// reply/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /created", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Location", "/events/7")
		w.WriteHeader(http.StatusCreated)
		fmt.Fprintln(w, "event 7 created")
	})
	mux.HandleFunc("GET /late", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "the body went first")
		w.Header().Set("X-Seats", "40")
		w.WriteHeader(http.StatusAccepted)
	})
	mux.HandleFunc("GET /sniffed", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "<h1>boxoffice</h1>")
	})
	mux.HandleFunc("GET /declared", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		fmt.Fprint(w, "<h1>boxoffice</h1>")
	})
	mux.HandleFunc("GET /missing", func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "no such seat", http.StatusNotFound)
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

## The right order, and the wrong one

```
ana@vm:~/reply$ curl -si localhost:8080/created
HTTP/1.1 201 Created
Location: /events/7
Date: Fri, 16 Oct 2026 22:11:56 GMT
Content-Length: 16
Content-Type: text/plain; charset=utf-8

event 7 created
ana@vm:~/reply$ curl -si localhost:8080/late
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:11:56 GMT
Content-Length: 20
Content-Type: text/plain; charset=utf-8

the body went first
```

`/created` set a header, chose a status, then wrote: the client got all three. `/late` wrote first,
and **the write sent a 200 on its own**, so the `X-Seats` header set afterwards went nowhere and the
`202` arrived too late to be a status. Neither mistake reached the client as an error. One of them
reached the server's own terminal:

```
ana@vm:~/reply$ go run .
2026/10/16 19:11:56 http: superfluous response.WriteHeader call from main.main.func2 (main.go:20)
```

**`superfluous response.WriteHeader call` is the line to look for** when a handler's status code
"does nothing". It names the function and the line, here the `WriteHeader(http.StatusAccepted)` on
line 20; `main.main.func2` is how Go names the second function literal inside `main`. The header
that went missing produced no line at all.

## The guessed type

```
ana@vm:~/reply$ curl -si localhost:8080/sniffed
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:11:56 GMT
Content-Length: 18
Content-Type: text/html; charset=utf-8

<h1>boxoffice</h1>ana@vm:~/reply$ curl -si localhost:8080/declared
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Date: Fri, 16 Oct 2026 22:11:56 GMT
Content-Length: 18

<h1>boxoffice</h1>ana@vm:~/reply$ curl -si localhost:8080/missing
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:11:57 GMT
Content-Length: 13

no such seat
```

(The prompt lands on the same line as the body because `Fprint`, unlike `Fprintln`, wrote no
newline, so `curl` left the cursor where the body ended.)

When a handler sets no `Content-Type`, **`net/http` reads the first 512 bytes of the body and
guesses**, with the function `http.DetectContentType`. It saw `<h1>` and said `text/html`, and a
browser would draw the heading. `/declared` sent the same bytes with the type set by hand, and a
browser would show the tags as text. **A server that answers JSON should say so itself**, and from
lesson 3 on every response this course writes does: a guess is right until the day a value happens
to start with something that looks like HTML.

`http.Error` is the package's shortcut for a failure. It sets `text/plain`, adds
`X-Content-Type-Options: nosniff` so that a browser does not second-guess that type, writes the
status and then the message with a newline. It does not return from your handler, so **the line
after `http.Error` is almost always `return`**, as it is in boxoffice in section 09.
