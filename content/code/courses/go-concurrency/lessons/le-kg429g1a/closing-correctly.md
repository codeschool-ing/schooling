---
title: Closing, stage by stage
version: 1
---

Every stage in section 02 ended its goroutine with `defer close(out)`, and every stage but the
first read its input with `range`. Those two habits together are the whole of how a pipeline
shuts down: **each stage closes the channel it sends on, after its input has closed**, and the
close travels down the chain one stage at a time. No stage needs to know how many stages there
are, or how many items.

The program below is section 02's pipeline with a line printed at each close. It is saved in
`~/pipeline/cascade` as `cascade.go`:

```go
// Command cascade shows each stage closing its output after its input closed.
package main

import "fmt"

func gen(nums ...int) <-chan int {
	out := make(chan int)
	go func() {
		defer func() { fmt.Println("gen: no more numbers, closing"); close(out) }()
		for _, n := range nums {
			out <- n
		}
	}()
	return out
}

func sq(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer func() { fmt.Println("sq:  input closed, closing"); close(out) }()
		for n := range in {
			out <- n * n
		}
	}()
	return out
}

func main() {
	for v := range sq(gen(1, 2)) {
		fmt.Println("main:", v)
	}
	fmt.Println("main: range over")
}
```

```
ana@vm:~/pipeline$ go run ./cascade
gen: no more numbers, closing
main: 1
main: 4
sq:  input closed, closing
main: range over
```

The closes came in pipeline order, `gen` and then `sq`, and `main`'s `range` ended last. `gen`'s
line printed before `main` had printed anything, and nothing is wrong with that: `gen` handed over
its second number as soon as `sq` took it and closed straight away, while `sq` and `main` were
still passing the squares along. **The order of lines from different goroutines is the order they
reached `Println`, not the order of the data**, as lesson 1 showed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A pipeline of three stages, gen, sq and main, joined by two channels. Values flow left to right. Closing flows the same way: gen closes its output when it has no more numbers; sq&#x27;s range over that channel then ends, and sq closes its own output; main&#x27;s range over it then ends. Cancellation is the other direction: when main stops early, a context tells gen and sq to stop sending.\"><defs><marker id=\"l15cascade-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15cascade-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15cascade-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">gen</text><rect x=\"290\" y=\"70\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sq</text><rect x=\"550\" y=\"70\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main</text><path d=\"M172 95 H287\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15cascade-phosphor)\"></path><text x=\"230\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">chan int</text><path d=\"M432 95 H547\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15cascade-phosphor)\"></path><text x=\"490\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">chan int</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">values</text><path d=\"M300 44 H420\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15cascade-phosphor)\"></path><text x=\"100\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1. no more numbers: close</text><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">2. range ends: close</text><text x=\"620\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">3. range ends</text><path d=\"M190 146 H262\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15cascade-amber)\"></path><path d=\"M450 146 H530\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15cascade-amber)\"></path><rect x=\"30\" y=\"196\" width=\"660\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">stopping early goes the other way: ctx.Done() in every send</text><path d=\"M620 192 V180 H100 V172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l15cascade-paper-dim)\"></path></svg>", "caption": "The close travels with the data, one stage at a time; each stage closes only the channel it sends on."}
```

Three rules make the cascade work, and each one is a failure of lesson 14 when broken:

- **A stage closes only its own output.** Closing its input would be a receiver closing a channel
  somebody else sends on: the `send on closed channel` panic.
- **It closes after its input is exhausted**, which `range` plus `defer close(out)` gives for
  free.
- **It closes on every way out of its goroutine.** `defer` makes that true even when a stage
  returns early, which section 04 needs.

## A wide stage

A pipeline goes as fast as its slowest stage, so the slow stage is the one worth spreading. **A
stage can be fanned out inside**: several goroutines read its input, as in lesson 13, and its
output is closed when all of them are done, as in lesson 14. From outside it is still one stage,
one channel in and one out. It is saved in `~/pipeline/wide` as `wide.go`:

```go
// Command wide runs the slow middle stage of a pipeline on three goroutines.
package main

import (
	"fmt"
	"sync"
	"time"
)

func gen(n int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 1; i <= n; i++ {
			out <- i
		}
	}()
	return out
}

// slowSq squares each number on `width` goroutines, and closes once all of them are done.
func slowSq(in <-chan int, width int) <-chan int {
	out := make(chan int)
	var wg sync.WaitGroup
	for range width {
		wg.Go(func() {
			for n := range in {
				time.Sleep(30 * time.Millisecond)
				out <- n * n
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
	for _, width := range []int{1, 3} {
		start := time.Now()
		sum := 0
		for v := range slowSq(gen(6), width) {
			sum += v
		}
		fmt.Printf("width %d: sum %d in %v\n", width, sum, time.Since(start).Round(10*time.Millisecond))
	}
}
```

```
ana@vm:~/pipeline$ go run ./wide
width 1: sum 91 in 180ms
width 3: sum 91 in 60ms
```

Six items of 30 milliseconds took 180 on one goroutine and 60 on three. The sum is the same, 91,
because addition does not care about order, and with three goroutines sending, nothing keeps
the squares in their input's order. A stage whose output order matters needs lesson 13's index. The wide stage's closing is the
`WaitGroup` and closer goroutine of lesson 14's `merge`, because three goroutines send on `out`
and only something that counts them knows when the last has finished.
