---
title: What Go promises, and what it does not
version: 1
---

A program with goroutines is a program whose steps no longer come in one fixed order, and the
first instinct is to read whatever order you see as the order there is. **Go promises very little
about the order in which goroutines run, and a great deal about what happens when they
synchronise.** Telling those two apart is most of this course.

## Order is not promised

`order.go`, from section 02, starts three goroutines that each print a line. Built once and run
five times:

```
ana@vm:~/promise$ go build -o order order.go
ana@vm:~/promise$ for i in 1 2 3 4 5; do ./order | paste -sd " "; done
hello from caio hello from bia hello from ana
hello from caio hello from ana hello from bia
hello from caio hello from ana hello from bia
hello from caio hello from ana hello from bia
hello from caio hello from ana hello from bia
```

`paste -sd " "` joins each run's three lines into one, so each line above is one run. Four of the
five agree, and the loop started `ana` first, yet `caio` printed first every time. That is the
runtime's scheduler at work: the goroutine created last waits in a slot of its own and tends to run
first when `main` stops to wait. Lesson 2 opens the scheduler up. In section 02 the same program,
built with the race detector, printed `ana`, `bia`, `caio`.

**None of those orders is part of the language.** A different release, a busier machine or a
different `GOMAXPROCS` changes them, and a program whose correctness depends on any of them works
until the day it does not. If the order matters, the program has to say so, with a channel or a
lock, which is what lessons 3 and 8 are for.

## Shared memory without a rule is a race

The second program has four goroutines add one to the same variable, a hundred thousand times
each, saved as `count.go`:

```go
// Command count adds one to a shared number from four goroutines at once.
package main

import (
	"fmt"
	"sync"
)

func main() {
	total := 0
	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() {
			for range 100_000 {
				total++
			}
		})
	}
	wg.Wait()
	fmt.Println("total:", total)
}
```

Four goroutines times a hundred thousand is 400,000. Five runs:

```
ana@vm:~/promise$ go build -o count count.go
ana@vm:~/promise$ for i in 1 2 3 4 5; do ./count; done
total: 281276
total: 400000
total: 351796
total: 341664
total: 197620
```

Four wrong answers and one right one, and **the right one is the most dangerous line on the
screen**. A test that ran once and got 400,000 would have passed, and the program would have shipped
with the defect inside it.

The cause is that `total++` is not one step. It reads the number, adds one, and writes the result
back, and between the read and the write another goroutine can do the same:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A lost update, step by step. total holds 7. Goroutine 10 reads 7, then goroutine 11 reads 7. Goroutine 10 adds one and writes 8. Goroutine 11 adds one to the 7 it read and writes 8 as well. Two increments happened and total went up by one.\"><defs><marker id=\"l01lost-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01lost-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"130\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">goroutine 10</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">total, in memory</text><text x=\"590\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">goroutine 11</text><rect x=\"330\" y=\"55\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">7</text><rect x=\"50\" y=\"55\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reads 7</text><path d=\"M328 70 H212\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01lost-phosphor)\"></path><rect x=\"330\" y=\"105\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">7</text><rect x=\"510\" y=\"105\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reads 7</text><path d=\"M392 120 H508\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01lost-phosphor)\"></path><rect x=\"330\" y=\"155\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">8</text><rect x=\"50\" y=\"155\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">writes 8</text><path d=\"M210 170 H328\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01lost-amber)\"></path><rect x=\"330\" y=\"205\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">8</text><rect x=\"510\" y=\"205\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">writes 8</text><path d=\"M510 220 H392\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01lost-amber)\"></path><rect x=\"220\" y=\"252\" width=\"280\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"267\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">two increments, one lost</text></svg>", "caption": "total++ is a read, an addition and a write. Two goroutines interleaving those three steps lose one increment."}
```

This is a **data race**: two goroutines touch the same memory at the same time, at least one of
them writes, and nothing orders the two. Go's memory model, the document that says what a program
may assume about memory shared between goroutines, gives a program with a data race no answer you
can rely on. The totals above are what that looks like.

## What Go does promise

Go's promises are about **synchronisation**. When one goroutine hands a value to another through a
channel, everything the first did before the send is visible to the second after the receive. When
a lock is released and taken again, everything done before the release is visible after the take.
When `wg.Wait` returns, everything the waited goroutines did is visible to whoever waited. That is
why reading `total` after `wg.Wait` is safe. The increments racing each other, inside the
goroutines, are the problem.

The Go proverb for this is *do not communicate by sharing memory; instead, share memory by
communicating*. Lessons 3 to 7 are the communicating; lessons 8 and 9 are the locks, for when
sharing is simpler.

And one promise is a tool rather than a rule. **The race detector reports a data race that happens
while it is watching**, with the two places in the source that collided:

```
ana@vm:~/promise$ go run -race count.go
==================
WARNING: DATA RACE
Read at 0x00c000018108 by goroutine 11:
  main.main.func1()
      /home/ana/promise/count.go:15 +0x37

Previous write at 0x00c000018108 by goroutine 10:
  main.main.func1()
      /home/ana/promise/count.go:15 +0x49

Goroutine 11 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72

Goroutine 10 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
==================
==================
WARNING: DATA RACE
Write at 0x00c000018108 by goroutine 11:
  main.main.func1()
      /home/ana/promise/count.go:15 +0x49

Previous write at 0x00c000018108 by goroutine 10:
  main.main.func1()
      /home/ana/promise/count.go:15 +0x49

Goroutine 11 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72

Goroutine 10 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
==================
total: 353574
Found 2 data race(s)
exit status 66
```

Two reports, both pointing at line 15 of `count.go`, which is `total++`: a read by goroutine 11
after a write by goroutine 10, then a write after a write. The program still printed a wrong total,
because the detector reports rather than repairs, and it exited with status 66 to make a script
notice. **It sees only the races that happen in the run it watches**, so a race on a path the run
never took goes unreported. Lesson 16 reads these reports line by line and fixes what they find.
