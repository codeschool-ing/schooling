---
title: Cancellation, the context way
version: 1
---

Lesson 6 ended on a hand-made `done` channel: the owner closes it, and every goroutine listening
stops. The `context` package is that idea with a standard shape, so that a function written by one
person can be stopped by code written by another. **A `context.Context` carries a `Done` channel
that closes when the work should stop, and an `Err` that says why.** Every function that might wait
takes one, and listens.

## Four methods and one tree

The interface is small. `Done()` returns a channel that is closed when the context is cancelled.
`Err()` is `nil` until then, and afterwards says how it ended, `context.Canceled` or
`context.DeadlineExceeded`. `Deadline()` reports a deadline if there is one, section 03's subject,
and `Value(key)` is section 04's.

Contexts form a tree. **`context.Background()` is the root**, empty and never cancelled, and each
`With…` function makes a child of the context it is given. `context.WithCancel(parent)` returns
the child and a `cancel` function. Calling `cancel` closes the child's `Done`, and the children of
that child, all the way down; it never touches the parent.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The tree of contexts in cancel.go. context.Background is the root and is never cancelled. ctx is made from it with WithCancel, and child is made from ctx with WithCancel. One worker listens on ctx and another on child. Calling cancel on ctx closes Done on ctx and on child, so both workers stop; the root is untouched.\"><defs><marker id=\"l10tree-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10tree-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l10tree-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">context.Background()</text><text x=\"150\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">never cancelled</text><rect x=\"40\" y=\"120\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ctx</text><text x=\"150\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">WithCancel(Background)</text><rect x=\"40\" y=\"220\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">child</text><text x=\"150\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">WithCancel(ctx)</text><path d=\"M150 72 V118\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10tree-wire)\"></path><path d=\"M150 172 V218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10tree-wire)\"></path><rect x=\"420\" y=\"120\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"505\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">parent&#x27;s worker</text><text x=\"505\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">stopped</text><rect x=\"420\" y=\"220\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"505\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">child&#x27;s worker</text><text x=\"505\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">stopped</text><path d=\"M262 145 H418\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l10tree-phosphor)\"></path><path d=\"M262 245 H418\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l10tree-phosphor)\"></path><text x=\"340\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Done</text><text x=\"340\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Done</text><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cancel() closes Done here…</text><path d=\"M610 72 Q 610 100 262 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10tree-amber)\"></path><text x=\"340\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">…and in every child below</text><path d=\"M300 280 Q 285 255 264 250\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10tree-amber)\"></path></svg>", "caption": "cancel.go: cancelling a context cancels its children, never its parent."}
```

## Two workers, one call

The program below starts a worker on a context and another on a child of it, then cancels the
parent only. Saved as `cancel.go`:

```go
// Command cancel stops two workers by cancelling the context they were given.
package main

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// work does one step every 30 ms until its context is cancelled.
func work(ctx context.Context, name string) {
	steps := 0
	for {
		select {
		case <-ctx.Done():
			fmt.Printf("%s stopped after %d steps: %v\n", name, steps, ctx.Err())
			return
		case <-time.After(30 * time.Millisecond):
			steps++
		}
	}
}

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	child, cancelChild := context.WithCancel(ctx)
	defer cancelChild()

	var wg sync.WaitGroup
	wg.Go(func() { work(ctx, "parent's worker") })
	wg.Go(func() { work(child, "child's worker") })

	time.Sleep(100 * time.Millisecond)
	cancel()
	wg.Wait()
	fmt.Println("child's Err after the parent was cancelled:", child.Err())
}
```

```
ana@vm:~/ctx$ go run cancel.go
parent's worker stopped after 3 steps: context canceled
child's worker stopped after 3 steps: context canceled
child's Err after the parent was cancelled: context canceled
```

**One call to `cancel` stopped both workers**, the one on the child included, and the child's `Err`
became `context.Canceled` without anybody cancelling it directly. Each worker took three steps in the
100 milliseconds before the cancel, and the `select` in `work` is what let it hear the news between
steps: a goroutine that never looks at `Done` cannot be stopped by any context.

Two habits are visible in `main`. **The function that creates a cancellable context calls its
`cancel`**, here with `defer cancelChild()`, even when somebody else may cancel first; calling it
twice is harmless. And `cancel` is called by the owner, never by the worker: the worker only listens.
Lesson 11 is about passing the context down through every layer of a program, so the listening
reaches the code that actually waits.
