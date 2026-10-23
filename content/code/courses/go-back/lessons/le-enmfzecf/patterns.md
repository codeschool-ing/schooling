---
title: Methods and wildcards in the pattern
version: 1
---

Until Go 1.22, released in February 2024, a `ServeMux` pattern was a path and nothing more. It
could not say `GET` and it could not say "any id here", so a handler for `/events/` received every
method and every path below it and had to sort them out itself, with an `if` on `r.Method` and a
`strings.Split` of the path. **That gap is most of the reason Go routers outside the standard
library exist**, and lesson 4 comes back to it. Since 1.22 a pattern carries three more things:

| written | means |
|---|---|
| `GET /events` | the method, a space, then the path |
| `/events/{id}` | a **wildcard**: one whole path segment, any text, read back with `r.PathValue("id")` |
| `/files/{path...}` | a wildcard that takes **the rest of the path**, slashes included; only allowed last |
| `/{$}` | a path that ends exactly here, trailing slash and all |

Here they are in one program:

```go
// routes/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "the home page, and nothing below it")
	})
	mux.HandleFunc("GET /events", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "every event")
	})
	mux.HandleFunc("POST /events", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "a new event")
	})
	mux.HandleFunc("GET /events/{id}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "event %q\n", r.PathValue("id"))
	})
	mux.HandleFunc("GET /events/latest", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "the latest event")
	})
	mux.HandleFunc("GET /files/{path...}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "file %q\n", r.PathValue("path"))
	})
	mux.HandleFunc("/static/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "under /static/: %s\n", r.URL.Path)
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

## The method

```
ana@vm:~/routes$ curl -s localhost:8080/events
every event
ana@vm:~/routes$ curl -s -X POST localhost:8080/events
a new event
ana@vm:~/routes$ curl -si -X DELETE localhost:8080/events
HTTP/1.1 405 Method Not Allowed
Allow: GET, HEAD, POST
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:11:52 GMT
Content-Length: 19

Method Not Allowed
```

One path, two handlers, chosen by the method. **The third request is the part the old mux could
never do on its own**: the path exists, the method does not, and the answer is `405` with an
`Allow` header listing what would have worked. Nobody wrote that list. The mux built it from the
patterns registered for `/events`, and put `HEAD` in it as well, because **a `GET` pattern also
answers `HEAD`**:

```
ana@vm:~/routes$ curl -sI localhost:8080/events
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:11:52 GMT
Content-Length: 12
Content-Type: text/plain; charset=utf-8

```

`curl -I` sends `HEAD`. The handler ran and wrote its twelve bytes, and the server counted them
for `Content-Length` and sent none of them, which is what `HEAD` means.

## The wildcards

```
ana@vm:~/routes$ curl -s localhost:8080/events/42
event "42"
ana@vm:~/routes$ curl -s localhost:8080/files/posters/2026/jazz.png
file "posters/2026/jazz.png"
ana@vm:~/routes$ curl -s localhost:8080/events/42/tickets
404 page not found
```

`{id}` took `42`, and **it is a string**: the mux knows nothing about numbers, and turning it into
one is the handler's job, with its own answer when it fails, which boxoffice does in section 09.
`{path...}` took three segments with their slashes. The last request is a 404 because `{id}`
matches one segment and `42/tickets` is two; no pattern here covers it.

## The ends of a path

```
ana@vm:~/routes$ curl -s localhost:8080/
the home page, and nothing below it
ana@vm:~/routes$ curl -si localhost:8080/about
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:11:52 GMT
Content-Length: 19

404 page not found
```

**`{$}` is what stops `/` from swallowing the site.** A pattern ending in a slash still means
"this and everything below it", as it did in section 03, so `GET /` alone would have answered
`/about` with the home page. With `{$}` it answers `/` and nothing else, and `/about` is an honest
404.

The old meaning is still there for when you want it, and `/static/` uses it:

```
ana@vm:~/routes$ curl -s localhost:8080/static/css/site.css
under /static/: /static/css/site.css
ana@vm:~/routes$ curl -si localhost:8080/static
HTTP/1.1 307 Temporary Redirect
Content-Type: text/html; charset=utf-8
Location: /static/
Date: Fri, 16 Oct 2026 22:11:52 GMT
Content-Length: 44

<a href="/static/">Temporary Redirect</a>.

```

A request for `/static`, without the slash, is not under `/static/`, and **the mux redirects it to
the slash form** rather than answering 404. That is helpful for a directory of files and surprising
for an API, where a client that does not follow redirects sees a 307 it did not expect. The
`/static/` pattern also has no method, so it answers `DELETE` as readily as `GET`: a pattern with
no method matches every method, exactly as before 1.22.

## A pattern can name a host

One more part exists and this course uses it nowhere: a pattern may start with a host name,
`api.example.com/events`, and then it matches only requests sent to that name. It is how one
process serves two sites. **A pattern with a host is more specific than one without**, which is the
first of the rules the next section is about.
