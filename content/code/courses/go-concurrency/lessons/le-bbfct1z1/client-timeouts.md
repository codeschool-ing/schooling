---
title: A server that never answers
version: 1
---

The failure that matters most for a client is not a 404 or a 500. It is a server that accepts the
connection and then says nothing, for a minute or for ever. **An `http.Client` with no timeout and
a request with no deadline wait exactly that long**, and `http.DefaultClient` has no timeout. A
test server can play that part on demand, which no real server will do when you want it to.

## The test

The handler waits until the request's context ends, which happens when the client gives up and
closes the connection. The client side gives up after 50 milliseconds, through the context lesson
10 taught. Saved as `timeout_test.go`:

```go
package wordcount

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestHTTPSourceTimeout(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		<-r.Context().Done() // never answer; return when the client goes away
	}))
	defer srv.Close()
	src := HTTPSource{BaseURL: srv.URL, Client: srv.Client()}

	ctx, cancel := context.WithTimeout(t.Context(), 50*time.Millisecond)
	defer cancel()
	start := time.Now()
	_, err := TopOf(ctx, src, "slow.txt", 1)
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("err = %v, want context.DeadlineExceeded", err)
	}
	t.Logf("gave up after %v: %v", time.Since(start).Round(time.Millisecond), err)
}
```

```
ana@vm:~/wordcount$ go test -v -run Timeout
=== RUN   TestHTTPSourceTimeout
    timeout_test.go:26: gave up after 51ms: open slow.txt: Get "http://127.0.0.1:43865/slow.txt": context deadline exceeded
--- PASS: TestHTTPSourceTimeout (0.06s)
PASS
ok  	example.com/wordcount	0.062s
```

The request was cancelled when the deadline passed, the error wraps `context.DeadlineExceeded`
through three layers, `http.Client`, `HTTPSource` and `TopOf`, and `errors.Is` still finds it. That
is the test proving `HTTPSource` honours the context it is given, which is the whole reason `Open`
takes one.

## The handler has to stop too

The handler's `<-r.Context().Done()` is not decoration. `srv.Close` waits for every request still
being handled to finish, so a test handler that ignores its context holds the test open for as long
as it chooses to wait. A throwaway file shows it, with a handler that sleeps for six seconds
whatever happens, saved as `stuck_test.go`:

```go
package wordcount

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestStuckServer(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(6 * time.Second) // ignores the client entirely
	}))
	defer srv.Close()
	ctx, cancel := context.WithTimeout(t.Context(), 50*time.Millisecond)
	defer cancel()
	_, err := TopOf(ctx, HTTPSource{BaseURL: srv.URL, Client: srv.Client()}, "slow.txt", 1)
	t.Logf("client gave up: %v", err)
}
```

```
ana@vm:~/wordcount$ go test -v -run Stuck
=== RUN   TestStuckServer
    stuck_test.go:19: client gave up: open slow.txt: Get "http://127.0.0.1:35767/slow.txt": context deadline exceeded
2026/10/16 19:47:20 httptest.Server blocked in Close after 5 seconds, waiting for connections:
  *net.TCPConn 0x2dd721902010 127.0.0.1:37320 in state active
--- PASS: TestStuckServer (6.02s)
PASS
ok  	example.com/wordcount	6.019s
ana@vm:~/wordcount$ rm stuck_test.go
```

**The client gave up after 50 milliseconds and the test still took six seconds**, because
`srv.Close` waited for the sleeping handler, and said so on the way. In a suite of a few hundred
tests that is how a run goes from seconds to minutes with every test passing. A handler written
for a test watches `r.Context()`, exactly as a production handler should.

## A deadline per request or per client

The test above put the deadline on the context, which is the right place when the caller knows how
long the whole operation may take. `http.Client` also has a `Timeout` field, a limit on each
request made through that client, including reading the body. The two combine, and whichever ends
first wins. What a client in production should not have is neither: give `HTTPSource` a client with
a `Timeout`, or callers that always pass a deadline, and test it the way this section did.
