---
title: Waiting on several channels at once
version: 1
---

Every receive so far waited on one channel. A program asking two servers the same question wants
whichever answer comes first, and a receive on the first server's channel would sit there even
while the second server's answer was already waiting. **`select` waits on several channel
operations at once and performs the first one that can proceed.** It looks like a `switch`, and
each `case` is a send or a receive.

## The first answer wins

Two goroutines stand in for two servers: one answers after 120 milliseconds, the other after 80.
`main` takes whichever answer arrives first, saved as `first.go`:

```go
// Command first asks two slow sources and takes whichever answers first.
package main

import (
	"fmt"
	"time"
)

func ask(name string, delay time.Duration, out chan<- string) {
	time.Sleep(delay)
	out <- name
}

func main() {
	start := time.Now()
	primary := make(chan string, 1)
	mirror := make(chan string, 1)
	go ask("primary", 120*time.Millisecond, primary)
	go ask("mirror", 80*time.Millisecond, mirror)

	select {
	case v := <-primary:
		fmt.Println("answer from", v)
	case v := <-mirror:
		fmt.Println("answer from", v)
	}
	fmt.Println("after", time.Since(start).Round(10*time.Millisecond))
}
```

```
ana@vm:~/select$ ./first
answer from mirror
after 80ms
```

`answer from mirror`, after 80 milliseconds: the `select` waited on both receives, and the moment
the mirror's value arrived, that case ran and the `select` ended. **The other case was simply not
taken.** The primary's answer arrived 40 milliseconds later into a channel nobody read again. That
is why both channels have room for one value: the losing goroutine can complete its send and
return instead of waiting forever for a receiver that has moved on, which is the leak lesson 4
ended on. Lesson 6 makes that a rule.

A `select` with no case ready blocks until one is, exactly like a single receive. **It blocks on
all of them at once**, and the first to become possible wins.

## When more than one is ready

If several cases can proceed at the moment `select` runs, it does not take the first one written.
**It picks one of the ready cases at random**, uniformly. This program keeps two channels full and
runs `select` ten thousand times, counting which case it took, saved as `fair.go`:

```go
// Command fair counts which case select picks when both are always ready.
package main

import "fmt"

func main() {
	a := make(chan int, 1)
	b := make(chan int, 1)
	counts := map[string]int{}
	for range 10_000 {
		a <- 1
		b <- 1
		select {
		case <-a:
			counts["a"]++
			<-b
		case <-b:
			counts["b"]++
			<-a
		}
	}
	fmt.Println(counts)
}
```

```
ana@vm:~/select$ ./fair
map[a:4932 b:5068]
ana@vm:~/select$ ./fair
map[a:5004 b:4996]
```

Two runs, two splits, each close to half: 4932 against 5068, then 5004 against 4996. Both cases were
ready every time, and the runtime chose between them at random. **That randomness is deliberate:
if `select` always preferred the first case written, a busy first channel could starve the second
forever.** It also means you cannot give one case priority by writing it first. A program that
needs a priority checks the important channel in a `select` of its own, with a `default`, before
the general one; section 04 shows the `default` case.
