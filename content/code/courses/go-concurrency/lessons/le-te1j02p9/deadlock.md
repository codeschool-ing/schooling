---
title: Deadlock, loud and quiet
version: 1
---

The rule of section 02 has a consequence that bites everybody once. **A send on an unbuffered
channel, with no other goroutine ready to receive, waits forever**, and so does a receive with no
sender. When that leaves every goroutine in the program waiting, nothing can ever move again: that
is a deadlock.

## The loud kind

The shortest version sends and receives in the same goroutine, saved as `stuck.go`:

```go
// Command stuck sends on an unbuffered channel with nobody to receive.
package main

import "fmt"

func main() {
	ch := make(chan int)
	ch <- 42
	fmt.Println(<-ch)
}
```

```
ana@vm:~/buffers$ go run stuck.go
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan send]:
main.main()
	/home/ana/buffers/stuck.go:8 +0x36
exit status 2
ana@vm:~/buffers$ go vet stuck.go && echo "vet: no complaint"
vet: no complaint
ana@vm:~/buffers$ sed 's/make(chan int)/make(chan int, 1)/' stuck.go > stuck-fixed.go
ana@vm:~/buffers$ go run stuck-fixed.go
42
```

`main` sends on an unbuffered channel, and the only goroutine that could receive is `main` itself,
which is busy sending. Nothing will ever move, and the runtime noticed: **`fatal error: all
goroutines are asleep - deadlock!`**, goroutine 1 in state `[chan send]`, at line 8, which is
`ch <- 42`. The bracketed state is worth reading in any such report; it says what the goroutine was
waiting to do.

`go vet` passed the file, because this is not something a program's text reliably shows: it depends
on which goroutines exist when the send runs. A buffer of one is enough to repair this particular
program, and the transcript makes that change with `sed`: the send now has room, returns at once,
and the receive takes the value. **That repair works because exactly one value is sent before the
receive.** Send two, and the second blocks exactly as before. A buffer moves the point where a
program deadlocks; it does not decide whether it does.

## The quiet kind

The runtime's check has a condition, and the condition is the trap: it fires only when **every**
goroutine is blocked. Here one goroutine is stuck exactly as `stuck.go` was, while `main` stays busy
with something else and then returns normally, saved as `partial.go`:

```go
// Command partial leaves one goroutine stuck on a send while main carries on.
package main

import (
	"fmt"
	"runtime"
	"time"
)

func main() {
	results := make(chan int)
	go func() {
		results <- 42 // nobody will ever receive this
	}()

	for i := 1; i <= 3; i++ {
		time.Sleep(100 * time.Millisecond)
		fmt.Println("main still working, goroutines alive:", runtime.NumGoroutine())
	}
	fmt.Println("main returns")
}
```

```
ana@vm:~/buffers$ go run partial.go; echo "exit status: $?"
main still working, goroutines alive: 2
main still working, goroutines alive: 2
main still working, goroutines alive: 2
main returns
exit status: 0
```

No error, exit status 0. **The goroutine was stuck from its first instant to the last**,
`NumGoroutine` counted it three times, and nothing anywhere reported it, because `main` was never
blocked: it was sleeping, which counts as a goroutine that may yet move. When `main` returned, the
stuck goroutine was simply discarded with the process.

In a program that returns after a second that costs nothing. In a server that runs for months, a
goroutine stuck like this on every request is a goroutine leak: memory that grows until the process
is killed, with no message at any point. **The loud deadlock is the lucky one.** Lesson 6 is about
the quiet one: how it happens, how to find it, and the patterns that prevent it.
