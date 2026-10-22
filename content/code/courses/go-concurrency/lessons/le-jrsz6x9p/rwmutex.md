---
title: Many readers, one writer
version: 1
---

A plain mutex lets one goroutine in at a time, and for data that is mostly read that is more
caution than it needs. Two goroutines that only read cannot spoil anything for each other. **A
`sync.RWMutex` has two kinds of lock: any number of readers may hold `RLock` together, and `Lock`
is held by one writer with nobody else**, readers included.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two timelines of the same four reads and one write. Under a Mutex the four reads and the write each hold the lock alone, one after another. Under an RWMutex the four reads hold the read lock together and overlap, then the write holds the lock alone, so the whole sequence ends much sooner.\"><defs><marker id=\"l08rw-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sync.Mutex</text><rect x=\"130\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read 1</text><rect x=\"230\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read 2</text><rect x=\"330\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"378.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read 3</text><rect x=\"430\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"478.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read 4</text><rect x=\"530\" y=\"46\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"578.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">write</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sync.RWMutex</text><rect x=\"130\" y=\"132\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read 1</text><rect x=\"130\" y=\"156\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read 2</text><rect x=\"130\" y=\"180\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read 3</text><rect x=\"130\" y=\"204\" width=\"96\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">read 4</text><rect x=\"230\" y=\"132\" width=\"96\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">write</text><path d=\"M328 126 V230\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"328\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">done</text><path d=\"M628 40 V78\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M130 262 H660\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08rw-paper-dim)\"></path><text x=\"80\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "Four readers and one writer: a Mutex serialises all five, an RWMutex lets the readers overlap and keeps the writer alone."}
```

## Measured on a shared map

The program below has eight goroutines read a price list 100,000 times each. It takes two words: which
lock to use, and how much work each read does while it holds the lock, so the two can be compared
on long and short critical sections. Saved as `cache.go`:

```go
// Command cache reads a shared map from eight goroutines, under a Mutex or an RWMutex.
//
//	./cache mutex 200   each read holds a Mutex while it does 200 steps of work
//	./cache rw 0        each read holds an RWMutex's read lock and does no extra work
package main

import (
	"fmt"
	"os"
	"strconv"
	"sync"
	"time"
)

// locker is what both kinds of lock offer for reading.
type locker interface {
	lock()
	unlock()
}

type plain struct{ sync.Mutex }

func (p *plain) lock()   { p.Lock() }
func (p *plain) unlock() { p.Unlock() }

type rw struct{ sync.RWMutex }

func (r *rw) lock()   { r.RLock() }
func (r *rw) unlock() { r.RUnlock() }

var prices = map[string]int{"apple": 120, "bread": 450, "milk": 600}

var work int

// lookup reads the map and does some work with the answer, all under the lock.
func lookup(l locker, item string) int {
	l.lock()
	defer l.unlock()
	p := prices[item]
	for range work {
		p = (p*31 + 7) % 1000
	}
	return p
}

func main() {
	var l locker = &plain{}
	if os.Args[1] == "rw" {
		l = &rw{}
	}
	work, _ = strconv.Atoi(os.Args[2])
	start := time.Now()
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			for range 100_000 {
				lookup(l, "bread")
			}
		})
	}
	wg.Wait()
	fmt.Printf("%-5s work %3d: 800000 reads in %v\n", os.Args[1], work, time.Since(start).Round(time.Millisecond))
}
```

The `locker` interface lets one `lookup` use either lock: `plain` locks a `Mutex` fully, `rw`
takes only an `RWMutex`'s read lock. Built with `go build -o cache cache.go`:

```
ana@vm:~/locks$ ./cache mutex 200
mutex work 200: 800000 reads in 641ms
ana@vm:~/locks$ ./cache rw 200
rw    work 200: 800000 reads in 200ms
ana@vm:~/locks$ ./cache mutex 0
mutex work   0: 800000 reads in 65ms
ana@vm:~/locks$ ./cache rw 0
rw    work   0: 800000 reads in 79ms
```

**With 200 steps of work under the lock, the read lock was three times faster**: 641
milliseconds against 200. Under the plain mutex the eight goroutines queued to do their work one at a
time; under the read lock four of them worked at once, one per processor.

**With no work under the lock, the `RWMutex` was slower**: 79 milliseconds against 65. An
`RWMutex` has more bookkeeping than a `Mutex`, because it counts its readers, and when the critical
section is a single map lookup that bookkeeping is most of the cost. So an `RWMutex` is not a free
upgrade. It pays when readers are many and hold the lock long enough to overlap, and the way to know
is to measure, as here.

## The rules that come with it

The documentation of `sync.RWMutex` adds two rules that a reader of code needs to know:

- **A waiting writer stops new readers.** Once a goroutine is blocked in `Lock`, later calls to
  `RLock` wait until that writer has had its turn. Without that a steady stream of readers could
  keep a writer out for ever.
- **A read lock cannot be turned into a write lock.** A goroutine holding `RLock` that calls `Lock`
  waits for every reader to leave, itself included, and so waits for ever. Release the read lock,
  take the write lock, and check again whatever you read, since another writer may have come
  between.

The same rule as the plain mutex holds for both: **one `RLock` is released by exactly one
`RUnlock`**, and `defer` is the way to be sure of it.
