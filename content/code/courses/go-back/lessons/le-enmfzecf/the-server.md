---
title: The server value, and the timeouts it ships without
version: 1
---

`http.ListenAndServe(addr, handler)` is a convenience. It builds an `http.Server` with the address
and the handler you gave it and every other field left at its zero value, and **for the timeouts
the zero value means none**. A connection may take as long as it likes to send its headers, to send
its body, and to sit idle between requests, and the server keeps a goroutine and a file descriptor
for it the whole time.

That is a real attack and an old one. A client opens a connection, sends half of a request, and
then sends nothing; open a few thousand of those and a server with no timeouts runs out of
connections while doing no work at all. It was named *Slowloris* when it was published in 2009,
and **the defence is a deadline on reading the request**, which the zero value does not set.

## Holding a connection open

Run `hello` from section 03 again, which used `ListenAndServe` and so has no deadlines. Bash can
open a TCP connection by itself with the file name `/dev/tcp/HOST/PORT`; this sends a request line
and one header, and never sends the blank line that ends the headers:

```
ana@vm:~/hello$ exec 3<>/dev/tcp/localhost/8080; printf "GET / HTTP/1.1\r\nHost: localhost\r\n" >&3; timeout 5 cat <&3; echo "exit $?"
exit 124
```

`cat` waited for an answer, and `timeout` killed it after five seconds; **124 is `timeout`'s exit
status for "I had to stop it"**. The server had sent nothing and closed nothing, and it would have
gone on waiting after five minutes as patiently as after five seconds.

## The same request against a server with deadlines

Build the server yourself, and set the fields:

```go
// patient/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "hello")
	})
	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           mux,
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}
```

```
ana@vm:~/patient$ start=$SECONDS; exec 3<>/dev/tcp/localhost/8080; printf "GET / HTTP/1.1\r\nHost: localhost\r\n" >&3; timeout 5 cat <&3; echo "exit $? after $((SECONDS-start)) s"
exit 0 after 2 s
```

This time `cat` ended by itself: **the server closed the connection after two seconds**, without a
word, and `cat` saw the end of the stream and exited 0. A client that sends its headers in good time
never notices the deadline exists.

## What each field bounds

| field | the clock starts | and stops |
|---|---|---|
| `ReadHeaderTimeout` | when the connection is accepted, or a kept-alive one starts a new request | when the headers have been read |
| `ReadTimeout` | the same moment | when the body has been read as well |
| `WriteTimeout` | when the headers have been read | when the response has been written |
| `IdleTimeout` | after a response, on a connection kept alive | when the next request begins |

**`ReadHeaderTimeout` is the one that stops Slowloris**, and it costs nothing: a real client sends
its headers in milliseconds. The others are judgements about your own handlers. `WriteTimeout` of
ten seconds means a handler that takes eleven has its connection cut under it, so it is set above
the slowest response the service is meant to give; lesson 13 meets a response meant to last for
minutes, and lifts it for that one route. If `IdleTimeout` is left at zero, the server uses
`ReadTimeout` for it.

The numbers here are a starting point and not a law: two, ten, ten and sixty seconds keep a small
API safe from the attack above and give its handlers room. **What is not defensible is the zero
value**, and every server from here on is an `http.Server` with all four set.

## The request carries its own deadline

One more thing comes with every request and needs no field: `r.Context()`. It is a
`context.Context` that **the server cancels when the client goes away** or the connection closes,
which is the first use case `go-concurrency` lesson 12 named. A handler that passes it on to a
database query stops that query when nobody is left to read its answer. Lesson 6 passes it on.
