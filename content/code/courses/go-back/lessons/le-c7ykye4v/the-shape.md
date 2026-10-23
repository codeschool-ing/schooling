---
title: A handler that holds a handler
version: 1
---

Some work belongs to every request rather than to one route: writing a line in the log, turning a
panic into a 500, answering a browser's questions about where it may send requests, checking who
is asking. Written into each handler, it is copied a dozen times and forgotten in the thirteenth.
**A middleware is that work written once, as a handler that holds another handler.** It does its
part, calls the one it holds, and can do more after that one returns.

In Go there is no framework type for it. The shape is a function from a handler to a handler:

```go
func(next http.Handler) http.Handler
```

It receives the handler to wrap, `next`, and returns a new handler whose `ServeHTTP` decides
whether, when and how to call `next.ServeHTTP`. Lesson 1 section 04 ended on the fact that makes
this work: **a mux is a handler too**, so the whole router can be the `next` of something.

## Watching the order

This program wraps one mux twice, and each wrapper prints on the way in and on the way out:

```go
// wrap/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

// announce returns a middleware that prints its name on the way in and on
// the way out of every request.
func announce(name string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			fmt.Println(name, "in")
			next.ServeHTTP(w, r)
			fmt.Println(name, "out")
		})
	}
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /hello", func(w http.ResponseWriter, r *http.Request) {
		fmt.Println("  the handler")
		fmt.Fprintln(w, "hello")
	})
	var h http.Handler = mux
	h = announce("inner")(h)
	h = announce("outer")(h)
	log.Fatal(http.ListenAndServe("localhost:8080", h))
}
```

`h` starts as the mux. `announce("inner")` wraps it, and `announce("outer")` wraps the result, so
the server receives the outer one. Run it, ask twice, and read what the server printed:

```
ana@vm:~/wrap$ curl -s localhost:8080/hello
hello
ana@vm:~/wrap$ curl -s localhost:8080/nothing
404 page not found
ana@vm:~/wrap$ go run .
outer in
inner in
  the handler
inner out
outer out
outer in
inner in
inner out
outer out
```

**The last wrapper applied is the first to run, and the last to finish.** A request goes in
through every layer and comes back out through them in reverse, like a call stack, because that
is what it is: each `ServeHTTP` calls the next and waits for it. The second request found no
route, and both middlewares still ran around the mux's 404. **A middleware wraps whatever is
inside it, including the answers nobody wrote.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Three boxes side by side: announce outer, announce inner and the mux. Arrows marked in go from outer to inner to the mux, where the handler runs; arrows marked out come back from the mux to inner to outer. The numbers give the order the lines were printed: 1 outer in, 2 inner in, 3 the handler, 4 inner out, 5 outer out.\"><defs><marker id=\"gb-l2-onion-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"40\" width=\"150\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">announce(\"outer\")</text><rect x=\"230\" y=\"40\" width=\"150\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"305\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">announce(\"inner\")</text><rect x=\"420\" y=\"40\" width=\"150\" height=\"170\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"495\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">mux</text><text x=\"115\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1 outer in</text><text x=\"305\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2 inner in</text><text x=\"495\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 the handler</text><text x=\"305\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4 inner out</text><text x=\"115\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5 outer out</text><path d=\"M 190 110 L 228 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-onion-ah)\"></path><path d=\"M 380 110 L 418 110\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-onion-ah)\"></path><path d=\"M 420 160 L 382 160\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-onion-ah)\"></path><path d=\"M 228 160 L 192 160\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-onion-ah)\"></path><text x=\"209\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">in</text><text x=\"209\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">out</text><text x=\"399\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">in</text><text x=\"399\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">out</text></svg>", "caption": "The last wrapper applied is the outermost: a request goes in through every layer and comes back out in reverse order."}
```

## A helper for the order

Wrapping by hand reads backwards, inner first, and boxoffice will wrap four times. A small
function puts them in reading order, the first one outermost:

```go
func chain(h http.Handler, mws ...func(http.Handler) http.Handler) http.Handler {
	for _, mw := range slices.Backward(mws) {
		h = mw(h)
	}
	return h
}
```

`slices.Backward` walks the list from its end, so the last middleware named is applied first and
ends up innermost. `chain(mux, a, b)` is `a(b(mux))`: a request meets `a`, then `b`, then the mux.

## What the rest of this lesson builds

Sections 03 to 06 each add one middleware to boxoffice, in a file of its own, and section 07
wires all of them into the server and starts it. **The transcripts in sections 03 to 06 come from
that finished server**, because each one prints the same with or without the middlewares after
it; type each file as you reach it and run the whole at the end.
