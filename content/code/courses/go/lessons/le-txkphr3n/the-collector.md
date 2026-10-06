---
title: The garbage collector, and reading its trace
version: 1
---

"Garbage collection" makes many programmers picture a program that freezes now and then while
something tidies up behind it. That picture is wrong about Go. **Go's
collector does almost all of its work while the program keeps running, and stops it twice per
collection, briefly.** In the trace in this section each stop lasts less than a tenth of a
millisecond, and one environment variable is all it takes to watch.

## Mark, then sweep

The collector never asks where a value came from or how old it is. It asks **what the program can
still reach**. It starts from the **roots**, the package-level variables and the stacks of every
running goroutine, follows every pointer it finds, and marks every value on the heap that it
reaches. That is the mark phase. Whatever was not marked cannot be used by the program again,
because nothing leads to it, so the sweep phase hands its room back for new values.

The program in `~/memory-gc` gives it something to do. It keeps 80 buffers of 100,000 bytes, eight
million bytes in all, in the package variable `live`, then makes 50,000 buffers of 10,000 bytes one after another,
fills each one and keeps only the newest in `last`:

```go
package main

import (
	"fmt"
	"runtime"
)

var live [][]byte
var last []byte

func main() {
	for range 80 {
		live = append(live, make([]byte, 100_000))
	}
	for range 50_000 {
		b := make([]byte, 10_000)
		for i := range b {
			b[i] = byte(i)
		}
		last = b
	}
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	fmt.Printf("%d collections, %d MB allocated, heap at most %d MB\n",
		m.NumGC, m.TotalAlloc>>20, m.HeapSys>>20)
}
```

`runtime.ReadMemStats` fills a `runtime.MemStats` with the runtime's own accounting: `NumGC` is how
many collections ran, `TotalAlloc` every byte ever allocated, and `HeapSys`, by its documentation,
"estimates the largest size the heap has had". `>>20` divides by 1,048,576, which is how the runtime
counts a megabyte. Each time `last` moves on, the previous buffer becomes unreachable:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"What the collector does with the heap of the program in ~/memory-gc. It starts from the roots, the package variables live and last and every goroutine stack, and follows pointers. live leads to an array of 80 slices and from it to 80 buffers of 100,000 bytes; last leads to the newest 10,000-byte buffer. Those are marked and kept. The older 10,000-byte buffers are reached from nothing, so the sweep frees their room for new values.\"><defs><marker id=\"gcr-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"101\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">roots</text><rect x=\"16\" y=\"36\" width=\"170\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"101\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">package variables</text><rect x=\"30\" y=\"66\" width=\"142\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">live</text><rect x=\"30\" y=\"106\" width=\"142\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">last</text><rect x=\"30\" y=\"146\" width=\"142\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">goroutine stacks</text><rect x=\"220\" y=\"66\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">80 slices</text><path d=\"M174 81 L217 81\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gcr-phosphor)\"></path><rect x=\"410\" y=\"30\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"416\" y=\"36\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"422\" y=\"42\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"492\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">100,000 bytes</text><text x=\"590\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">× 80</text><path d=\"M342 81 L418 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gcr-phosphor)\"></path><rect x=\"410\" y=\"106\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">10,000 bytes</text><text x=\"560\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the newest</text><path d=\"M174 121 L407 121\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gcr-phosphor)\"></path><rect x=\"240\" y=\"200\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"310\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10,000 bytes</text><rect x=\"395\" y=\"200\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"465\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10,000 bytes</text><rect x=\"550\" y=\"200\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"620\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10,000 bytes</text><text x=\"475\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">older buffers: nothing points at them</text><rect x=\"20\" y=\"262\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reached from a root: marked, kept</text><rect x=\"370\" y=\"262\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"400\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reached from nothing: swept, its room reused</text></svg>", "caption": "One collection of the program in ~/memory-gc. Marking follows pointers from the roots; whatever it never reached is swept."}
```

The source of the runtime describes its own collector in four lines at the top of `mgc.go`:

```
ana@vm:~/memory-gc$ sed -n 7,10p /usr/local/go/src/runtime/mgc.go
// The GC runs concurrently with mutator threads, is type accurate (aka precise), allows multiple
// GC threads to run in parallel. It is a concurrent mark and sweep that uses a write barrier. It is
// non-generational and non-compacting. Allocation is done using size segregated per P allocation
// areas to minimize fragmentation while eliminating locks in the common case.
```

"Mutator" is the collector's word for your program, the thing that changes the heap under it.
**Concurrent** means marking happens while your code runs, and the write barrier is a check the compiler
adds to pointer writes, active while a collection runs, so the marker does not miss a pointer your
program moves. **Non-generational** means it does not sort values by age and treat young ones
differently. **Non-compacting** means it never moves a value on the heap to close the gaps between
them; it reuses the gaps instead, which is what the size classes of lesson 12 section 03 are for.

### Which collector 1.27.1 runs

How marking walks through memory has been reworked inside that design. The build configuration of
1.27.1 turns on an algorithm called **Green Tea** by default, and its file says what it does
differently:

```
ana@vm:~/memory-gc$ grep -n "GreenTeaGC" /usr/local/go/src/internal/buildcfg/exp.go
86:		GreenTeaGC:            true,
ana@vm:~/memory-gc$ sed -n 5,10p /usr/local/go/src/runtime/mgcmark_greenteagc.go
// Green Tea mark algorithm
//
// The core idea behind Green Tea is simple: achieve better locality during
// mark/scan by delaying scanning so that we can accumulate objects to scan
// within the same span, then scan the objects that have accumulated on the
// span all together.
```

A **span** is a run of memory pages that holds values of one size class. Scanning the marked values
of one span together, instead of one by one in the order they were found, keeps the processor
reading nearby memory. It changes how fast marking goes, not what is marked, and no program has to
change for it.

## One line per collection

`GODEBUG=gctrace=1` makes the runtime print a line to standard error at every collection. The
binary is built first, so that the trace is the program's and not the `go` command's, which collects
garbage too:

```
ana@vm:~/memory-gc$ go build -o gc .
ana@vm:~/memory-gc$ GODEBUG=gctrace=1 ./gc 2>&1 | sed -n "1,4p;\$p"
gc 1 @0.000s 12%: 0.073+0.19+0.007 ms clock, 0.29+0.11/0.17/0.20+0.031 ms cpu, 3->4->3 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 2 @0.001s 12%: 0.039+0.23+0.036 ms clock, 0.15+0.043/0.073/0.035+0.14 ms cpu, 7->8->8 MB, 7 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 3 @0.009s 2%: 0.027+0.29+0.058 ms clock, 0.11+0.021/0.048/0.076+0.23 ms cpu, 15->15->8 MB, 16 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 4 @0.016s 2%: 0.029+0.29+0.036 ms clock, 0.11+0.044/0.077/0.017+0.14 ms cpu, 15->15->8 MB, 16 MB goal, 0 MB stacks, 0 MB globals, 4 P
61 collections, 496 MB allocated, heap at most 19 MB
```

`sed` kept the first four lines and the last, which is the program's own. The key to the fields is in
the runtime's documentation:

```
ana@vm:~/memory-gc$ go doc runtime | grep -A 9 "where the fields are" | head -10
    where the fields are as follows:
    	gc #         the GC number, incremented at each GC
    	@#s          time in seconds since program start
    	#%           percentage of time spent in GC since program start
    	#+...+#      wall-clock/CPU times for the phases of the GC
    	#->#-># MB   heap size at GC start, at GC end, and live heap, or /gc/scan/heap:bytes
    	# MB goal    goal heap size, or /gc/heap/goal:bytes
    	# MB stacks  estimated scannable stack size, or /gc/scan/stack:bytes
    	# MB globals scannable global size, or /gc/scan/globals:bytes
    	# P          number of processors used, or /sched/gomaxprocs:threads
```

Read `gc 3` with it, left to right:

| field | in `gc 3` | what it says |
|---|---|---|
| `gc #` | `gc 3` | the third collection of this run |
| `@#s` | `@0.009s` | it started 9 milliseconds after the program |
| `#%` | `2%` | the share of the run so far spent collecting |
| clock | `0.027+0.29+0.058 ms` | a stop, the concurrent mark, a second stop |
| cpu | `0.11+0.021/0.048/0.076+0.23 ms` | the same phases in processor time, the mark split three ways |
| `#->#-># MB` | `15->15->8 MB` | the heap at the start, at the end, and what was still reachable |
| goal | `16 MB goal` | the size this collection aimed to finish under |
| stacks, globals | `0 MB`, `0 MB` | roots to scan: this program's are under a megabyte |
| `# P` | `4 P` | the four processors of the lab's machine |

**The clock field is the answer to the frozen-program picture.** The runtime's documentation names
the three phases: a stop-the-world sweep termination, the concurrent mark and scan, a
stop-the-world mark termination. In `gc 3` the two stops took 0.027 and 0.058 milliseconds, and
the 0.29 milliseconds of marking ran beside the program. The three numbers of the mark in the cpu
field are the time the program's own allocations spent helping, the background workers, and
workers on otherwise idle processors.

`15->15->8` is the mark-and-sweep of the figure in numbers: 15 MB on the heap, 8 MB of it reachable,
the 80 buffers of `live` and little else. Seven megabytes of old `last` buffers were garbage.

## GOGC: how much garbage before the next collection

The goal in `gc 4` is 16 MB, twice the 8 MB that `gc 3` found alive. That doubling is a setting:

```
ana@vm:~/memory-gc$ go doc runtime | grep -A 5 "The GOGC variable"
The GOGC variable sets the initial garbage collection target percentage.
A collection is triggered when the ratio of freshly allocated data to live
data remaining after the previous collection reaches this percentage. The
default is GOGC=100. Setting GOGC=off disables the garbage collector entirely.
runtime/debug.SetGCPercent allows changing this percentage at run time.
```

**`GOGC=100` lets the heap grow by 100% of what survived before the next collection starts.** With
8 MB alive, the next one is due at 16 MB. Lower, and collections come sooner and the heap stays
smaller; higher, and they come later. The same binary under five settings:

```
ana@vm:~/memory-gc$ for g in 50 100 200 400 off; do echo "GOGC=$g: $(GOGC=$g ./gc)"; done
GOGC=50: 123 collections, 496 MB allocated, heap at most 15 MB
GOGC=100: 61 collections, 496 MB allocated, heap at most 19 MB
GOGC=200: 30 collections, 496 MB allocated, heap at most 27 MB
GOGC=400: 15 collections, 496 MB allocated, heap at most 59 MB
GOGC=off: 0 collections, 496 MB allocated, heap at most 499 MB
```

Every run allocated the same 496 MB. Doubling `GOGC` roughly halved the number of collections and
let the heap grow, and `off` collected nothing and kept every byte. **GOGC trades memory for the
processor time spent collecting**, and there is no setting that saves both. The counts and the
megabytes differ a little on every run, because the collector runs beside the program and the two
race; the shape stays the same.
