---
title: A buffered channel as a limit
version: 1
---

A pool keeps a fixed set of goroutines and feeds them. There is a second way to cap concurrency
that keeps one goroutine per job and limits how many may **work** at once. It is called a
semaphore: a counter of free places, taken before the work and given back after. **In Go a buffered
channel is a semaphore with no extra code**: sending takes a place, and blocks when there are none;
receiving gives one back.

The jobs are `unbounded.go`'s, and the limit is fifty again, saved as `semaphore.go`:

```go
// Command semaphore starts one goroutine per job but lets only 50 work at once.
package main

import (
	"fmt"
	"os"
	"sync"
	"sync/atomic"
	"time"
)

func job() error {
	f, err := os.Open("/etc/hostname")
	if err != nil {
		return err
	}
	defer f.Close()
	time.Sleep(50 * time.Millisecond)
	return nil
}

func main() {
	start := time.Now()
	sem := make(chan struct{}, 50)
	var failed atomic.Int64
	var wg sync.WaitGroup
	for range 1000 {
		sem <- struct{}{}
		wg.Go(func() {
			defer func() { <-sem }()
			if job() != nil {
				failed.Add(1)
			}
		})
	}
	wg.Wait()
	fmt.Println("jobs: 1000  limit: 50  failed:", failed.Load(), " took:", time.Since(start).Round(10*time.Millisecond))
}
```

`sem` has room for fifty empty structs; a `struct{}` takes no memory, because the channel's only
job is to count. The loop sends **before** starting each goroutine, so the fifty-first send waits
until some job finishes and its deferred receive frees a place. `atomic.Int64` is a counter that
many goroutines may add to safely without a lock, lesson 8's subject.

```
ana@vm:~/pool$ (ulimit -n 256; ./semaphore)
jobs: 1000  limit: 50  failed: 0  took: 1.04s
```

The same result as `pool.go` under the same limit: nothing failed, in about a second.

## Which one to choose

The difference is where the waiting happens, and what exists while it does.

| | worker pool | semaphore |
|---|---|---|
| goroutines alive | the workers, a fixed number | at most the limit, plus the loop that starts them |
| who waits when it is full | the producer, sending on `jobs` | the loop, sending on `sem` |
| a job's own state | passed in on the channel | captured by the closure, like any goroutine |
| natural fit | a stream of jobs that never ends, from a queue | a known list of jobs, each a function call |

**Acquire before `go`, not inside the goroutine.** If the send on `sem` were the goroutine's first
line, the loop would start all thousand goroutines at once and only their work would wait. The
files would be safe, but a thousand goroutines would exist, each holding whatever its job carries.
Taking the place in the loop is what keeps the count of goroutines bounded as well.

Outside the standard library, the `golang.org/x/sync` module offers the same idea as a type,
`semaphore.Weighted`, and `errgroup.Group` has a `SetLimit` that does this and collects the first
error. This course stays inside the standard library; lesson 13 builds error handling for fanned-out
work by hand.
