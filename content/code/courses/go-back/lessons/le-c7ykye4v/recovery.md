---
title: Recovering from a panic
version: 1
---

A panic in a handler is a bug: a nil map written to, an index past the end of a slice, a nil
pointer followed. `go` lesson 36 put panics on the side of "this should never happen" and errors
on the side of "this will happen", and nothing in this lesson changes that. **What a server has to
decide is what one bug in one request does to everybody else.**

## What `net/http` does on its own

```go
// fragile/main.go
package main

import (
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /boom", func(w http.ResponseWriter, r *http.Request) {
		var seats map[string]int
		seats["A1"]++
	})
	log.Fatal(http.ListenAndServe("localhost:8080", mux))
}
```

Writing to a nil map panics. Ask for it:

```
ana@vm:~/fragile$ curl -si localhost:8080/boom; echo "exit $?"
exit 52
```

`curl` printed nothing at all, and `-s` hid its complaint, so the exit status is the only witness:
**52 is curl's "empty reply from server"**. The connection was closed with no status line, no
headers and no body. The server's terminal shows why:

```
ana@vm:~/fragile$ go run .
2026/10/16 19:29:16 http: panic serving 127.0.0.1:53290: assignment to entry in nil map
goroutine 23 [running]:
net/http.(*conn).serve.func1()
	/usr/local/go/src/net/http/server.go:1939 +0xbb
panic({0x91a830?, 0x98fc00?})
	/usr/local/go/src/runtime/panic.go:859 +0x125
main.main.func1({0x1c5c5dd462d4?, 0x48a352?}, 0x0?)
	/home/ana/fragile/main.go:13 +0x28
net/http.HandlerFunc.ServeHTTP(0x1c5c5dd340c0?, {0x94fc58?, 0x1c5c5dd2a1e0?}, 0x61635a?)
	/usr/local/go/src/net/http/server.go:2338 +0x29
net/http.(*ServeMux).ServeHTTP(0x482839?, {0x94fc58, 0x1c5c5dd2a1e0}, 0x1c5c5dd62280)
	/usr/local/go/src/net/http/server.go:2903 +0x1cf
net/http.serverHandler.ServeHTTP({0x1c5c5dd30380?}, {0x94fc58?, 0x1c5c5dd2a1e0?}, 0x1?)
	/usr/local/go/src/net/http/server.go:3413 +0x8e
net/http.(*conn).serve(0x1c5c5dd5a2d0, {0x950008, 0x1c5c5dd27500})
	/usr/local/go/src/net/http/server.go:2137 +0x6dc
created by net/http.(*Server).Serve in goroutine 1
	/usr/local/go/src/net/http/server.go:3581 +0x4fd
```

**`net/http` recovered the panic itself.** It logged it with the client's address and the whole
stack, closed that one connection, and went on serving: the program did not die, and a request
arriving a moment later would have been answered. Read the stack from the top down to the first
line that is your own code, `main.main.func1` at `main.go:13`, which is the line that wrote to the
map. Everything above it is the runtime reporting the panic, and everything below is `net/http`
calling your handler.

That default protects the process and is unkind to the client, which is left with a connection
that closed on it and nothing to show the user.

## A 500 instead of silence

The middleware below catches the panic first, with `recover` in a deferred function, and turns it
into a response:

```go
// sturdy/main.go
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
			http.Error(w, "internal server error", http.StatusInternalServerError)
		}()
		next.ServeHTTP(w, r)
	})
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /boom", func(w http.ResponseWriter, r *http.Request) {
		var seats map[string]int
		seats["A1"]++
	})
	log.Fatal(http.ListenAndServe("localhost:8080", recoverPanics(mux)))
}
```

```
ana@vm:~/sturdy$ curl -si localhost:8080/boom
HTTP/1.1 500 Internal Server Error
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 16 Oct 2026 22:29:20 GMT
Content-Length: 22

internal server error
```

```
ana@vm:~/sturdy$ go run .
2026/10/16 19:29:20 panic serving GET /boom: assignment to entry in nil map
goroutine 19 [running]:
runtime/debug.Stack()
	/usr/local/go/src/runtime/debug/stack.go:26 +0x5e
main.recoverPanics.func1.1()
	/home/ana/sturdy/main.go:20 +0x8d
```

The client now has a status it can act on, and **the body says nothing about the cause**: a
panic's message can hold anything, and a stranger does not need to know that a map was nil. The
detail went to the log, with `debug.Stack()` printing the stack of the goroutine that panicked;
the six lines above are its top, and the full stack goes on to the handler at `main.go`.

Three details in that middleware are deliberate:

- **`recover` only works in a deferred function**, and only in the goroutine that panicked. A
  handler that starts goroutines of its own has to protect them itself, because a panic in one of
  those ends the whole program and no middleware can stop it.
- **`http.ErrAbortHandler` is re-panicked.** It is the value a handler panics with on purpose to
  abandon a response halfway, and `net/http` treats it as a request to close the connection
  without logging anything. Turning it into a 500 would undo that.
- **If the handler had already written, the 500 cannot be sent.** The status left with the first
  write, so `http.Error` adds a superfluous `WriteHeader` line to the log and the client gets
  whatever was half written. Recovery makes a panic survivable; it does not make it invisible.

## The same in boxoffice

boxoffice gets the same middleware in a file of its own:

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
			http.Error(w, "internal server error", http.StatusInternalServerError)
		}()
		next.ServeHTTP(w, r)
	})
}
```
