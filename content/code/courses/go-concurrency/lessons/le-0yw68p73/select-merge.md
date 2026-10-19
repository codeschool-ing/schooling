---
title: Merging with select
version: 1
---

When the inputs are few and known when the code is written, a `select` can merge them in a single
goroutine, with no copiers and no `WaitGroup`. Lesson 5 introduced `select` for waiting on several
channels at once. Used as a merge, it has one trap that `range` hid: **a closed channel is always
ready to receive from**, and it delivers its type's zero value, forever.

The program below forgets that. It merges two channels of three numbers each, and counts what it
receives for 100 milliseconds. It is saved in `~/fanin/spin` as `spin.go`:

```go
// Command spin merges two channels with select and forgets that a closed channel is always ready.
package main

import (
	"fmt"
	"time"
)

func numbers(n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			out <- i
		}
	}()
	return out
}

func main() {
	a, b := numbers(3), numbers(3)
	stop := time.After(100 * time.Millisecond)
	values, zeros := 0, 0
	for {
		select {
		case v := <-a:
			if v == 0 {
				zeros++
			} else {
				values++
			}
		case v := <-b:
			if v == 0 {
				zeros++
			} else {
				values++
			}
		case <-stop:
			fmt.Println("in 100ms:", values, "real values and", zeros, "zero values")
			return
		}
	}
}
```

```
ana@vm:~/fanin$ go run ./spin
in 100ms: 6 real values and 972922 zero values
```

Six numbers were sent and six arrived. Then both channels closed, and the loop spent the rest of
its 100 milliseconds receiving 972,922 zeros: each `case` was ready on every turn, because receiving
from a closed channel never waits. A program written like this without the timer would never end,
and would keep a processor busy doing it. Worse, if the channels carried values where zero is a
legal reading, the zeros would be indistinguishable from data.

## Switching a case off

Two things repair it. **The comma-ok form tells a closed channel from a value**, as lesson 3
showed: `v, ok := <-a` sets `ok` to `false` once `a` is closed and drained. **And a nil channel is
never ready**, as lesson 5 showed, so setting the variable to `nil` switches its `case` off for the
rest of the loop. The loop runs while either channel is still live. It is saved in `~/fanin/pair`
as `pair.go`:

```go
// Command pair merges two channels with select, switching off each one as it closes.
package main

import "fmt"

func numbers(from, n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := from; i < from+n; i++ {
			out <- i
		}
	}()
	return out
}

func main() {
	a, b := numbers(1, 3), numbers(100, 2)
	for a != nil || b != nil {
		select {
		case v, ok := <-a:
			if !ok {
				fmt.Println("a closed")
				a = nil
				continue
			}
			fmt.Println("a:", v)
		case v, ok := <-b:
			if !ok {
				fmt.Println("b closed")
				b = nil
				continue
			}
			fmt.Println("b:", v)
		}
	}
	fmt.Println("both closed")
}
```

```
ana@vm:~/fanin$ go run ./pair
b: 100
a: 1
b: 101
b closed
a: 2
a: 3
a closed
both closed
```

Values from both channels, interleaved as they arrived. `b` closed first, after two values; its
`case` was switched off by `b = nil`, and the loop went on receiving from `a` alone until `a`
closed too. Then the condition `a != nil || b != nil` was false and the loop ended, with nothing
spinning.

Setting a channel variable to `nil` changes only that variable, the loop's own handle on the
channel. The channel itself and any other goroutine using it are untouched.

**Which to use is a question of how many inputs there are.** A `select` needs one `case` per
channel, written in the source, so it suits two or three channels fixed when the code was written,
and it keeps everything in one goroutine. A list of channels whose length is known only when the
program runs needs section 02's `merge`, one goroutine per input.
