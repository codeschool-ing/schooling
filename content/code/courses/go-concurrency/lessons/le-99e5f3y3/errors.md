---
title: When one piece fails
version: 1
---

With one goroutine, an error is simple: return it, and the work stops. With twenty pieces of work
spread over four workers, a failure in one piece raises three questions. **Should the others stop?
Who learns why? And what happens to errors that were already on their way?** The usual answers are
yes, the caller, and they are kept, and the standard library has a tool for each.

The program below checks twenty files with four workers. Reading a file takes 20 milliseconds, and
files 3 and 4 are damaged. It is saved in `~/fanout/firsterr` as `firsterr.go`:

```go
// Command firsterr checks twenty files with four workers and stops at the first bad one.
package main

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

// check stands for verifying one file: reading it takes 20ms, and files 3 and 4 are damaged.
func check(ctx context.Context, file int) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	time.Sleep(20 * time.Millisecond)
	if file == 3 || file == 4 {
		return fmt.Errorf("file %d: checksum mismatch", file)
	}
	return nil
}

func main() {
	ctx, cancel := context.WithCancelCause(context.Background())
	defer cancel(nil)

	files := make(chan int)
	var checked atomic.Int64
	var mu sync.Mutex
	var errs []error

	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() {
			for f := range files {
				err := check(ctx, f)
				if errors.Is(err, context.Canceled) {
					continue
				}
				if err != nil {
					mu.Lock()
					errs = append(errs, err)
					mu.Unlock()
					cancel(err)
					continue
				}
				checked.Add(1)
			}
		})
	}

feed:
	for f := 1; f <= 20; f++ {
		select {
		case files <- f:
		case <-ctx.Done():
			break feed
		}
	}
	close(files)
	wg.Wait()

	fmt.Println("checked cleanly:", checked.Load(), "of 20")
	fmt.Println("cause:", context.Cause(ctx))
	fmt.Println("all errors:")
	fmt.Println(errors.Join(errs...))
}
```

```
ana@vm:~/fanout$ go run ./firsterr
checked cleanly: 2 of 20
cause: file 4: checksum mismatch
all errors:
file 4: checksum mismatch
file 3: checksum mismatch
```

**The first error stopped the rest.** Files 1 to 4 were being read when the first damaged one
failed; that worker called `cancel(err)`, and from then on three things refused to start new work.
`check` returns at once once the context has ended, which is lesson 11's "before starting expensive
work". The feeding loop in `main` waits on `ctx.Done()` beside its send, so it stops handing out
files. And a worker that got `context.Canceled` back skips it, because a cancellation is not one of
the failures being reported. Two files were checked cleanly out of twenty. That number moves from
run to run: when the two good files finish a moment before the damaged ones, their workers take
the next two before the cancel lands, and other runs of this program printed 4.

**`context.WithCancelCause` keeps the reason.** An ordinary `cancel()` leaves `ctx.Err()` saying
`context canceled` and nothing more. `cancel(err)` records the error that caused the
cancellation, and `context.Cause(ctx)` returns it: here `file 4: checksum mismatch`, whichever
failure called `cancel` first. Later calls of the same `cancel` change nothing, so the cause is the
first reason, which is usually the one somebody wants to read.

**`errors.Join` keeps the rest.** Files 3 and 4 were read at the same time and failed at the same
time, so cancelling could not prevent the second failure, and dropping it would hide a damaged file.
The workers collected every real error under a lock, and `errors.Join` turned them into one error
that prints one per line. `errors.Is` and `errors.As` look inside a joined error, so a caller can
still ask whether any of them was a particular kind.

The module `golang.org/x/sync` has a package, `errgroup`, that wraps this shape: start goroutines,
cancel on the first error, return it. It is outside the standard library, and this course uses
none; the program above is what such a package does underneath.
