---
title: How a goroutine is left behind
version: 1
---

A goroutine that is finished with its work returns, and the runtime takes back its stack. **A
goroutine that is blocked forever never returns, and nothing takes it back.** It holds its stack,
everything its variables point at, and a line in every count the runtime keeps. That is a
goroutine leak, and the program goes on working perfectly while it happens, which is why leaks are
found in production by a graph that only ever climbs.

Go has no way to stop a goroutine from outside. There is no handle to kill, and a goroutine ends
only by returning. So **every goroutine you start needs a way to finish that does not depend on
luck**, and the two programs below are the two commonest ways to forget one.

## A sender nobody listens to

The first program asks three servers the same question and keeps whichever answer comes back
first. The servers are pretend ones, a `time.Sleep` that grows with the server's number, so the
lesson needs no network. `runtime.NumGoroutine` reports how many goroutines exist at that moment,
`main` included. Saved as `first.go`:

```go
// Command first asks three slow servers and keeps the fastest answer.
package main

import (
	"fmt"
	"runtime"
	"time"
)

// ask stands in for a request to a server: server n takes n*10 ms to answer.
func ask(server int) string {
	time.Sleep(time.Duration(server) * 10 * time.Millisecond)
	return fmt.Sprint("answer from server ", server)
}

// first returns whichever answer arrives first.
func first() string {
	ch := make(chan string)
	for s := 1; s <= 3; s++ {
		go func() { ch <- ask(s) }()
	}
	return <-ch
}

func main() {
	fmt.Println(first())
	fmt.Println("goroutines at start:", runtime.NumGoroutine())
	for range 100 {
		first()
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines after 100 more calls:", runtime.NumGoroutine())
}
```

```
ana@vm:~/leaks$ go run first.go
answer from server 1
goroutines at start: 3
goroutines after 100 more calls: 203
```

The answer is right and fast, and the program is broken. **After one call there are already three
goroutines where there should be one**, and a hundred calls later there are 203. Each call to
`first` left two goroutines behind.

The reason is in `first`. It receives once, from an unbuffered channel, and returns. Server 1
answers after 10 milliseconds, its goroutine hands the string over, and `first` is gone. Servers 2
and 3 finish their sleep a little later and try to send on `ch`. An unbuffered send waits for a
receiver, lesson 4 showed, and the only receiver has returned. Nobody will ever read `ch` again, so
those two sends wait forever:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"One call to first. Three goroutines, servers 1, 2 and 3, send on the unbuffered channel ch. The function first receives the answer from server 1 and returns. Servers 2 and 3 reach their send afterwards, with no receiver left, and wait forever: two goroutines leaked per call.\"><defs><marker id=\"l06leak-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06leak-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">first()</text><text x=\"105\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">receives once, returns</text><rect x=\"270\" y=\"110\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ch</text><path d=\"M268 135 H192\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06leak-phosphor)\"></path><text x=\"325\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no receiver from here on</text><rect x=\"460\" y=\"40\" width=\"240\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">go func() { ch &lt;- ask(s) }</text><text x=\"580\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">after 10 ms: sent, returned</text><path d=\"M458 67 L382 135\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06leak-phosphor)\"></path><rect x=\"460\" y=\"125\" width=\"240\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">go func() { ch &lt;- ask(s) }</text><text x=\"580\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">after 20 ms: blocked on send</text><path d=\"M458 152 L382 135\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#l06leak-amber)\"></path><rect x=\"460\" y=\"210\" width=\"240\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">go func() { ch &lt;- ask(s) }</text><text x=\"580\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">after 30 ms: blocked on send</text><path d=\"M458 237 L382 135\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#l06leak-amber)\"></path><rect x=\"20\" y=\"222\" width=\"360\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"200\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">two goroutines that never return</text></svg>", "caption": "One call to first: the fastest answer is taken, and the two slower senders wait on a channel nobody will read again."}
```

## A receiver nobody closes

The mirror image is a goroutine waiting to receive. The second program hands lines of text to a
helper goroutine, which stands in for one that writes a log. A `for range` over a channel ends when
the channel is closed, as lesson 3 showed, and `process` closes it at the end. Saved as `early.go`:

```go
// Command early hands lines to a helper goroutine and gives up on a bad one.
package main

import (
	"errors"
	"fmt"
	"runtime"
	"time"
)

// process sends each line to a goroutine that counts characters,
// as a stand-in for one that writes a log.
func process(lines []string) error {
	logs := make(chan string)
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
	close(logs)
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
ana@vm:~/leaks$ go run early.go
goroutines after 100 calls: 51
```

A hundred calls, half of them with an empty line, and 51 goroutines: `main` and fifty helpers.
**Every call that returned early left its helper behind**, because the early `return` skips
`close(logs)`, and a `for range` over a channel that is never closed waits forever. The fifty calls
that reached the end closed the channel and their helpers finished.

This is the shape of most real leaks. The happy path is correct, somebody added an error check
months later, and the new `return` jumped over the line that let the goroutine go. Nothing failed;
the count went up by one per error.

## What a leak costs

A blocked goroutine uses no processor. What it holds is memory: its stack, which starts at a few
kilobytes and grows with what it was doing, and anything its variables still reach, which the
garbage collector cannot free while the goroutine exists. Here, the strings from `ask` and the
slice of lines. A leak of two goroutines per request is invisible in a test and, at a few hundred
requests a second, is a service that runs out of memory over a weekend.
