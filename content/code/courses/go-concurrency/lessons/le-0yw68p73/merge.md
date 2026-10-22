---
title: Merging channels into one
version: 1
---

Fan-out, in lesson 13, sent one stream to many goroutines. **Fan-in is the opposite: many channels
merged into one**, so that a single loop can read whatever any of them produces, in the order it
arrives. It is how a program listens to several sources at once without knowing in advance which
will speak next: three sensors, several replicas of a service, the workers of a fan-out sending
their results home.

The shape is one goroutine per input, each copying its input onto a shared output, and one more
goroutine that closes the output when every copier is done. The program below merges three sources
that produce at different rates. It is saved in `~/fanin/merge` as `merge.go`:

```go
// Command merge reads three sources through one channel.
package main

import (
	"fmt"
	"sync"
	"time"
)

// source sends n readings named after it, one every gap, then closes its channel.
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

// merge copies every value of every input onto one output, and closes it when all inputs are done.
func merge[T any](inputs ...<-chan T) <-chan T {
	out := make(chan T)
	var wg sync.WaitGroup
	for _, in := range inputs {
		wg.Go(func() {
			for v := range in {
				out <- v
			}
		})
	}
	go func() {
		wg.Wait()
		close(out)
	}()
	return out
}

func main() {
	start := time.Now()
	all := merge(
		source("disk", 3, 30*time.Millisecond),
		source("net", 4, 20*time.Millisecond),
		source("cpu", 2, 50*time.Millisecond),
	)
	for reading := range all {
		fmt.Printf("%5v  %s\n", time.Since(start).Round(10*time.Millisecond), reading)
	}
	fmt.Println("all sources closed")
}
```

```
ana@vm:~/fanin$ go run ./merge
 20ms  net-1
 30ms  disk-1
 40ms  net-2
 50ms  cpu-1
 60ms  net-3
 60ms  disk-2
 80ms  net-4
 90ms  disk-3
100ms  cpu-2
all sources closed
```

Nine readings arrived on one channel, in time order: `net` every 20 milliseconds, `disk` every
30, `cpu` every 50. **`main` never mentions the three sources by name**; it ranges over one
channel and receives from whichever source produced last. And its loop ended by itself, printing
`all sources closed`, because the merged channel was closed at the right moment.

`merge` is generic, `[T any]`, as lesson 31 of `go` showed for functions: it copies values of any
type, and nothing in it depends on the readings being strings. Each input gets a goroutine of its
own because each might block at any moment, waiting for its source, and one goroutine waiting on
one input must not hold up the others.

The part that decides whether `merge` is correct is the last goroutine it starts:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"How merge in merge.go closes its output. Three input channels, disk, net and cpu, each read by a copier goroutine of its own that sends every value onto the single output channel out. Each copier calls Done on a WaitGroup when its input closes. A fourth goroutine waits on the WaitGroup and closes out only after all three copiers are done; main ranges over out until that close.\"><defs><marker id=\"l14merge-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14merge-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l14merge-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">disk</text><rect x=\"180\" y=\"40\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copier</text><path d=\"M112 58 H177\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-wire)\"></path><path d=\"M312 58 L417 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-phosphor)\"></path><rect x=\"20\" y=\"110\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">net</text><rect x=\"180\" y=\"110\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copier</text><path d=\"M112 128 H177\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-wire)\"></path><path d=\"M312 128 L417 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-phosphor)\"></path><rect x=\"20\" y=\"180\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cpu</text><rect x=\"180\" y=\"180\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copier</text><path d=\"M112 198 H177\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-wire)\"></path><path d=\"M312 198 L417 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-phosphor)\"></path><rect x=\"420\" y=\"110\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">out</text><rect x=\"560\" y=\"110\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"630\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ranges until out closes</text><path d=\"M512 128 H557\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-phosphor)\"></path><text x=\"310\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Done() when its input closes</text><path d=\"M245 218 V244\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"330\" y=\"240\" width=\"270\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">waits for all three, then close(out)</text><path d=\"M465 238 V149\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-amber)\"></path><path d=\"M314 260 H327\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14merge-wire)\"></path></svg>", "caption": "merge.go's merge. Only the goroutine that knows every copier has finished may close the output."}
```

**The output may be closed only when nothing will send on it again**, and with three copiers that
means when all three have finished. No copier can know that about the others, so none of them
closes it. The `WaitGroup` counts them, and a separate goroutine waits for the count to reach zero
and then calls `close(out)`. It has to be a separate goroutine: if `merge` itself called
`wg.Wait()`, it would block before returning `out`, and nobody would be reading `out` for the
copiers to send to. Section 04 shows the two ways people get this wrong.
