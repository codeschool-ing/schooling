---
title: The scheduler that runs them
version: 1
---

Something has to decide which of a hundred thousand goroutines runs on which of four processors.
In most languages that is the operating system's job, done thread by thread. **In Go it is the
runtime's: a scheduler compiled into every program, which places many goroutines on a few
threads.** The operating system sees only the threads.

It works with three kinds of thing, named by single letters in the runtime's source:

- **G** is a goroutine: its stack, and where it had got to.
- **M** is a machine, the runtime's word for an operating-system thread.
- **P** is a processor, a licence to run Go code. There are exactly `GOMAXPROCS` of them, and an M
  must hold a P to run a G.

Each P keeps a queue of goroutines ready to run, and there is one global queue besides. An M with a
P takes the next G from its P's queue; when that queue is empty it takes from the global queue, or
**steals half the queue of another P**, so no processor sits idle while another has a backlog. When
a goroutine blocks in a system call, its M blocks with it, and the P is handed to another M so the
other goroutines keep running. That is why a Go program has a few more threads than processors.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The Go scheduler at the moment of the trace at 505 milliseconds. Four Ps, P0 to P3, each held by a thread, M0 to M3, and each running one goroutine. Two goroutines wait in the global run queue, and P0 and P3 each have one more in their local queue. A fifth thread, M4, holds no P and waits. The operating system sees only the five threads.\"><rect x=\"250\" y=\"14\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">global run queue</text><rect x=\"318\" y=\"33\" width=\"36\" height=\"16\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"336\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">G</text><rect x=\"366\" y=\"33\" width=\"36\" height=\"16\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"384\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">threads: all the operating system sees</text><rect x=\"30\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M0</text><path d=\"M90 122 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"30\" y=\"140\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">P0</text><rect x=\"60\" y=\"184\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"90\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">running</text><rect x=\"30\" y=\"238\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"90\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">local queue</text><rect x=\"72\" y=\"262\" width=\"36\" height=\"16\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">G</text><rect x=\"190\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M1</text><path d=\"M250 122 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"190\" y=\"140\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">P1</text><rect x=\"220\" y=\"184\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"250\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"250\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">running</text><rect x=\"190\" y=\"238\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"250\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">local queue</text><rect x=\"350\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M2</text><path d=\"M410 122 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"350\" y=\"140\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">P2</text><rect x=\"380\" y=\"184\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"410\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"410\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">running</text><rect x=\"350\" y=\"238\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"410\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">local queue</text><rect x=\"510\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">M3</text><path d=\"M570 122 V140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"510\" y=\"140\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">P3</text><rect x=\"540\" y=\"184\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"570\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">G</text><text x=\"570\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">running</text><rect x=\"510\" y=\"238\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"570\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">local queue</text><rect x=\"552\" y=\"262\" width=\"36\" height=\"16\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></rect><text x=\"570\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--ink)\">G</text><rect x=\"650\" y=\"96\" width=\"50\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"675\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">M4</text><text x=\"675\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">spare, no P</text><path d=\"M20 90 H705\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"360\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">GOMAXPROCS=4</text></svg>", "caption": "Eight goroutines on four Ps and five threads, as the schedtrace line at 505ms counted them."}
```

The runtime will describe this as it happens. `GODEBUG=schedtrace=500` makes it print one line
about the scheduler every 500 milliseconds.

The program it is measured on keeps eight goroutines computing for a second and a half, twice as
many as the lab has processors, saved as `busy.go`:

```go
// Command busy keeps eight goroutines computing for a second and a half.
package main

import (
	"sync"
	"time"
)

func main() {
	stop := time.Now().Add(1500 * time.Millisecond)
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			for time.Now().Before(stop) {
			}
		})
	}
	wg.Wait()
}
```

```
ana@vm:~/goroutines$ go build -o busy busy.go
ana@vm:~/goroutines$ GODEBUG=schedtrace=500 ./busy
SCHED 0ms: gomaxprocs=4 idleprocs=2 threads=5 spinningthreads=1 needspinning=0 idlethreads=2 runqueue=0 [ 0 0 0 0 ] schedticks=[ 1 0 0 2 ]
SCHED 505ms: gomaxprocs=4 idleprocs=0 threads=5 spinningthreads=0 needspinning=1 idlethreads=0 runqueue=2 [ 1 0 0 1 ] schedticks=[ 22 21 22 24 ]
SCHED 1011ms: gomaxprocs=4 idleprocs=0 threads=5 spinningthreads=0 needspinning=1 idlethreads=0 runqueue=2 [ 1 1 0 0 ] schedticks=[ 44 44 44 46 ]
```

Read the line at 505ms from the left. `gomaxprocs=4` is the four Ps, and `idleprocs=0` says all of
them are busy. `threads=5` is the Ms: four running Go code and one spare, for eight goroutines.
`runqueue=2` is the global queue, and `[ 1 0 0 1 ]` are the four local queues, one number per P. Two
plus one plus one is four goroutines waiting, and with the four running that is all eight. At
1011ms the waiting ones sit on different Ps, because the scheduler moved them. `schedticks` counts
how many times each P has picked a goroutine, and the four numbers keep pace with each other: the
work was shared evenly. The first line, at 0ms, caught the program before most goroutines had
started.

**Eight goroutines ran on five threads**, and a hundred thousand would have run on about as few.

## A loop that never calls anything

A scheduler has to take the processor back from a goroutine that does not give it up. This
program asks for one processor, starts a goroutine that loops forever without calling a single
function, and then has `main` sleep and print, saved as `hog.go`:

```go
// Command hog runs a loop that never calls a function, on one processor.
package main

import (
	"fmt"
	"runtime"
	"time"
)

func main() {
	runtime.GOMAXPROCS(1)
	go func() {
		for {
		}
	}()
	time.Sleep(100 * time.Millisecond)
	fmt.Println("main got the processor back")
}
```

```
ana@vm:~/goroutines$ go build -o hog hog.go
ana@vm:~/goroutines$ ./hog
main got the processor back
ana@vm:~/goroutines$ GODEBUG=asyncpreemptoff=1 timeout 3 ./hog; echo "exit status: $?"
exit status: 124
```

With the default settings `main` printed its line: after 100 milliseconds the runtime interrupted
the looping goroutine, gave the only processor to `main`, and the program ended. Since Go 1.14 the
scheduler **preempts** a goroutine that has run for about ten milliseconds, by sending its thread a
signal, even in a loop with no function call in it.

`GODEBUG=asyncpreemptoff=1` turns that signal off, which leaves only the older kind of preemption,
the kind that happens at a function call. The loop calls nothing, so it never reaches one, `main`
never runs again, and `timeout` had to kill the program after three seconds: exit status 124 is
`timeout` reporting that it did. Older releases of Go behaved like the second run.

**You will not write `for {}` on purpose**, and you never need `Gosched` or a call to yield. What
the experiment shows is that no goroutine can keep the others from running, however badly it
behaves, and that the order they get turns in is the scheduler's choice, never the program's.
