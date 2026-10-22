---
title: Where a loop looks
version: 1
---

A context does not stop anything by itself. **Cancelling closes a channel and records a reason;
the code doing the work has to look.** A function that is handed `ctx` and never consults it
accepts the parameter and ignores the request, and the caller's deadline passes with the work
still running. The question for every loop that can run long is where it looks.

The program below runs two loops of 300 items, each item a millisecond of work, with a context
that ends after 50 milliseconds. One loop never asks; the other asks before every item. It is saved
in `~/propagate/loop` as `loop.go`:

```go
// Command loop cancels two loops at the same moment and times how long each takes to notice.
package main

import (
	"context"
	"fmt"
	"time"
)

// step stands for one unit of real work: a millisecond of it.
func step() { time.Sleep(time.Millisecond) }

// deaf never asks its context anything.
func deaf(ctx context.Context, items int) int {
	done := 0
	for range items {
		step()
		done++
	}
	return done
}

// polite asks before every item.
func polite(ctx context.Context, items int) int {
	done := 0
	for range items {
		if ctx.Err() != nil {
			break
		}
		step()
		done++
	}
	return done
}

func run(name string, f func(context.Context, int) int) {
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()
	start := time.Now()
	n := f(ctx, 300)
	fmt.Printf("%-6s did %3d of 300 items and returned after %v\n",
		name, n, time.Since(start).Round(10*time.Millisecond))
}

func main() {
	run("deaf", deaf)
	run("polite", polite)
}
```

```
ana@vm:~/propagate$ go run ./loop
deaf   did 300 of 300 items and returned after 350ms
polite did  47 of 300 items and returned after 50ms
```

`deaf` was told to stop at 50 milliseconds and finished all 300 items anyway, returning at 350.
Its caller had long since given up on the result, so 300 milliseconds of work were thrown away,
and in a server they would have been taken from requests that were still waiting. `polite` did 47
items and returned at 50 milliseconds, within one item of the deadline. **The distance between the
deadline and the return is the cost of one step**, because that is how long the loop goes between
two looks.

## Two ways to look

There are two, and each fits a different kind of step.

- **`ctx.Err() != nil`** at the top of each iteration, as `polite` does, when each step is
  computation or a call that returns by itself. It asks without waiting, and a non-nil answer is
  also the reason to return: `context.Canceled` or `context.DeadlineExceeded`.
- **A `select` with `case <-ctx.Done()`**, as `fetch` did in section 02, when the step is a WAIT:
  on a channel, a timer, a result from another goroutine. A loop blocked in a plain receive is not
  running any code that could check `ctx.Err()`, so the only way to notice cancellation during the
  wait is to wait on `Done()` at the same time. Lesson 5 built that `select`.

Where the step itself takes a context, such as a request made with `http.NewRequestWithContext` in
lesson 12, it does the looking for you and returns the context's error when it ends. **Passing
`ctx` into such a call counts as checking**, which is one more reason it goes into every call.

## How often

Checking costs little: `ctx.Err()` reads a value the context keeps. It is not free, and a loop
whose step is a single addition does not need to ask a billion times. The useful rule is about
time rather than counts: **look often enough that the loop overruns a deadline by an amount
nobody minds.** A step of a millisecond, as here, overran by under one. A loop of very fast steps
can check every thousand, and a step that takes a second needs a check inside it, through a
context passed further down.

One more place matters, and it is easy to miss: **before starting expensive work at all.** A
function called with a context that has already ended should return its error at once rather than
open a file, start a goroutine or send a request whose answer nobody is waiting for.
