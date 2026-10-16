---
title: A map built for concurrent use
version: 1
---

An ordinary Go map is not safe for concurrent use, and unlike most races this one does not stay
quiet. **The runtime checks for simultaneous writes to a map and stops the program with a fatal
error**, one no `recover` can catch. Saved as `crash.go`:

```go
// Command crash writes to an ordinary map from four goroutines with no lock.
package main

import (
	"fmt"
	"sync"
)

func main() {
	seen := map[int]bool{}
	var wg sync.WaitGroup
	for g := range 4 {
		wg.Go(func() {
			for i := range 100_000 {
				seen[g*100_000+i] = true
			}
		})
	}
	wg.Wait()
	fmt.Println("entries:", len(seen))
}
```

```
ana@vm:~/waitonce$ go run crash.go
fatal error: concurrent map writes

goroutine 19 [running]:
internal/runtime/maps.fatal({0x49dfd5?, 0x0?})
	/usr/local/go/src/runtime/panic.go:1195 +0x18
main.main.func1()
	/home/ana/waitonce/crash.go:15 +0x45
sync.(*WaitGroup).Go.func1()
	/usr/local/go/src/sync/waitgroup.go:258 +0x4a
created by sync.(*WaitGroup).Go in goroutine 1
	/usr/local/go/src/sync/waitgroup.go:238 +0x7d
exit status 2
```

`fatal error: concurrent map writes`, at line 15, which is the assignment. The check is cheap and
does not catch every case: two writes that never overlap in time pass it, and a read during a write
can produce `concurrent map read and map write`. The race detector, lesson 16's subject, reports all
of them. The usual repair is the one lesson 8 taught, a `sync.Mutex` beside
the map.

## `sync.Map`

The standard library also has a map type with the locking inside it. Its methods take and return
`any`: `Store`, `Load`, `LoadOrStore`, `LoadAndDelete`, `Delete`, `Swap`, `CompareAndSwap`, `Range`
and `Clear`. The program below records the first visitor of each page from six goroutines, with
`LoadOrStore`, which stores a value only if the key is absent and reports which value is there.
Saved as `syncmap.go`:

```go
// Command syncmap counts the first visitor of each page with a sync.Map.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var first sync.Map // page -> name of the first visitor
	visits := []struct{ page, who string }{
		{"/home", "ana"}, {"/home", "bia"}, {"/docs", "caio"},
		{"/docs", "ana"}, {"/home", "caio"}, {"/blog", "bia"},
	}
	var wg sync.WaitGroup
	for _, v := range visits {
		wg.Go(func() {
			first.LoadOrStore(v.page, v.who)
		})
	}
	wg.Wait()

	who, ok := first.Load("/blog")
	fmt.Println("/blog:", who, ok)
	_, ok = first.Load("/about")
	fmt.Println("/about:", ok)
	n := 0
	first.Range(func(key, value any) bool {
		n++
		return true
	})
	fmt.Println("pages:", n)
}
```

```
ana@vm:~/waitonce$ go run syncmap.go
/blog: bia true
/about: false
pages: 3
```

Three pages, six visits, and `/blog` had one visitor, `bia`. Which visitor was first on `/home` and
`/docs` depended on which goroutine reached `LoadOrStore` first, so the program does not print it. A
missing key is reported by the second result, `false`, as with an ordinary map's comma-ok.

## When to use it, and when not

The documentation of `sync.Map` is unusually direct about this: **most code should use an ordinary
map with its own locking**, for type safety and because it is easier to keep other state consistent
with it. `sync.Map` is optimised for two cases:

1. a key is written once and read many times, as in a cache that only grows;
2. several goroutines read, write and overwrite **disjoint** sets of keys.

In those two, it can mean much less waiting than a map behind one `Mutex` or `RWMutex`. Outside them
it loses the map's types, every `Load` needs a type assertion, and `Range` is not a snapshot of one
moment. So the order of preference is a map with a `Mutex`, then an `RWMutex` if measurement says
readers wait, and `sync.Map` when the access pattern is one of the two above.
