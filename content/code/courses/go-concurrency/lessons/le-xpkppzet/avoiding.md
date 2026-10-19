---
title: Giving every goroutine a way out
version: 1
---

Finding leaks is the fallback. **The rule that prevents them is ownership: whoever starts a
goroutine decides how it will end, at the moment of starting it**, and writes that down in the code
rather than hoping. In practice the answer is one of three: the goroutine's work has a natural end
that cannot block, somebody closes the channel it reads, or it is told to stop. The two leaks of
section 02 each take one of them.

## Room for every answer

`first.go` leaked because two senders had nobody to receive from them. If the channel has room for
every answer, no send ever waits. Three servers, three places in the buffer, and the senders that
lose the race drop their answer into the buffer and return. The buffer is collected with the
channel once nobody refers to it. Saved as `buffered.go`:

```go
// Command buffered is first.go with room in the channel for every answer.
package main

import (
	"fmt"
	"runtime"
	"time"
)

func ask(server int) string {
	time.Sleep(time.Duration(server) * 10 * time.Millisecond)
	return fmt.Sprint("answer from server ", server)
}

func first() string {
	const servers = 3
	ch := make(chan string, servers)
	for s := 1; s <= servers; s++ {
		go func() { ch <- ask(s) }()
	}
	return <-ch
}

func main() {
	for range 100 {
		first()
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines after 100 calls:", runtime.NumGoroutine())
}
```

```
ana@vm:~/leaks$ go run buffered.go
goroutines after 100 calls: 1
```

One goroutine, `main`, after a hundred calls. **The only change is the `3` in `make`**, written as
a constant beside the loop it has to match. That coupling is the fragile part: somebody adds a
fourth server, forgets the buffer, and the leak is back at one goroutine per call. Lesson 4 is the
whole subject of buffers.

## Close on every path

`early.go` leaked because one path skipped `close(logs)`. **`defer` runs on every way out of a
function**, the early `return` included, so a `close` deferred right after `make` cannot be
skipped. Saved as `done.go`:

```go
// Command done is early.go with a way for the helper goroutine to hear that it is over.
package main

import (
	"errors"
	"fmt"
	"runtime"
	"time"
)

func process(lines []string) error {
	logs := make(chan string)
	defer close(logs)
	go func() {
		chars := 0
		for l := range logs {
			chars += len(l)
		}
		_ = chars
	}()
	for _, l := range lines {
		if l == "" {
			return errors.New("empty line")
		}
		logs <- l
	}
	return nil
}

func main() {
	good := []string{"one", "two", "three"}
	bad := []string{"one", "", "three"}
	for range 50 {
		process(good)
		process(bad)
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines after 100 calls:", runtime.NumGoroutine())
}
```

```
ana@vm:~/leaks$ go run done.go
goroutines after 100 calls: 1
```

`defer close(logs)` sits two lines after the channel is made and the explicit `close` at the end is
gone. Both paths now close the channel, both helpers see their `for range` end, and the count stays
at one.

## Told to stop

The third way out is for the goroutine to listen for a signal as well as for its work. The classic
form in Go is a channel called `done` that the owner closes when it no longer wants anything; a
`select`, the subject of lesson 5, waits on the send and on `done` together, and whichever is ready
first wins. A closed channel is ready for every receiver at once, so one `close` stops any number of
goroutines. Lesson 10's `context` package is this pattern with a standard name, a deadline and a
reason attached, and from lesson 10 on the course uses it instead of a hand-made `done`.

## A checklist for every `go` statement

Before writing `go`, answer three questions, and if one has no answer the goroutine can leak:

1. **What does it block on?** A send, a receive, a lock, a `Wait`.
2. **Who makes that operation complete?** A receiver that is certain to be there, a `close` that
   runs on every path, a buffer with room.
3. **What happens if the caller gives up early?** An error, a timeout, a panic: does the goroutine
   still have a way out?
