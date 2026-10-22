---
title: Timeouts
version: 1
---

A receive with nobody sending waits forever, and lesson 4 showed how quietly that goes wrong. **A
timeout is one more case in a `select`: a channel that delivers a value when the time is up.**
`time.After(d)` returns exactly that, a channel on which one value arrives after `d`.

## One operation, one limit

The work takes 500 milliseconds and the caller will wait 200, saved as `timeout.go`:

```go
// Command timeout gives up on a slow result after 200 milliseconds.
package main

import (
	"fmt"
	"time"
)

func main() {
	start := time.Now()
	result := make(chan string, 1)
	go func() {
		time.Sleep(500 * time.Millisecond) // the slow work
		result <- "done"
	}()

	select {
	case r := <-result:
		fmt.Println("result:", r)
	case <-time.After(200 * time.Millisecond):
		fmt.Println("timed out")
	}
	fmt.Println("after", time.Since(start).Round(10*time.Millisecond))
}
```

```
ana@vm:~/select$ ./timeout
timed out
after 200ms
```

The work needed 500 milliseconds, the timer fired at 200, and the `select` took that case. **The
caller got its answer, `timed out`, on time.** Note that the slow goroutine was not stopped: it
went on sleeping, then sent `"done"` into a channel nobody would read. The buffer of one is what
lets it finish that send and return. Stopping the work itself, rather than only ceasing to wait for
it, is the job of the `context` package in lesson 10.

## A limit per step, or a limit for the whole

Where the `time.After` is written decides what it limits, and the difference is easy to miss. Five
results arrive 100 milliseconds apart. The first loop gives each receive 150 milliseconds; the
second gives the whole collection 350, saved as `budget.go`:

```go
// Command budget compares a timeout per receive with one deadline for all of them.
package main

import (
	"fmt"
	"time"
)

func results() <-chan int {
	out := make(chan int)
	go func() {
		for i := 1; i <= 5; i++ {
			time.Sleep(100 * time.Millisecond)
			out <- i
		}
		close(out)
	}()
	return out
}

func main() {
	start := time.Now()
	in := results()
	got := 0
perStep:
	for {
		select {
		case _, ok := <-in:
			if !ok {
				break perStep
			}
			got++
		case <-time.After(150 * time.Millisecond):
			break perStep
		}
	}
	fmt.Println("per step: got", got, "after", time.Since(start).Round(10*time.Millisecond))

	start = time.Now()
	in = results()
	got = 0
	deadline := time.After(350 * time.Millisecond)
overall:
	for {
		select {
		case _, ok := <-in:
			if !ok {
				break overall
			}
			got++
		case <-deadline:
			break overall
		}
	}
	fmt.Println("overall: got", got, "after", time.Since(start).Round(10*time.Millisecond))
}
```

```
ana@vm:~/select$ ./budget
per step: got 5 after 500ms
overall: got 3 after 350ms
```

The same five results, two different answers. **With `time.After` inside the loop, each pass of
the `select` creates a new 150-millisecond timer**, and every result arrived 100 milliseconds after
the one before, so no timer ever fired. All five came in, after 500 milliseconds, and a source
that sent one result every 140 milliseconds forever would never be timed out at all. **With the
timer made once, before the loop, it measures the whole collection**: three results by 350
milliseconds, then the deadline case ran and the loop ended.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"budget.go on a time line from 0 to 500 milliseconds. Results arrive at 100, 200, 300, 400 and 500. With a timeout of 150 milliseconds per receive, each window starts again after every result, no window expires, and all five arrive. With one deadline at 350 milliseconds for the whole loop, results 1 to 3 arrive and the deadline ends the loop before results 4 and 5.\"><defs><marker id=\"l05budget-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"60\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">results arrive</text><rect x=\"158.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"170.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">1</text><rect x=\"268.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"280.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">2</text><rect x=\"378.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"390.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">3</text><rect x=\"488.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"500.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">4</text><rect x=\"598.0\" y=\"34\" width=\"24\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"610.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">5</text><text x=\"60\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">time.After inside the loop: 150 ms per receive</text><rect x=\"60.0\" y=\"98\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"170.0\" y=\"112\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"280.0\" y=\"98\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"112\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"500.0\" y=\"98\" width=\"165.0\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"672\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">got 5</text><text x=\"60\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">time.After before the loop: 350 ms for all</text><rect x=\"60.0\" y=\"170\" width=\"385.0\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M445.0 30 V196\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"457.0\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">got 3</text><path d=\"M60 222 H630\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05budget-paper-dim)\"></path><path d=\"M60.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M170.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"170.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 ms</text><path d=\"M280.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"280.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200 ms</text><path d=\"M390.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"390.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300 ms</text><path d=\"M500.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"500.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400 ms</text><path d=\"M610.0 217 V227\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"610.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">500 ms</text><text x=\"445.0\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">350 ms</text></svg>", "caption": "Inside the loop, each receive starts a fresh 150 ms; before the loop, one 350 ms clock runs for the whole collection."}
```

Neither is wrong. A limit on each step suits "give up if the stream goes quiet"; a limit on the
whole suits "I have 350 milliseconds to answer my own caller". What matters is choosing on purpose,
and a request handler almost always means the second. Lesson 10 expresses that second kind with a
context deadline, which travels through every function the request calls.

The loops also use a label, `perStep:` and `overall:`. A plain `break` inside a `select` leaves the
`select`, not the `for` around it, so the labelled `break` is what ends the loop. Lesson 18 of `go`
covers labels.
