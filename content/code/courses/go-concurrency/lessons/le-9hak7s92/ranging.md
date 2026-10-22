---
title: Ranging over a channel
version: 1
---

A receiver that does not know how many values are coming wants a loop that takes them until the
sender says it is done. **`for v := range ch` is that loop: it receives until the channel is closed
and empty, then ends.** It is the two-value receive of section 03, with the `ok` check written for
you.

## A producer and a consumer

`split` sends every word of a text and then closes the channel; `main` ranges over it, saved as
`words.go`:

```go
// Command words sends some words on a channel and ranges over them.
package main

import (
	"fmt"
	"strings"
)

func split(text string, out chan<- string) {
	for _, w := range strings.Fields(text) {
		out <- w
	}
	close(out)
}

func main() {
	words := make(chan string)
	go split("share memory by communicating", words)
	for w := range words {
		fmt.Println(len(w), w)
	}
	fmt.Println("the channel is closed and drained")
}
```

```
ana@vm:~/channels$ go run words.go
5 share
6 memory
2 by
13 communicating
the channel is closed and drained
```

Four words, then the line after the loop. **The loop ended because `split` closed the channel**,
and it ended only after the last word had been received: a close never overtakes values already
sent. `split` takes a `chan<- string`, so it can send and close and nothing else, while `main`
holds the plain channel it made.

This is the commonest shape a channel takes in real code: one goroutine produces, another consumes,
and the producer's `close` is the end-of-data marker. It is the seed of the pipelines in lesson 15,
where each stage ranges over the channel before it and closes the one after it.

## Forgetting to close

The loop ends only because `split` closed the channel. Deleting that one line, with `sed`, gives a
program that receives the same four words and then waits for a fifth that nobody will send:

```
ana@vm:~/channels$ sed '/close(out)/d' words.go > forgot.go
ana@vm:~/channels$ go run forgot.go
5 share
6 memory
2 by
13 communicating
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan receive]:
main.main()
	/home/ana/channels/forgot.go:18 +0x10a
exit status 2
```

**The words still came through; the loop just never ended.** After `communicating`, `main` waited
for a fifth value, `split` had returned, and no goroutine was left that could ever send. The
runtime noticed that every goroutine in the program was blocked and stopped it with `fatal error:
all goroutines are asleep - deadlock!`, naming `main` as stuck in `[chan receive]` at line 18,
which is the `range`.

That rescue happens only because every goroutine was stuck. In a program where some other
goroutine is still alive, say a server waiting for connections, the same forgotten `close` leaves
the ranging goroutine waiting forever with no message at all. Lesson 4 looks at the fatal error
closely, and lesson 6 at the silent version, which is a leak.

Two rules follow, and they are the whole of ranging. **The sender closes when it has nothing more
to send. A receiver that ranges trusts that it will.**
