---
title: Four ways to fix one, and choosing between them
version: 1
---

A race is two goroutines touching the same memory with nothing ordering them. **So there are
exactly two kinds of fix: put something between the two accesses, or stop them touching the same
memory.** The first kind has three tools in Go, and the second has one idea. Each of the races in
this lesson gets the one that fits it, and each fix is proved the same way: the detector runs
again and says nothing.

| the race | the fix | why that one |
|---|---|---|
| one number, raised in one goroutine and read in another | an atomic | a single integer, and nothing else has to change with it |
| a map written from several goroutines | a mutex | several steps on one structure, which must look like one step |
| a slice that every goroutine appends to | stop sharing | each goroutine can own its own slot |
| results passed from workers to a collector | a channel | lessons 3 to 15: the value moves, and the memory goes with it |

## An atomic, for one number

`stats.go` from section 03 raises an `int` in one goroutine and reads it in another. The package
`sync/atomic` has types whose every operation is indivisible and synchronised, so a read through
`Load` sees a whole value written by `Add`, and the detector knows they are ordered. Edited,
saved again as `stats.go`:

```go
// Command stats counts requests in one goroutine while main reports them.
package main

import (
	"fmt"
	"sync/atomic"
	"time"
)

type stats struct {
	served atomic.Int64
}

func main() {
	s := &stats{}
	go serve(s)
	time.Sleep(10 * time.Millisecond)
	fmt.Println("served so far:", s.served.Load())
}

func serve(s *stats) {
	for {
		s.served.Add(1)
		time.Sleep(time.Millisecond)
	}
}
```

```
ana@vm:~/races$ go run -race stats.go
served so far: 10
```

The field changed type, and that is the point of the typed atomics: **an `atomic.Int64` has no
`++`**, so the compiler refuses every plain access you might forget. An atomic is right for one
counter or one flag. Two fields that must change together are not two atomics, because a reader
could see one changed and the other not; that needs a lock.

## A mutex, for a structure

`tally.go` does several things to the map on each `counts[w]++`: look the key up, add one, store
the result, perhaps grow the table. A mutex, lesson 8's subject, makes that whole sequence one
step as far as every other goroutine can tell. Edited, saved again as `tally.go`:

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
	var mu sync.Mutex
	var wg sync.WaitGroup
	for _, line := range lines {
		wg.Go(func() {
			for _, w := range strings.Fields(line) {
				mu.Lock()
				counts[w]++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	fmt.Println(counts)
}
```

```
ana@vm:~/races$ go run -race tally.go
map[a:1 cat:2 dog:1 end:1 ran:2 sat:1 the:3]
```

Same output as the plain runs before the fix, and that is worth saying plainly: **the fix did not
change the answer, because the answer was right by luck all along.** What changed is that it is
now right by construction, and the detector agrees.

## Stop sharing, for a slice

The third program collects the squares of a thousand numbers, each computed in a goroutine of its
own, by appending to one slice. Saved as `collect.go`:

```go
// Command collect squares a thousand numbers in a thousand goroutines.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var results []int
	var wg sync.WaitGroup
	for i := range 1000 {
		wg.Go(func() { results = append(results, i*i) })
	}
	wg.Wait()
	fmt.Println("results:", len(results))
}
```

```
ana@vm:~/races$ for i in 1 2 3; do go run collect.go; done
results: 865
results: 984
results: 868
ana@vm:~/races$ go run -race collect.go 2>&1 | tail -3
results: 578
Found 4 data race(s)
exit status 66
```

This one fails without the detector. `append` reads the slice's length, writes the new element
and stores a new length, and two goroutines that read the same length write into the same slot,
so squares vanish: 1,000 went in and the runs kept fewer, a different number each time. The last
command keeps only the end of the detector's output; its reports are the shape section 03 read.

A mutex around the `append` would work. But nothing here needs the goroutines to share a growing
slice at all. **The number of results is known before the first goroutine starts**, so the slice
can be made at full length and each goroutine given its own element. Different elements of a slice
are different memory, and the detector agrees. Edited, saved again as `collect.go`:

```go
// Command collect squares a thousand numbers in a thousand goroutines.
package main

import (
	"fmt"
	"sync"
)

func main() {
	results := make([]int, 1000)
	var wg sync.WaitGroup
	for i := range 1000 {
		wg.Go(func() { results[i] = i * i })
	}
	wg.Wait()
	fmt.Println("results:", len(results), "last:", results[999])
}
```

```
ana@vm:~/races$ go run -race collect.go
results: 1000 last: 998001
```

**No lock, no atomic, no channel, and no race**, because no two goroutines ever touch the same
element; the results also come back in order, which the appending version never promised. When a
design lets each goroutine own its memory, that is the cheapest fix there is.

## Choosing

The fourth row of the table is the one lessons 3 to 15 spent their time on: when a value is handed
over a channel, the sender stops using it and the receiver starts, so there is nothing left to
share. Choose by asking what the shared thing is. **One number: an atomic. A structure updated in
several steps: a mutex. Work whose results can be split up: give each goroutine its own. A value
that moves from one goroutine to another: a channel.** And whichever you pick, run the detector
again; a fix nobody re-ran is a guess.
