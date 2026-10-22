---
title: Reading a report, line by line
version: 1
---

A race report looks like a stack trace, and the reflex is to scroll to the bottom for the error.
**There is no error at the bottom. A report is two accesses and two birthplaces**, and every line
of it answers one of four questions: what was touched, what touched it before, and where each of
the two goroutines came from. Read in that order, a report names the fix nearly every time.

The program is a counter that one goroutine keeps raising while `main` reads it, the shape of a
server that counts requests while something else reports the count. Saved as `stats.go`:

```go
// Command stats counts requests in one goroutine while main reports them.
package main

import (
	"fmt"
	"time"
)

type stats struct {
	served int
}

func main() {
	s := &stats{}
	go serve(s)
	time.Sleep(10 * time.Millisecond)
	fmt.Println("served so far:", s.served)
}

func serve(s *stats) {
	for {
		s.served++
		time.Sleep(time.Millisecond)
	}
}
```

Run plainly and then with the detector:

```
ana@vm:~/races$ go run stats.go
served so far: 10
ana@vm:~/races$ go run -race stats.go
==================
WARNING: DATA RACE
Read at 0x00c00009e028 by main goroutine:
  main.main()
      /home/ana/races/stats.go:17 +0xe8

Previous write at 0x00c00009e028 by goroutine 8:
  main.serve()
      /home/ana/races/stats.go:22 +0x44
  main.main.gowrap1()
      /home/ana/races/stats.go:15 +0xe

Goroutine 8 (running) created at:
  main.main()
      /home/ana/races/stats.go:15 +0xa4
==================
served so far: 11
Found 1 data race(s)
exit status 66
```

The plain run printed a plausible number and nothing else. That is the whole difficulty with
races: **the program without the detector gave no sign that anything was wrong.**

## The four parts

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The race report from stats.go split into its four parts. One: Read at an address by main goroutine, in main.main at stats.go line 17, the access that completed the race. Two: Previous write at the same address by goroutine 8, in main.serve at stats.go line 22, the access nothing ordered against the first. Three: Goroutine 8 created at main.main, stats.go line 15, where the other goroutine was born. Four: Found 1 data race(s), the count, and exit status 66.\"><defs><marker id=\"l16rep-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16rep-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l16rep-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Read at 0x00c00009e028 by main goroutine:</text><text x=\"34\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  main.main()  stats.go:17</text><path d=\"M424 46.0 H452\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16rep-phosphor)\"></path><text x=\"462\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1  what was touched, and where</text><text x=\"476\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the access that completed the race</text><rect x=\"20\" y=\"98\" width=\"400\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Previous write at 0x00c00009e028 by goroutine 8:</text><text x=\"34\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  main.serve()  stats.go:22</text><text x=\"34\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  main.main.gowrap1()  stats.go:15</text><path d=\"M424 133.0 H452\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16rep-amber)\"></path><text x=\"462\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2  what touched it before</text><text x=\"476\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing ordered it against 1</text><rect x=\"20\" y=\"194\" width=\"400\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Goroutine 8 (running) created at:</text><text x=\"34\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  main.main()  stats.go:15</text><path d=\"M424 220.0 H452\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16rep-paper-dim)\"></path><text x=\"462\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3  where the other goroutine was born</text><text x=\"476\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the go statement that started it</text><rect x=\"20\" y=\"262\" width=\"400\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Found 1 data race(s)</text><text x=\"34\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">exit status 66</text><path d=\"M424 288.0 H452\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16rep-paper-dim)\"></path><text x=\"462\" y=\"279.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4  the count</text><text x=\"476\" y=\"297.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and status 66 at exit</text></svg>", "caption": "One report, four questions. Lines 17 and 22 of stats.go are the diagnosis; line 15 says who started the second goroutine."}
```

**`Read at 0x00c00009e028 by main goroutine`** is the access that completed the race, and the
stack under it says where: `main.main()`, line 17 of `stats.go`, which is the `fmt.Println` that
reads `s.served`. The address is the variable's place in memory. It changes on every run and
matters only for matching it with the next block.

**`Previous write at 0x00c00009e028 by goroutine 8`** is the other access to the same address,
the one nothing ordered against the first. Its stack reads from the top down: `main.serve()` at
line 22, which is `s.served++`, called from `main.main.gowrap1()` at line 15. That second frame
is the runtime's wrapper around the `go serve(s)` statement, and line 15 is that statement.

**`Goroutine 8 (running) created at`** is the birthplace of the other goroutine: `main.main()`
at line 15 again, the `go` statement. A report gives a birthplace for every goroutine it names
except `main`, which nobody created. `(running)` says the goroutine was still alive when the
report was written; `(finished)` would say it had already returned.

**The last line is the count**, `Found 1 data race(s)`, followed by status 66. The program still
printed its number, `11` in that run, because the detector reports and lets the program go on.

So the report names the variable twice, by two lines of source: line 17 reads it in one goroutine
and line 22 writes it in another, and nothing makes one happen before the other. That sentence is
the diagnosis, and the fix in section 04 of this lesson follows from it.

## When a stack stops inside the runtime

Not every report is that tidy. Here several goroutines count the words of a few lines into one
map, saved as `tally.go`:

```go
// Command tally counts words from several goroutines into one map.
package main

import (
	"fmt"
	"strings"
	"sync"
)

func main() {
	lines := []string{"the cat sat", "the dog ran", "a cat ran", "the end"}
	counts := map[string]int{}
	var wg sync.WaitGroup
	for _, line := range lines {
		wg.Go(func() {
			for _, w := range strings.Fields(line) {
				counts[w]++
			}
		})
	}
	wg.Wait()
	fmt.Println(counts)
}
```

Three plain runs agree, and they are right. With the detector there were four reports, so this
run sets `GORACE=halt_on_error=1`, which stops the program at the first one:

```
ana@vm:~/races$ for i in 1 2 3; do go run tally.go; done
map[a:1 cat:2 dog:1 end:1 ran:2 sat:1 the:3]
map[a:1 cat:2 dog:1 end:1 ran:2 sat:1 the:3]
map[a:1 cat:2 dog:1 end:1 ran:2 sat:1 the:3]
ana@vm:~/races$ GORACE=halt_on_error=1 go run -race tally.go; echo "exit: $?"
==================
WARNING: DATA RACE
Read at 0x00c0000a20f0 by goroutine 8:
  runtime.mapaccess2_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:120 +0x0
  runtime.mapaccess1_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:115 +0x17

Previous write at 0x00c0000a20f0 by goroutine 11:
  runtime.mapassign_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:261 +0x0
  main.main.func1()
      /home/ana/races/tally.go:17 +0xcc

Goroutine 8 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72

Goroutine 11 (finished) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
==================
exit status 66
exit: 1
```

**The plain runs printed the correct count three times**, with a race in the program every time:
the goroutines were so short that they hardly overlapped, and luck did the rest. The detector
does not need luck. It saw two goroutines touch the same map with nothing between them.

Three things in this report differ from the last one. The frames start with
`runtime.mapaccess2_faststr` and `runtime.mapassign_faststr`: the map's own code, inside the
runtime, is where the memory was actually touched. **Skip the runtime frames and look for the first
line in your own files**: `tally.go:17`, `counts[w]++`, under the previous write by goroutine 11.

The read by goroutine 8 never reaches your files at all; its stack stops inside the runtime's map
code. That happens, and it costs nothing here, because one side naming your line is enough: both
sides touched the same address, so both are the same `counts[w]++`. And the birthplaces point at
`sync.(*WaitGroup).Go()`, the line of the standard library that started the goroutine for you,
which is where any goroutine started by `wg.Go` says it was born. `(finished)` beside goroutine 11
says it had already returned when the report was written.

`GORACE` is how the detector takes options at run time, and `halt_on_error=1` is the one worth
knowing: one report is easier to read than four, and you fix them one at a time anyway. The exit
status 66 comes through `go run`, which then exits 1 itself, as the last line shows.
