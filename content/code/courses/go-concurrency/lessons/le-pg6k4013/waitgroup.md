---
title: Waiting for goroutines with a WaitGroup
version: 1
---

Every lesson so far has used `wg.Go` and `wg.Wait` and promised the details here. **A
`sync.WaitGroup` is a counter of goroutines still running, with a `Wait` that blocks until the
counter is back at zero.** `Add` raises it, `Done` lowers it by one, and `wg.Go`, new in Go 1.25,
does both for you around a function.

## The long way

Before Go 1.25 every program wrote the three calls by hand, and most code you will read still does.
Saved as `wait.go`:

```go
// Command wait downloads three pretend files and waits for all of them, the long way.
package main

import (
	"fmt"
	"sync"
	"time"
)

func download(name string) {
	time.Sleep(20 * time.Millisecond)
	fmt.Println("downloaded", name)
}

func main() {
	var wg sync.WaitGroup
	for _, name := range []string{"a.txt", "b.txt", "c.txt"} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			download(name)
		}()
	}
	wg.Wait()
	fmt.Println("all three done")
}
```

```
ana@vm:~/waitonce$ go run wait.go
downloaded b.txt
downloaded a.txt
downloaded c.txt
all three done
```

`wg.Add(1)` runs in `main`, before the goroutine starts; `defer wg.Done()` is the goroutine's first
line, so it runs however the goroutine ends. The three downloads finished in an order nobody chose,
lesson 1's point again, and `all three done` came after all of them. **`wg.Go(f)` is exactly this
pattern**, an `Add(1)` before starting `f` and a `Done` after it returns, and it leaves no room for
either of the two mistakes below.

## `Add` one line too late

The tempting variation moves `Add` into the goroutine beside `Done`, where it looks tidier. Saved
as `late.go`:

```go
// Command late calls Add inside the goroutine, which is one line too late.
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

func main() {
	var finished atomic.Int64
	var wg sync.WaitGroup
	for range 5 {
		go func() {
			wg.Add(1)
			defer wg.Done()
			time.Sleep(10 * time.Millisecond)
			finished.Add(1)
		}()
	}
	wg.Wait()
	fmt.Println("finished when Wait returned:", finished.Load())
}
```

```
ana@vm:~/waitonce$ go run late.go
finished when Wait returned: 0
ana@vm:~/waitonce$ go vet late.go
late.go:16:10: WaitGroup.Add called from inside new goroutine
```

**Five goroutines started, and `Wait` returned before any of them finished.** `main` reached `Wait`
while the counter was still zero, because none of the goroutines had yet been scheduled to run their
`Add`. A counter of zero means nothing to wait for, so `Wait` returned at once. The rule is that
**`Add` must happen before the `go` statement**, in the goroutine that will call `Wait`. `go vet`
knows it, as the second command shows, and `wg.Go` makes it impossible.

## A counter below zero

The opposite mistake, one `Done` more than the `Add`s, is not silent at all. Saved as
`negative.go`:

```go
// Command negative calls Done once more than it called Add.
package main

import "sync"

func main() {
	var wg sync.WaitGroup
	wg.Add(1)
	wg.Done()
	wg.Done()
}
```

```
ana@vm:~/waitonce$ go run negative.go
panic: sync: negative WaitGroup counter

goroutine 1 [running]:
sync.(*WaitGroup).Add(0xc25eaf9e000, 0xffffffffffffffff)
	/usr/local/go/src/sync/waitgroup.go:118 +0x23a
sync.(*WaitGroup).Done(...)
	/usr/local/go/src/sync/waitgroup.go:156
main.main()
	/home/ana/waitonce/negative.go:10 +0x58
exit status 2
```

The counter would have gone to minus one, and the `WaitGroup` panics rather than allow it. In real
code the cause is a `Done` on a path that also returns early through another `defer`, or a
goroutine started twice for one `Add`. And like a mutex, a `WaitGroup` must not be copied after
first use: a function that receives one takes `*sync.WaitGroup`, or the `Done` lowers the counter of
a copy and the original `Wait` waits forever.
