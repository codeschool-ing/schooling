---
title: Stages joined by channels
version: 1
---

**A pipeline is a chain of stages, each a goroutine that receives values from the stage before it
and sends results to the stage after it**, joined by channels. Lessons 13 and 14 spread one stream
over many goroutines and merged many into one. A pipeline is the third shape: a stream that passes
through several steps in order, every step working at the same time on a different item.

Each stage in Go has the same signature shape: it takes the channel it reads from and returns the
channel it writes to, having started the goroutine that connects them. That shape is what lets
stages be chained by calling one with the result of another. The program below has a first stage,
`gen`, that turns a list into a channel, and a middle stage, `sq`, that squares. It is saved in
`~/pipeline/squares` as `squares.go`:

```go
// Command squares chains three stages, each a goroutine joined to the next by a channel.
package main

import "fmt"

// gen is the first stage: it turns a list into a channel.
func gen(nums ...int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for _, n := range nums {
			out <- n
		}
	}()
	return out
}

// sq is a middle stage: it receives numbers and sends their squares.
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
	for v := range sq(gen(1, 2, 3, 4)) {
		fmt.Println(v)
	}
	for v := range sq(sq(gen(1, 2, 3))) {
		fmt.Println("twice:", v)
	}
}
```

```
ana@vm:~/pipeline$ go run ./squares
1
4
9
16
twice: 1
twice: 16
twice: 81
```

`sq(gen(1, 2, 3, 4))` reads inside out: `gen` produces 1 to 4, `sq` squares them, and `main`, the
last stage, ranges over the result. **Because a stage's input and output are the same type, a
stage can be used twice**: `sq(sq(gen(1, 2, 3)))` raised each number to the fourth power, 1, 16
and 81, with no new code. Each call started one more goroutine and one more channel.

## Every stage works at once

Chaining functions is not new. What the goroutines add is that **all the stages run at the same
time**, each on a different item: while the second stage handles item 1, the first is already
producing item 2. The program below has two stages that each take 20 milliseconds per item, five
items, and timestamps on every step. It is saved in `~/pipeline/overlap` as `overlap.go`:

```go
// Command overlap times five items through two slow stages.
package main

import (
	"fmt"
	"time"
)

var start = time.Now()

func stamp() time.Duration { return time.Since(start).Round(10 * time.Millisecond) }

// read takes 20ms to produce each item.
func read(n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			time.Sleep(20 * time.Millisecond)
			fmt.Printf("%5v  read   item %d\n", stamp(), i)
			out <- i
		}
	}()
	return out
}

// store takes 20ms to handle each item.
func store(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := range in {
			time.Sleep(20 * time.Millisecond)
			fmt.Printf("%5v  stored item %d\n", stamp(), i)
			out <- i
		}
	}()
	return out
}

func main() {
	done := 0
	for range store(read(5)) {
		done++
	}
	fmt.Printf("%d items, 200ms of work, finished at %v\n", done, stamp())
}
```

```
ana@vm:~/pipeline$ go run ./overlap
 20ms  read   item 1
 40ms  stored item 1
 40ms  read   item 2
 60ms  stored item 2
 60ms  read   item 3
 80ms  stored item 3
 80ms  read   item 4
100ms  stored item 4
100ms  read   item 5
120ms  stored item 5
5 items, 200ms of work, finished at 120ms
```

Ten steps of 20 milliseconds is 200 milliseconds of work, and it finished at 120. From 40
milliseconds on, every line is paired: an item stored and the next one read at the same instant,
the two stages busy together. **The time a pipeline takes is set by its slowest stage, repeated
once per item, plus the time to fill it**: here 20 milliseconds per item for five items, plus the
20 the first read took before `store` had anything to do.

That also says where to spend effort. Speeding up a stage that is not the slowest changes nothing
the clock can see; section 03 widens the slow one instead.
