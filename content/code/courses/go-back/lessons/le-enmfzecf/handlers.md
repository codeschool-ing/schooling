---
title: A handler is anything with ServeHTTP
version: 1
---

The function in the last section looked like the whole idea, and it is half of it. **What
`net/http` actually routes to is an interface with one method**:

```go
type Handler interface {
	ServeHTTP(ResponseWriter, *Request)
}
```

Any type with that method is a handler, by the rule `go` lesson 27 taught for every interface:
nothing is declared, the method set is enough. A function is not a type with methods, so the
package carries an adapter, `http.HandlerFunc`, which is a function type whose `ServeHTTP` calls
the function itself. **`HandleFunc` is `Handle` with that conversion done for you.** The program
below uses all three spellings:

```schooling-example
{
  "language": "go",
  "file": "counter/main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"log\"\n\t\"net/http\"\n\t\"sync\"\n)\n\n",
      "note": "`sync` is here because the handler below keeps a count, and a count shared between requests needs a lock."
    },
    {
      "code": "// visits counts the requests it has answered.\ntype visits struct {\n\tmu sync.Mutex\n\tn  int\n}\n\n",
      "note": "**A handler can carry state.** A struct is the place for anything that outlives one request: a counter here, a database pool from lesson 6 on."
    },
    {
      "code": "func (v *visits) ServeHTTP(w http.ResponseWriter, r *http.Request) {\n\tv.mu.Lock()\n\tv.n++\n\tn := v.n\n\tv.mu.Unlock()\n\tfmt.Fprintf(w, \"visit %d\\n\", n)\n}\n\n",
      "note": "**This method is what makes `*visits` a handler.** The lock is not decoration: `net/http` runs every request in a goroutine of its own, so two requests can reach `v.n++` at the same moment. The value is copied out under the lock and written after it, so a slow client never holds the lock while the reply crosses the network."
    },
    {
      "code": "func hello(w http.ResponseWriter, r *http.Request) {\n\tfmt.Fprintln(w, \"hello\")\n}\n\n",
      "note": "A plain function with the right signature. On its own it is not a handler, because it has no methods."
    },
    {
      "code": "func main() {\n\tmux := http.NewServeMux()\n\tmux.Handle(\"/visits\", &visits{})\n\tmux.Handle(\"/hello\", http.HandlerFunc(hello))\n\tmux.HandleFunc(\"/hi\", hello)\n\tlog.Fatal(http.ListenAndServe(\"localhost:8080\", mux))\n}\n",
      "note": "**A mux of the program's own**, passed to `ListenAndServe` where the last section passed `nil`. `/visits` gets the struct; `/hello` gets the function converted by hand into an `http.HandlerFunc`; `/hi` gets the same function through `HandleFunc`, which converts it for you. The last two are one thing written twice."
    }
  ]
}
```

Run it, and ask each path:

```
ana@vm:~/counter$ curl -s localhost:8080/visits; curl -s localhost:8080/visits; curl -s localhost:8080/visits
visit 1
visit 2
visit 3
ana@vm:~/counter$ curl -s localhost:8080/hello; curl -s localhost:8080/hi
hello
hello
ana@vm:~/counter$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:11:49 GMT
Content-Length: 19

404 page not found
```

The count survived between requests because **one `visits` value served all three**: `&visits{}`
was made once, in `main`, and the mux holds a pointer to it. A path the mux has no pattern for gets
the package's own `404 page not found`, with a header asking the browser not to guess its type.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Three curl requests arrive at once. The http.Server gives each one a goroutine of its own, and all three goroutines call the same mux, which calls the same visits value. The counter inside it is shared by all of them.\"><defs><marker id=\"gb-l1-shared-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"170\" y=\"12\" width=\"240\" height=\"214\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"290\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">http.Server</text><rect x=\"20\" y=\"40\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl /visits</text><rect x=\"190\" y=\"40\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">goroutine for request 1</text><path d=\"M 140 60 L 188 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><path d=\"M 390 60 L 448 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><rect x=\"20\" y=\"105\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl /visits</text><rect x=\"190\" y=\"105\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">goroutine for request 2</text><path d=\"M 140 125 L 188 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><path d=\"M 390 125 L 448 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><rect x=\"20\" y=\"170\" width=\"120\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl /visits</text><rect x=\"190\" y=\"170\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">goroutine for request 3</text><path d=\"M 140 190 L 188 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><path d=\"M 390 190 L 448 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><rect x=\"450\" y=\"100\" width=\"100\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mux</text><text x=\"500\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one for all</text><path d=\"M 550 125 L 578 125\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l1-shared-ah)\"></path><rect x=\"580\" y=\"90\" width=\"105\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"632\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">*visits</text><text x=\"632\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">n, shared</text><text x=\"632\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">behind mu</text></svg>", "caption": "One goroutine per request, one mux and one visits value for all of them. The value they share is the reason ServeHTTP takes a lock."}
```

## Why the lock, if the requests came one at a time

These three requests did come one after another, and the program would have printed the same
without the mutex. **A program that is only correct when requests arrive in turn is a program
waiting for a busy evening.** `go-concurrency` lesson 16 showed the race detector catching exactly
this shape, an unguarded counter written from several goroutines, and lesson 15 of this course runs
it against a handler.

## A mux is a handler too

`http.NewServeMux()` returns a `*ServeMux`, and `ServeMux` has a `ServeHTTP` method: it looks at the
request, picks the handler whose pattern matches, and calls that handler's `ServeHTTP`. **So a mux
can be registered inside another mux, and anything that wraps a handler can wrap a whole mux.**
That one fact is what lesson 2 is built on: a middleware is a handler that holds another handler,
and the server only ever sees the outermost one.
