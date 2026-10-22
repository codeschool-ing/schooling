---
title: Two words that are not one
version: 1
---

Most people arrive at this subject holding one idea under two names: concurrency means doing
several things at the same instant, and so does parallelism. **The two words name different
things, and Go's whole design rests on the difference.** Rob Pike, one of Go's designers, put it in
one line: concurrency is about *dealing* with lots of things at once, parallelism is about *doing*
lots of things at once.

- **Concurrency is a property of the program.** It is written as several independent activities,
  each of which could make progress without waiting for the others. In Go each activity is a
  goroutine, lesson 2's subject.
- **Parallelism is a property of one run.** It is whether, at a given instant, more than one of
  those activities is actually executing, on more than one processor.

A concurrent program may run with no parallelism at all, on one processor, taking turns. A program
with no concurrency in it cannot run in parallel, however many processors the machine has. **You
write the concurrency; the machine and the runtime decide how much parallelism you get.**

## The same program, three runs

The demonstration is a program of four goroutines that each do the same arithmetic and share
nothing. It is shown in pieces, saved as `spin.go`:

```schooling-example
{"language": "go", "file": "spin.go", "parts": [{"code": "// Command spin runs four equal pieces of arithmetic at once and times them.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"runtime\"\n\t\"sync\"\n\t\"time\"\n)\n\n", "note": "The standard library alone, as everything in this course. `runtime` is the package that answers questions about the program's own run."}, {"code": "// work keeps one processor busy for a while and touches nothing shared.\nfunc work() uint64 {\n\tvar x uint64\n\tfor range 500_000_000 {\n\t\tx = x*6364136223846793005 + 1\n\t}\n\treturn x\n}\n\n", "note": "**Half a billion multiplications, each needing the one before.** No step can be skipped and nothing waits on a disk or a network, so the only thing that makes it faster is a processor of its own."}, {"code": "var sink [4]uint64\n\n", "note": "Each goroutine writes its result in a slot of its own. Keeping the result gives the arithmetic a use, and four separate slots mean nothing is shared between the goroutines."}, {"code": "func main() {\n\tstart := time.Now()\n\tvar wg sync.WaitGroup\n\tfor i := range 4 {\n\t\twg.Go(func() { sink[i] = work() })\n\t}\n\twg.Wait()\n", "note": "**This loop is the concurrency, and it is the same in every run.** Four calls of `work`, each started as a goroutine by `wg.Go`, then `wg.Wait` until all four have returned."}, {"code": "\tfmt.Printf(\"GOMAXPROCS=%d: four tasks took %v\\n\",\n\t\truntime.GOMAXPROCS(0), time.Since(start).Round(10*time.Millisecond))\n}\n", "note": "`runtime.GOMAXPROCS(0)` reports a setting without changing it: how many goroutines may execute Go code at the same instant. That number is the parallelism."}]}
```

`GOMAXPROCS` defaults to the number of processors the program is allowed to use, and an
environment variable of the same name overrides it for one run. So the program never changes, and
the parallelism it gets does:

```
ana@vm:~/promise$ nproc
4
ana@vm:~/promise$ go build -o spin spin.go
ana@vm:~/promise$ ./spin
GOMAXPROCS=4: four tasks took 400ms
ana@vm:~/promise$ GOMAXPROCS=1 ./spin
GOMAXPROCS=1: four tasks took 1.57s
ana@vm:~/promise$ GOMAXPROCS=2 ./spin
GOMAXPROCS=2: four tasks took 800ms
```

The lab has four processors, and the arithmetic cost about 400 milliseconds a task. **With one
processor the four took turns, and the total is close to four times one task**: 1.57 seconds. Two
processors halved that to 800 milliseconds, and four brought it down to 400. Nothing in the source
moved; only the number of lanes did.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The same four tasks, A to D, run twice. With one processor they take turns in short slices along a single lane, and all four finish after about 1.6 seconds. With four processors each task has a lane of its own and all four finish after about 0.4 seconds. The program is the same; only the parallelism changed.\"><defs><marker id=\"l01turns-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one processor: the four take turns</text><text x=\"60\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P1</text><rect x=\"110.0\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"127.1\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><rect x=\"146.2\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"163.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><rect x=\"182.5\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"199.6\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><rect x=\"218.8\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"235.9\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><rect x=\"255.0\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"272.1\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><rect x=\"291.2\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"308.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><rect x=\"327.5\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"344.6\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><rect x=\"363.8\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"380.9\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><rect x=\"400.0\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"417.1\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><rect x=\"436.2\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"453.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><rect x=\"472.5\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"489.6\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><rect x=\"508.7\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"525.9\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><rect x=\"545.0\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"562.1\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><rect x=\"581.2\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"598.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><rect x=\"617.5\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"634.6\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><rect x=\"653.8\" y=\"48\" width=\"34.2\" height=\"28\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"670.9\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><text x=\"110\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">four processors: the four run at once</text><text x=\"60\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P1</text><rect x=\"110\" y=\"128\" width=\"143.0\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"182.5\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">A</text><text x=\"60\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P2</text><rect x=\"110\" y=\"160\" width=\"143.0\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"182.5\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">B</text><text x=\"60\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P3</text><rect x=\"110\" y=\"192\" width=\"143.0\" height=\"26\" rx=\"2\" fill=\"var(--paper)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"182.5\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">C</text><text x=\"60\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">P4</text><rect x=\"110\" y=\"224\" width=\"143.0\" height=\"26\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"182.5\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">D</text><path d=\"M110 268 H700\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01turns-paper-dim)\"></path><path d=\"M110.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M255.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"255.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4 s</text><path d=\"M400.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"400.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8 s</text><path d=\"M545.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"545.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.2 s</text><path d=\"M690.0 263 V273\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"690.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.6 s</text><text x=\"60\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">time</text><path d=\"M255.0 120 V258\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path></svg>", "caption": "spin.go twice: concurrency is the four tasks, parallelism is how many lanes the run was given."}
```

## Concurrency without parallelism still pays

If parallelism were the only reward, a concurrent program on one processor would be pointless. It
is not, because most real programs spend their time waiting: for a disk, for a database, for a
server on another continent. A waiting goroutine needs no processor at all. Here the four tasks
each wait one second instead of computing, saved as `wait.go`:

```go
// Command wait starts four tasks that each wait one second.
package main

import (
	"fmt"
	"runtime"
	"sync"
	"time"
)

func main() {
	start := time.Now()
	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() { time.Sleep(time.Second) })
	}
	wg.Wait()
	fmt.Printf("GOMAXPROCS=%d: four waits took %v\n",
		runtime.GOMAXPROCS(0), time.Since(start).Round(10*time.Millisecond))
}
```

```
ana@vm:~/promise$ go build -o wait wait.go
ana@vm:~/promise$ ./wait
GOMAXPROCS=4: four waits took 1s
ana@vm:~/promise$ GOMAXPROCS=1 ./wait
GOMAXPROCS=1: four waits took 1s
```

**One processor, four seconds of waiting, one second on the clock.** While one goroutine sleeps
the runtime has nothing to run for it, so the four sleeps overlap completely. Written one after
another, the same four waits would have taken four seconds on any machine. That is the case Go
was built for: a server with thousands of requests in flight, nearly all of them waiting on
something, served by a handful of processors.

The two results point the same way. **Structure your program as independent pieces first**, and
it takes whatever parallelism the machine offers without being rewritten. Lesson 2 shows what a
goroutine costs, and why thousands of them are ordinary.
