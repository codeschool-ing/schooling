---
title: The mutex, and the copy that breaks it
version: 1
---

Lesson 1 ended with `count.go`: four goroutines adding to one number, and five different wrong
totals. Lessons 3 to 7 avoided that problem by passing values through channels, so that only one
goroutine ever held each one. Sometimes the simplest design really is a variable that several
goroutines change. **A mutex makes that safe by letting one goroutine at a time into the code
between `Lock` and `Unlock`**, the critical section, and making every other goroutine wait at
`Lock` until it is free.

## `count.go`, repaired

The same program, with a `sync.Mutex` around the increment, saved as `count.go`:

```go
// Command count is lesson 1's count.go with a mutex around the shared number.
package main

import (
	"fmt"
	"sync"
)

func main() {
	total := 0
	var mu sync.Mutex
	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() {
			for range 100_000 {
				mu.Lock()
				total++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	fmt.Println("total:", total)
}
```

```
ana@vm:~/locks$ for i in 1 2 3; do go run count.go; done
total: 400000
total: 400000
total: 400000
ana@vm:~/locks$ go run -race count.go
total: 400000
```

Three runs, three right answers, and the race detector of lesson 1 has nothing to report: the
program printed its total and no warning. `mu.Lock()` and `mu.Unlock()` around `total++` turn the
read, the addition and the write into one step as far as the other goroutines can tell. Unlocking
also publishes the change: what one goroutine wrote before `Unlock` is visible to the next one
after its `Lock`, which is the promise lesson 1 listed.

Three habits go with it:

- **The zero value is an unlocked mutex.** `var mu sync.Mutex` is ready to use, with no
  constructor, and so is a struct that contains one.
- **`defer mu.Unlock()` right after `Lock`** in any function longer than a line. An early `return`
  or a panic between the two would otherwise leave the mutex locked, and every goroutine that comes
  after waits forever, the same shape as lesson 6's skipped `close`.
- **Keep the critical section short.** Everything inside it runs one goroutine at a time. Work that
  does not touch the shared data, a calculation, a log line, a network call, belongs outside.

## A mutex must not be copied

Most code puts the mutex beside the data it guards, in a struct, with methods that lock it. This
version makes one mistake, saved as `copied.go`:

```go
// Command copied keeps its counter and its mutex in a struct, and makes one mistake.
package main

import (
	"fmt"
	"sync"
)

// Counter is safe for use by several goroutines, if its methods are written right.
type Counter struct {
	mu sync.Mutex
	n  int
}

// Inc has a value receiver, so it works on a copy of the Counter.
func (c Counter) Inc() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.n++
}

func main() {
	var c Counter
	var wg sync.WaitGroup
	for range 4 {
		wg.Go(func() {
			for range 100_000 {
				c.Inc()
			}
		})
	}
	wg.Wait()
	fmt.Println("total:", c.n)
}
```

```
ana@vm:~/locks$ go run copied.go
total: 0
ana@vm:~/locks$ go vet copied.go
copied.go:16:9: Inc passes lock by value: command-line-arguments.Counter contains sync.Mutex
```

**Four hundred thousand calls and a total of zero.** `Inc` has a value receiver, `(c Counter)`, so
every call works on a fresh copy of the whole struct, its mutex included. It locks the copy's
mutex, increments the copy's `n`, and throws the copy away. The original never changes. Nothing
crashes and the race detector stays quiet, because each copy is touched by one goroutine only.

`go vet`, the checker lesson 4 of `go` introduced, knows this mistake by name. It points at the
receiver and says why. The fix is a pointer receiver, `func (c *Counter) Inc()`, and the rule
behind it covers more than methods: **once a mutex has been used, the value holding it must not be
copied**, whether by a value receiver, an assignment or passing the struct to a function by value.
