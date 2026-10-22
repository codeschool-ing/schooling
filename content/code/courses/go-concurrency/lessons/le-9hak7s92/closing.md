---
title: Closing a channel
version: 1
---

A receiver often needs to know one thing besides the values: **that no more are coming**. That is
what `close(ch)` says. It does not destroy the channel or throw away what is in it. It marks the
channel as finished, and every receive after the last value answers at once instead of waiting.

## What a receive says after close

The two-value form of a receive, `v, ok := <-ch`, reports which kind of answer it got. The program
below puts two values in a channel with room for both, a buffered channel of the kind lesson 4
explains, closes it, and receives four times, saved as `closed.go`:

```go
// Command closed receives from a channel after it has been closed.
package main

import "fmt"

func main() {
	ch := make(chan string, 2)
	ch <- "first"
	ch <- "second"
	close(ch)

	for range 4 {
		v, ok := <-ch
		fmt.Printf("%q %v\n", v, ok)
	}
}
```

```
ana@vm:~/channels$ go run closed.go
"first" true
"second" true
"" false
"" false
```

The first two receives took the two values that were sent, with `ok` true. **After that the channel
was closed and empty, and every further receive answered at once with the zero value of the
element type and `ok` false**: `""` for a string, `0` for an int. It never blocks again and never
runs out. That is why the `ok` matters: without it, a receiver cannot tell an empty string somebody
sent from the empty string a closed channel hands out.

Note the order. Closing did not discard `"first"` and `"second"`; values sent before `close` are
still delivered, and only then does the channel start answering `false`.

## Two mistakes that panic

Closing is a statement about the future, so it can be made only once, and only by a side that will
not send again. Sending on a closed channel panics, saved as `sendclosed.go`:

```go
// Command sendclosed sends on a channel that is already closed.
package main

func main() {
	ch := make(chan int, 1)
	close(ch)
	ch <- 1
}
```

and closing it a second time panics too, saved as `closetwice.go`:

```go
// Command closetwice closes the same channel twice.
package main

func main() {
	ch := make(chan int)
	close(ch)
	close(ch)
}
```

```
ana@vm:~/channels$ go run sendclosed.go
panic: send on closed channel

goroutine 1 [running]:
main.main()
	/home/ana/channels/sendclosed.go:7 +0x3a
exit status 2
ana@vm:~/channels$ go run closetwice.go
panic: close of closed channel

goroutine 1 [running]:
main.main()
	/home/ana/channels/closetwice.go:7 +0x30
exit status 2
```

Both are panics, and both end the program, as lesson 2 showed every panic does. **The rule they
enforce is that only the sending side closes, and only once.** A receiver that closes a channel can
never be sure no sender is about to send, and one stray send after that is this panic in production.
There is no function that asks whether a channel is closed, either: by the time the answer
arrived, it could be out of date.

So who closes is a decision about the program's design, made once: **the goroutine that owns the
sending closes, when it has sent everything.** If several goroutines send on one channel, none of
them can close it alone, and lesson 14 shows the shape that solves it.

## A channel with one direction

The types can carry that rule, so the compiler enforces it. `chan<- int` is a channel the holder
may only send on, and `<-chan int` one it may only receive from. A plain `chan int` converts to
either when passed to a function. Here a function meant only to drain a channel tries to send on
it, saved as `oops.go`:

```go
// Command oops sends on a channel its function was given only to receive from.
package main

func drain(in <-chan int) {
	in <- 1
}

func main() {}
```

```
ana@vm:~/channels$ go build oops.go
# command-line-arguments
./oops.go:5:2: invalid operation: cannot send to receive-only channel <-chan int in (variable of type <-chan int)
```

The compiler refused before anything ran, and named both the operation and the type. Writing
`<-chan int` in a signature costs nothing and makes the role of each function readable from its
first line: `split` in section 04 takes a `chan<- string` because it only sends and closes. **Only
the send-only side may close a directional channel**, which the compiler also checks, and which is
the rule above turned into types.
