---
title: Through the whole call
version: 1
---

Passing `ctx` down unchanged is most of what a program does with it. The rest is **deriving**: a
function that needs a tighter limit, or a way to stop its own helpers, makes a child of the context
it was given and passes the child on. Lesson 10 showed `WithTimeout` and `WithCancel` once each.
Used in a chain, they form a tree, and the tree has rules that are easy to guess wrong.

## A child can only be shorter-lived

The common wrong guess is that a child with a longer timeout than its parent gets the longer one.
The program below derives two children from a root that has 100 milliseconds: one asks for a whole
second, the other is cancelled by hand. It is saved in `~/propagate/tree` as `tree.go`:

```go
// Command tree derives contexts from a context and shows what each one inherits.
package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	start := time.Now()
	root, cancelRoot := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancelRoot()

	child, cancelChild := context.WithTimeout(root, time.Second)
	defer cancelChild()
	sibling, cancelSibling := context.WithCancel(root)

	rootDeadline, _ := root.Deadline()
	childDeadline, _ := child.Deadline()
	fmt.Println("child's deadline is root's:", childDeadline.Equal(rootDeadline))

	cancelSibling()
	fmt.Println("sibling:", sibling.Err())
	fmt.Println("root:   ", root.Err())
	fmt.Println("child:  ", child.Err())

	<-child.Done()
	fmt.Printf("child done after %v: %v\n", time.Since(start).Round(10*time.Millisecond), child.Err())
}
```

```
ana@vm:~/propagate$ go run ./tree
child's deadline is root's: true
sibling: context canceled
root:    <nil>
child:   <nil>
child done after 100ms: context deadline exceeded
```

Three rules, one per line of output:

- **A child's deadline is the earlier of its own and its parent's.** `child` asked for a second and
  reports root's deadline instead, and it ended at 100 milliseconds with
  `context deadline exceeded`, the parent's reason.
- **Cancelling a child does not touch its parent or its siblings.** `sibling` was cancelled, and
  `root` and `child` both still answered `<nil>` straight afterwards.
- **An end travels down the tree and never up.** Whatever ends a context ends everything derived
  from it, at any depth.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The contexts of tree.go as a tree. context.Background at the top; under it root, with a 100 millisecond timeout; under root two children: child, which asked for one second but inherits root&#x27;s deadline at 100 milliseconds, and sibling, which was cancelled by hand. Cancelling sibling stopped at sibling: root and child carried on. Root&#x27;s deadline reached both of its children.\"><defs><marker id=\"l11tree-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l11tree-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"250\" y=\"20\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">context.Background()</text><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">never ends</text><rect x=\"250\" y=\"100\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">root</text><text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">deadline in 100 ms</text><rect x=\"90\" y=\"196\" width=\"220\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">child</text><text x=\"200\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">asked for 1 s</text><text x=\"200\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ends at 100 ms, with root</text><rect x=\"410\" y=\"196\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sibling</text><text x=\"520\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cancelled by hand</text><path d=\"M360 62 V98\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11tree-wire)\"></path><path d=\"M330 142 L230 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11tree-phosphor)\"></path><path d=\"M390 142 L490 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11tree-phosphor)\"></path><text x=\"80\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">an end travels down</text><text x=\"80\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">never up or sideways</text></svg>", "caption": "tree.go's contexts. A context ends when its parent does or when its own reason arrives, whichever is first; its end reaches only what was derived from it."}
```

This is what makes deriving safe. A function can impose a shorter limit on its own part of the
work, or cancel the helpers it started, and nothing it does can cut short the caller's work or a
neighbour's. The reverse holds too: no child can extend what its caller allowed.

**Every derived context comes with a cancel function, and `defer cancel()` goes on the next
line.** Calling it releases what the runtime keeps to track the child, even when the deadline
would have ended it anyway; `go vet` reports a cancel function that is dropped on some path,
because the child then lives until its parent ends.

## Two tools for the edges

Two functions in the `context` package handle work that sits at the boundary of a request. The
program below uses both, saved in `~/propagate/detach` as `detach.go`:

```go
// Command detach runs code when a context ends, and keeps one piece of work going past it.
package main

import (
	"context"
	"fmt"
)

type requestID struct{}

func main() {
	ctx := context.WithValue(context.Background(), requestID{}, "req-7f3a")
	ctx, cancel := context.WithCancel(ctx)

	closed := make(chan struct{})
	stop := context.AfterFunc(ctx, func() {
		fmt.Println("AfterFunc: request over, closing its connection")
		close(closed)
	})
	defer stop()

	audit := context.WithoutCancel(ctx)

	cancel()
	<-closed
	fmt.Println("ctx:  ", ctx.Err())
	fmt.Println("audit:", audit.Err(), "| request", audit.Value(requestID{}))
	fmt.Println("stop after the fact:", stop())
}
```

```
ana@vm:~/propagate$ go run ./detach
AfterFunc: request over, closing its connection
ctx:   context canceled
audit: <nil> | request req-7f3a
stop after the fact: false
```

**`context.AfterFunc` runs a function, in a goroutine of its own, once the context ends.** It is
for code that has to react to a cancellation without a goroutine of yours sitting in a `select` for
it: closing a connection, releasing a resource. The function it returns, `stop`, removes the
arrangement if the work finished first. Here it came too late and said so with `false`: the
function had already run. The program waited for it on a channel, `closed`, rather than with a
sleep, because lesson 1 showed that a pause promises nothing.

**`context.WithoutCancel` keeps the values and drops the ending.** `audit` still answers the
request's id, `req-7f3a`, and its `Err` stays `<nil>` after the request was cancelled. It is for the
small piece of work that must finish even when the request does not, such as writing the audit
record of a request the client abandoned. Used anywhere else, it switches off the very mechanism
this lesson builds, so it belongs at the edge of a request and nowhere in the middle.
