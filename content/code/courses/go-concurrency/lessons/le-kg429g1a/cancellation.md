---
title: Stopping a pipeline early
version: 1
---

The cascade of section 03 runs from the first stage to the last, and it assumes the last stage
reads everything. Often it does not: a search stops at the first match, a page shows the first ten
results, a request is abandoned. **When the consumer stops early, every stage upstream is left
blocked on a send that nobody will ever receive**, and nothing in the cascade can reach them,
because closing only ever travels downstream.

The program below takes two results from a pipeline that would produce a thousand, then checks
how many goroutines are alive a tenth of a second later. It is saved in `~/pipeline/stuck` as
`stuck.go`:

```go
// Command stuck reads two results from a pipeline of a thousand, and walks away.
package main

import (
	"fmt"
	"runtime"
	"time"
)

func gen(n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			out <- i
		}
	}()
	return out
}

func sq(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for n := range in {
			out <- n * n
		}
	}()
	return out
}

func main() {
	results := sq(gen(1000))
	fmt.Println(<-results, <-results)
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines still alive:", runtime.NumGoroutine())
}
```

```
ana@vm:~/pipeline$ go run ./stuck
1 4
goroutines still alive: 3
```

Three: `main`, and the two stages. `sq` is blocked sending 9, and `gen` is blocked sending 4 to
`sq`. Neither will ever run again, and neither will be collected, because a blocked goroutine is
still a goroutine. **This is lesson 6's leak**, built here out of a perfectly correct pipeline. In
a program that exits at the end of `main` it costs nothing. In a server that builds a pipeline per
request it costs two goroutines and their memory per request, for ever.

## A context in every stage

The repair is the one lesson 11 gave for any loop that can wait: every send that might block also
waits on `ctx.Done()`. Every stage takes the context first, and the consumer cancels when it has
what it wants. The program below also counts the stages with a `WaitGroup`, so that `main` can wait
for them to finish rather than guess with a pause. It is saved in `~/pipeline/stoppable` as
`stoppable.go`:

```go
// Command stoppable is the same pipeline, with a context every stage watches.
package main

import (
	"context"
	"fmt"
	"runtime"
	"sync"
)

var stages sync.WaitGroup

func gen(ctx context.Context, n int) <-chan int {
	out := make(chan int)
	stages.Go(func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			select {
			case out <- i:
			case <-ctx.Done():
				return
			}
		}
	})
	return out
}

func sq(ctx context.Context, in <-chan int) <-chan int {
	out := make(chan int)
	stages.Go(func() {
		defer close(out)
		for n := range in {
			select {
			case out <- n * n:
			case <-ctx.Done():
				return
			}
		}
	})
	return out
}

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	results := sq(ctx, gen(ctx, 1000))
	fmt.Println(<-results, <-results)
	cancel()
	stages.Wait()
	fmt.Println("goroutines still alive:", runtime.NumGoroutine())
}
```

```
ana@vm:~/pipeline$ go run -race ./stoppable
1 4
goroutines still alive: 1
```

One goroutine alive: `main`. When `main` called `cancel`, `sq` was waiting to send 9, and its
`select` took the `ctx.Done()` case and returned; its deferred `close(out)` ran. `gen` was waiting
to send 4, took the same case, returned and closed its output too. `stages.Wait()` returned once
both had, and the race detector, built in, found nothing to report.

**Cancellation flows upstream, against the data, and closing flows downstream, with it.** A
pipeline that only closes leaks when its reader leaves; one that only cancels leaves its reader
waiting for a close. The stages of `stoppable.go` do both, and that is the full pattern: receive
with `range`, send inside a `select` on `ctx.Done()`, and `defer close(out)`.

Every pattern so far has relied on the rules of lesson 1 holding: no two goroutines touching the
same memory without synchronisation. Lesson 16 is the tool that checks them.
