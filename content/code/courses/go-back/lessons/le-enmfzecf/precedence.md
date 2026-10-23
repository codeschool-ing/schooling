---
title: Which pattern wins
version: 1
---

In the last program, `/events/latest` matched two patterns, `GET /events/{id}` and
`GET /events/latest`, and the second one answered. **The order they were registered in had nothing
to do with it.** Many routers try their routes top to bottom and stop at the first match, so moving
a line changes what a request reaches. `ServeMux` does not, and the rule it uses instead is short.

> **The most specific pattern wins.** One pattern is more specific than another when it matches a
> strict subset of the requests the other matches.

`GET /events/latest` matches one path. `GET /events/{id}` matches that path and every other single
segment after `/events/`. The first matches less, so it is more specific, so it wins, wherever it
sits in the file. The same reasoning ranks the rest:

| these two | the winner | because |
|---|---|---|
| `GET /events/latest` against `GET /events/{id}` | `/events/latest` | a literal segment matches less than a wildcard |
| `GET /events/{id}` against `/events/` | `GET /events/{id}` | it names a method, and it matches one segment rather than a whole subtree |
| `api.example.com/events` against `/events` | the one with the host | it only matches requests sent to that name |

## Two patterns that overlap and neither wins

Sometimes neither of two patterns matches a subset of the other. Each matches some paths the other
does not, and both match some paths in common:

```go
// conflict/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events/{id}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "one event")
	})
	mux.HandleFunc("GET /{kind}/42", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "anything numbered 42")
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

Which should `/events/42` reach? There is no answer that is not arbitrary, and **`ServeMux` refuses
to pick one. It panics when the second pattern is registered**, before the server has opened its
port:

```
ana@vm:~/conflict$ go run .
panic: pattern "GET /{kind}/42" (registered at /home/ana/conflict/main.go:15) conflicts with pattern "GET /events/{id}" (registered at /home/ana/conflict/main.go:12):
	GET /{kind}/42 and GET /events/{id} both match some paths, like "/events/42".
	But neither is more specific than the other.
	GET /{kind}/42 matches "/kind/42", but GET /events/{id} doesn't.
	GET /events/{id} matches "/events/id", but GET /{kind}/42 doesn't.

goroutine 1 [running]:
net/http.(*ServeMux).register(...)
	/usr/local/go/src/net/http/server.go:2957
net/http.(*ServeMux).HandleFunc(0x0?, {0x695b14?, 0x401320?}, 0xfb4ac95e0d8?)
	/usr/local/go/src/net/http/server.go:2931 +0x5e
main.main()
	/home/ana/conflict/main.go:15 +0x59
exit status 2
```

**Read the first five lines and stop.** They name both patterns with the file and line that
registered each, give a path both match, and then prove that neither is more specific, with one
path for each side that only it matches. The stack below them is the panic's usual trace, and here
it adds nothing the message did not already say.

A panic sounds alarming for a routing mistake, and it is the kind choice. **The program fails the
first time it runs, on your machine, with both lines named.** The alternative is a router that
quietly sends `/events/42` to whichever handler it prefers, and a bug report weeks later from
someone who was shown the wrong page. The repair is to make one pattern more specific, or to
rename a path so the two stop overlapping.

## When old code behaves differently

A module whose `go.mod` says `go 1.21` or earlier gets the old mux, where a method or a `{` in a
pattern is just part of a literal path. The same code compiled against a `go 1.22` line or later
gets the new one. The old behaviour can also be forced with the setting `GODEBUG=httpmuxgo121=1`,
meant for programs that registered paths with braces in them and need time to change. **If a
pattern with a method answers 404 to everything, look at the `go` line in `go.mod` first.**
