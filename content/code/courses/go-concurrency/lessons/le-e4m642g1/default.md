---
title: The default case, and the nil channel
version: 1
---

A `select` with a `default` case never waits. **If no other case can proceed at that instant,
`default` runs instead**, and the `select` is over. That turns any send or receive into a try: do it
if it can be done now, otherwise do something else.

## Trying without waiting

A common use is a send that must never hold up the sender, such as a progress update that is fine
to drop if nobody is listening yet. Here the channel has room for two and the sender offers five,
saved as `try.go`:

```go
// Command try offers five updates to a channel with room for two, without waiting.
package main

import "fmt"

func main() {
	updates := make(chan int, 2)
	for i := 1; i <= 5; i++ {
		select {
		case updates <- i:
			fmt.Println("queued", i)
		default:
			fmt.Println("dropped", i)
		}
	}
	close(updates)
	for u := range updates {
		fmt.Println("received", u)
	}
}
```

```
ana@vm:~/select$ ./try
queued 1
queued 2
dropped 3
dropped 4
dropped 5
received 1
received 2
```

The first two sends found room and were queued. The other three found the buffer full and, instead
of waiting, ran `default`. **Nothing blocked, ever**, and the receiver later got exactly the two
updates that fitted. Whether dropping is acceptable is a decision about the data: a progress
percentage can be dropped, an order cannot. A receive works the same way: `case v := <-ch` with a
`default` reads a value if one is there and otherwise goes on.

## A default in a loop is a busy loop

The temptation is to put a `select` with `default` in a `for` loop and "check now and then". The
loop then never waits for anything: it spins as fast as the processor allows. Two programs wait one
second for the same value, one with a blocking receive and one with `default` in a loop, saved as
`patient.go`:

```go
// Command patient waits one second for a value with a blocking receive.
package main

import (
	"fmt"
	"time"
)

func main() {
	ch := make(chan int)
	go func() {
		time.Sleep(time.Second)
		ch <- 1
	}()
	fmt.Println("got", <-ch)
}
```

and as `restless.go`:

```go
// Command restless waits one second for a value by polling with default.
package main

import (
	"fmt"
	"time"
)

func main() {
	ch := make(chan int)
	go func() {
		time.Sleep(time.Second)
		ch <- 1
	}()
	polls := 0
	for {
		select {
		case v := <-ch:
			fmt.Println("got", v, "after", polls, "polls")
			return
		default:
			polls++
		}
	}
}
```

```
ana@vm:~/select$ time ./patient
got 1

real	0m1.002s
user	0m0.003s
sys	0m0.000s
ana@vm:~/select$ time ./restless
got 1 after 316410547 polls

real	0m1.007s
user	0m0.994s
sys	0m0.009s
```

Both took one second of wall-clock time, the `real` line. The difference is in `user`, the time
the processor spent running the program: **3 milliseconds for the blocking receive, 994 for the
polling loop.** `restless` ran its `select` 316,410,547 times to find out what `patient` was told
for free, and kept one processor at full load the whole second. On a laptop that is a fan and a
battery; on a server, a processor taken from every other goroutine.

So `default` is for a single try, not for waiting. If the loop has nothing else to do, a plain
receive or a `select` without `default` waits without spending anything.

## A nil channel switches a case off

One more fact makes `select` complete. **A send or receive on a nil channel blocks forever**, so a
case on a nil channel can never be chosen. Setting a channel variable to `nil` is therefore the way
to switch one case off while the others carry on. Here two inputs finish at different times, and
each is set to `nil` when it closes, saved as `both.go`:

```go
// Command both drains two channels that close at different times.
package main

import "fmt"

func numbers(from, to int) <-chan int {
	out := make(chan int)
	go func() {
		for i := from; i <= to; i++ {
			out <- i
		}
		close(out)
	}()
	return out
}

func main() {
	a, b := numbers(1, 2), numbers(10, 14)
	for a != nil || b != nil {
		select {
		case v, ok := <-a:
			if !ok {
				fmt.Println("a closed")
				a = nil
				continue
			}
			fmt.Println("a", v)
		case v, ok := <-b:
			if !ok {
				fmt.Println("b closed")
				b = nil
				continue
			}
			fmt.Println("b", v)
		}
	}
}
```

```
ana@vm:~/select$ ./both
b 10
b 11
b 12
b 13
b 14
b closed
a 1
a 2
a closed
```

Every value of both inputs arrived, each close was reported once, and the loop ended when both
variables were `nil`. **Without the `a = nil`, a closed `a` would make its case ready forever**,
returning zero and `false` on every pass, and the loop would spin exactly like `restless`. With
it, the case drops out of the `select`, and the next pass waits only on `b`.

This run took all of `b` before any of `a`: both goroutines were ready, and the order the values
came in is the scheduler's choice, as always. Lesson 14 builds on this pattern to merge channels
whose number is not known in advance.
