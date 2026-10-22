---
title: When a channel is the worse tool
version: 1
---

Lesson 1 quoted the proverb *share memory by communicating*, and it is easy to read it as a ban on
mutexes. It is not. **Channels are for handing over ownership of data and for coordinating
goroutines; a mutex is for guarding a piece of state that several goroutines touch in place.** Using
a channel for the second job works, and costs clarity and time.

## One counter, three ways

The program below counts to 400,000 from four goroutines three times: with a mutex, with
`sync/atomic`, and by giving the number to one goroutine that owns it and receives the increments on
a channel. Each way is a function, timed by `main`. Saved as `three.go`:

```go
// Command three counts to 400,000 from four goroutines, three ways, and times each.
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

const goroutines, each = 4, 100_000

func withMutex() int {
	var mu sync.Mutex
	total := 0
	var wg sync.WaitGroup
	for range goroutines {
		wg.Go(func() {
			for range each {
				mu.Lock()
				total++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	return total
}

func withAtomic() int {
	var total atomic.Int64
	var wg sync.WaitGroup
	for range goroutines {
		wg.Go(func() {
			for range each {
				total.Add(1)
			}
		})
	}
	wg.Wait()
	return int(total.Load())
}

// withChannel gives the number to one goroutine, which owns it, and sends it the increments.
func withChannel() int {
	incs := make(chan int)
	done := make(chan int)
	go func() {
		total := 0
		for n := range incs {
			total += n
		}
		done <- total
	}()
	var wg sync.WaitGroup
	for range goroutines {
		wg.Go(func() {
			for range each {
				incs <- 1
			}
		})
	}
	wg.Wait()
	close(incs)
	return <-done
}

func main() {
	for _, way := range []struct {
		name string
		f    func() int
	}{{"mutex", withMutex}, {"atomic", withAtomic}, {"channel", withChannel}} {
		start := time.Now()
		total := way.f()
		fmt.Printf("%-8s total %d in %v\n", way.name, total, time.Since(start).Round(time.Millisecond))
	}
}
```

Built with `go build -o three three.go` and run twice:

```
ana@vm:~/locks$ ./three
mutex    total 400000 in 26ms
atomic   total 400000 in 2ms
channel  total 400000 in 80ms
ana@vm:~/locks$ ./three
mutex    total 400000 in 31ms
atomic   total 400000 in 8ms
channel  total 400000 in 95ms
```

All three got the right total. The atomic counter was the fastest in both runs, at 2 and 8
milliseconds, against 26 and 31 for the mutex; the gap moves from run to run, the order does not.
The channel took about three times as long as the mutex, 80 and 95 milliseconds. A channel operation is a handover between two
goroutines, with a lock inside the channel and a goroutine woken on the other side. A mutex costs
a few atomic instructions when it is free, and puts a goroutine to sleep only when it has to wait. For a counter, the channel version is also the
longest to read: a goroutine, two channels, a close and a final receive, to do what `total++` says.

## `sync/atomic`, for a single number

`atomic.Int64` and its relatives, `Int32`, `Uint64`, `Bool` and `Pointer`, make one operation on
one value indivisible: `Add`, `Load`, `Store`, `Swap`, `CompareAndSwap`. **They are the right tool
when the whole of the shared state is one number or one pointer**, a counter of requests, a flag
that says "shutting down". Lesson 7's `semaphore.go` counted failures with one.

They stop being the right tool at the second value. Two atomic variables updated one after the other
can be seen half-updated by another goroutine, between the two; keeping them consistent is what a
mutex is for. Like a mutex, an atomic type must not be copied after first use, and `go vet` checks
that too.

## A rule for choosing

The Go project's own advice comes down to which question the code is answering:

| the code is… | reach for |
|---|---|
| handing a value to another goroutine, which then owns it | a channel |
| spreading work, or collecting results, lessons 7, 13 and 14 | a channel |
| saying "this happened", "stop", "I am done" | a channel, often closed rather than sent on |
| guarding a cache, a map, a struct that goroutines read and change in place | a mutex |
| one counter or one flag, nothing else | `sync/atomic` |

**When a design with channels needs a goroutine whose only job is to hold a variable, that is
usually a mutex wearing a disguise**, and `withChannel` above is the example. Lesson 9 adds the rest
of `sync`: waiting for goroutines, doing something once, and a map built for concurrent use.
