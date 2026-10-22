---
title: An HTTP request
version: 1
---

Lessons 10 and 11 built contexts with nothing real at either end. A web server is the place the
mechanism was designed for, and in `net/http` **both sides of a request already carry a context**:
the server hands one to every handler, and the client takes one with every request. A program
that uses both is the clearest way to see what each does.

The program below is a server and its client in one process. The handler takes two seconds to
produce a report, unless its request ends first. The client will not wait more than 100
milliseconds. The server listens on `127.0.0.1:8412`, an address only this machine can reach. It
is saved in `~/cases/abandon` as `abandon.go`:

```go
// Command abandon serves one slow request and gives up on it from the client side.
package main

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"time"
)

func main() {
	gone := make(chan string, 1)
	report := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		select {
		case <-time.After(2 * time.Second):
			fmt.Fprintln(w, "report ready")
			gone <- "server: finished the report"
		case <-r.Context().Done():
			gone <- fmt.Sprintf("server: client left after %v: %v",
				time.Since(start).Round(10*time.Millisecond), r.Context().Err())
		}
	})
	ln, err := net.Listen("tcp", "127.0.0.1:8412")
	if err != nil {
		fmt.Println(err)
		return
	}
	go http.Serve(ln, report)

	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, "GET", "http://127.0.0.1:8412/report", nil)
	if err != nil {
		fmt.Println(err)
		return
	}
	_, err = http.DefaultClient.Do(req)
	fmt.Println("client:", err)
	fmt.Println(<-gone)
}
```

```
ana@vm:~/cases$ go run ./abandon
client: Get "http://127.0.0.1:8412/report": context deadline exceeded
server: client left after 100ms: context canceled
```

Read the two lines as two halves of one event.

**The client side.** `http.NewRequestWithContext` attaches `ctx` to the request, and `Do` returns
as soon as the context ends, whatever the server is doing. The error names the address and the
reason, `context deadline exceeded`, and `errors.Is(err, context.DeadlineExceeded)` would find it,
because the client wraps the context's error rather than replacing it. `http.NewRequest` without
the context still exists, and it is the request that waits as long as the server takes.

**The server side.** When the client gave up, it closed its connection. The server noticed, and
cancelled the context of the request that connection carried, `r.Context()`. The handler was
waiting on that context in its `select`, so it stopped after 100 milliseconds instead of spending
two seconds on a report nobody would read. Its reason is `context canceled`, not the client's
deadline: **the server does not know why the client left, only that it did.**

A handler that ignores `r.Context()` still works, and finishes every abandoned report for nobody.
Under load that is the difference between a server that sheds the work its clients stopped wanting
and one that falls further behind with every timeout. In a real handler the context goes further
down, into every call the handler makes, exactly as `ctx` went from `handle` to `fetch` in
lesson 11.

One rule is easy to miss: **`r.Context()` belongs to that request and ends with it.** Work the
handler starts in a goroutine of its own and expects to outlive the response must not take that
context, or it is cancelled the moment the handler returns. That is the case for
`context.WithoutCancel`, from lesson 11.
