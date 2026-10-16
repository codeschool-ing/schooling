---
title: Deadlines, timeouts and why it stopped
version: 1
---

Lesson 5 put a timeout on one `select` with `time.After`. That covers one wait. A request that
calls three services, each through two functions, needs **one budget for the whole of it**, and every
wait inside it should give up when the budget is spent. **`context.WithTimeout(parent, d)` is a
context that cancels itself after `d`; `context.WithDeadline(parent, t)` does the same at the time
`t`.** The first is written in terms of the second.

## A lookup with a budget

The program below gives a slow lookup 100 milliseconds. It uses `WithTimeoutCause`, from Go 1.21,
which also records an error of your own as the reason. Saved as `deadline.go`:

```go
// Command deadline gives a slow lookup 100 ms, and asks afterwards why it stopped.
package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var errSlowDNS = errors.New("lookup budget of 100ms spent")

// lookup pretends to ask a slow server, and gives up when ctx is done.
func lookup(ctx context.Context) (string, error) {
	select {
	case <-time.After(300 * time.Millisecond):
		return "192.0.2.10", nil
	case <-ctx.Done():
		return "", ctx.Err()
	}
}

func main() {
	ctx, cancel := context.WithTimeoutCause(context.Background(), 100*time.Millisecond, errSlowDNS)
	defer cancel()

	d, ok := ctx.Deadline()
	fmt.Println("has a deadline:", ok, " in about", time.Until(d).Round(10*time.Millisecond))

	start := time.Now()
	addr, err := lookup(ctx)
	fmt.Printf("addr %q after %v\n", addr, time.Since(start).Round(10*time.Millisecond))
	fmt.Println("err:", err)
	fmt.Println("is DeadlineExceeded:", errors.Is(err, context.DeadlineExceeded))
	fmt.Println("cause:", context.Cause(ctx))
}
```

```
ana@vm:~/ctx$ go run deadline.go
has a deadline: true  in about 100ms
addr "" after 100ms
err: context deadline exceeded
is DeadlineExceeded: true
cause: lookup budget of 100ms spent
```

Read the lines in order:

- **`Deadline()` reported the budget**, about 100 milliseconds from the moment it was asked. Code
  far down the call can use it to decide not to start something that cannot finish in time.
- `lookup` gave up after 100 milliseconds, not the 300 its server would have taken, because its
  `select` was also waiting on `ctx.Done()`.
- **`Err()` said `context deadline exceeded`**, and `errors.Is(err, context.DeadlineExceeded)` is
  how code should test for it, since callers further up may wrap the error.
- **`context.Cause` returned the error given to `WithTimeoutCause`**, which says which budget ran
  out. `Err()` can only ever be one of two values, so in a program with several deadlines it cannot
  say whose it was. The same pair exists for manual cancellation: `WithCancelCause` returns a
  `cancel(err)` that records a cause.

A child can only tighten a deadline. **`WithTimeout` on a context that already has an earlier
deadline keeps the earlier one**, so a function deep in the call cannot give itself more time than
its caller had.

## The `cancel` you must call

`WithTimeout` returns a `cancel` function too, and it is tempting to drop it, since the context will
cancel itself anyway. Until the deadline it holds a timer and a place in its parent's list of
children. Saved as `lost.go`:

```go
// Command lost forgets to call the cancel function it was given.
package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	ctx, _ := context.WithTimeout(context.Background(), time.Second)
	fmt.Println(ctx.Err())
}
```

```
ana@vm:~/ctx$ go vet lost.go
lost.go:11:7: the cancel function returned by context.WithTimeout should be called, not discarded, to avoid a context leak
```

**`go vet` refuses the discarded `cancel` by name.** In a server that makes a context per request
with a long timeout and never cancels it, those timers and entries pile up until each deadline
passes. `defer cancel()` on the line after the `With…` call is the habit, as `deadline.go` has it.
