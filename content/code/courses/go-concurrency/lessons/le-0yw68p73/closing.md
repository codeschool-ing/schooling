---
title: Closing the merged channel
version: 1
---

A merge has one question that is easy to get wrong in both directions: **when to close the
output.** Close it too early and a copier that is still running sends on a closed channel. Never
close it and whoever ranges over the output waits for ever. Both mistakes look reasonable in code,
and both have an exact message.

## Too early

The obvious place for `close(out)` is right after a copier's loop, where the input it was copying
has just closed. The program below does that, with a fast input of one reading and a slow one of
three. It is saved in `~/fanin/early` as `early.go`:

```go
// Command early closes the merged channel as soon as the first input is done.
package main

import (
	"fmt"
	"time"
)

func source(name string, n int, gap time.Duration) <-chan string {
	out := make(chan string)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			time.Sleep(gap)
			out <- fmt.Sprintf("%s-%d", name, i)
		}
	}()
	return out
}

func merge(inputs ...<-chan string) <-chan string {
	out := make(chan string)
	for _, in := range inputs {
		go func() {
			for v := range in {
				out <- v
			}
			close(out) // wrong: the other inputs may still be sending
		}()
	}
	return out
}

func main() {
	all := merge(source("fast", 1, 10*time.Millisecond), source("slow", 3, 20*time.Millisecond))
	for reading := range all {
		fmt.Println(reading)
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("main is done")
}
```

```
ana@vm:~/fanin$ go run ./early
slow-1
fast-1
panic: send on closed channel

goroutine 38 [running]:
main.merge.func1()
	/home/ana/fanin/early/early.go:26 +0x51
created by main.merge in goroutine 1
	/home/ana/fanin/early/early.go:24 +0x45
exit status 2
```

The copier of the fast input finished first and closed `out`. The copier of the slow input was
still running, and its next send, line 26 of `early.go`, `out <- v`, hit a closed channel. **A
send on a closed channel panics**, as lesson 3 showed, and a panic in any goroutine ends the whole
program. The two lines under `goroutine 38` say which goroutine it was, and where `merge` started
it, at line 24. Whichever copier happens to finish first, the result is the same, because one
copier cannot know the others are done.

## Never

The opposite mistake is to leave `close` out altogether. Every input closes properly, the copiers
finish, and the output stays open. It is saved in `~/fanin/never` as `never.go`:

```go
// Command never merges two inputs and never closes the result.
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

func merge(inputs ...<-chan int) <-chan int {
	out := make(chan int)
	for _, in := range inputs {
		go func() {
			for v := range in {
				out <- v
			}
		}()
	}
	return out
}

func main() {
	for v := range merge(numbers(1, 2), numbers(10, 2)) {
		fmt.Println(v)
	}
	fmt.Println("done")
}
```

```
ana@vm:~/fanin$ go run ./never
1
2
10
11
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan receive]:
main.main()
	/home/ana/fanin/never/never.go:30 +0xba
exit status 2
```

All four values arrived. Then `main` went back to its `range` at line 30 for a fifth, the copiers
had returned, and nothing else in the program could ever send. The runtime noticed that every
goroutine was blocked and stopped the program with the deadlock message of lesson 4, naming the
one goroutine left and what it was waiting for: `chan receive`.

**Here the runtime caught it because `main` was the only goroutine left.** In a server, where other
goroutines are always alive, the same mistake raises nothing: the goroutine ranging over the
output simply waits for ever, which is a leak in lesson 6's sense, found only by counting
goroutines.

## The rule

The output of a merge is closed exactly once, by the code that knows every sender has finished.
In section 02 that was a goroutine waiting on a `WaitGroup` that the copiers count down. In the
`select` merge of section 03 there is no output channel to close, because the loop is the
consumer. Both follow lesson 3's rule, that the sender closes, extended to a channel with several
senders: **the last sender closes, and only something that counts them knows which one is last.**
