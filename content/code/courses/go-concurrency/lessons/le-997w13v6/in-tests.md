---
title: The race only a test can find
version: 1
---

The races so far were in programs that run their goroutines by themselves. **Most races are not.
They sit in a type that is safe when one goroutine uses it and wrong when two do**, and the program
that would make two use it at once is a server that does not exist yet. Nothing in the package
itself ever runs concurrently, so running it with `-race` finds nothing. A test has to make the
goroutines meet, and `go test -race` has to watch.

Lesson 25 starts the `testing` package properly. This section needs only three facts from it: a
test is a function named `TestSomething` in a file ending `_test.go`, it reports a failure with
`t.Errorf` or `t.Fatalf`, and `go test` runs every such function in a package.

## A cache that is fine on its own

The package remembers the answers of a slow lookup, so each key is looked up once. It lives in the
directory `cache` inside `~/races`, saved as `cache/cache.go`:

```go
// Package cache remembers the answers of a slow lookup.
package cache

// Cache asks lookup once per key and remembers the answer.
type Cache struct {
	lookup func(string) string
	seen   map[string]string
}

// New returns an empty Cache in front of lookup.
func New(lookup func(string) string) *Cache {
	return &Cache{lookup: lookup, seen: map[string]string{}}
}

// Get returns the answer for key, asking lookup only the first time.
func (c *Cache) Get(key string) string {
	if v, ok := c.seen[key]; ok {
		return v
	}
	v := c.lookup(key)
	c.seen[key] = v
	return v
}
```

Two tests beside it. The first checks the promise in the comment, one lookup per key. The second
is the one this section is about: it calls `Get` from six goroutines at once, with some keys
repeated, which is what a server handling six requests would do. Saved as `cache/cache_test.go`:

```go
package cache

import (
	"strings"
	"sync"
	"testing"
)

func TestGet(t *testing.T) {
	calls := 0
	c := New(func(k string) string { calls++; return strings.ToUpper(k) })
	for range 3 {
		if got := c.Get("go"); got != "GO" {
			t.Fatalf("Get(%q) = %q, want %q", "go", got, "GO")
		}
	}
	if calls != 1 {
		t.Errorf("lookup ran %d times, want 1", calls)
	}
}

func TestGetFromManyGoroutines(t *testing.T) {
	c := New(strings.ToUpper)
	var wg sync.WaitGroup
	for _, k := range []string{"a", "b", "a", "c", "b", "a"} {
		wg.Go(func() {
			if got := c.Get(k); got != strings.ToUpper(k) {
				t.Errorf("Get(%q) = %q", k, got)
			}
		})
	}
	wg.Wait()
}
```

## Green, and wrong

```
ana@vm:~/races$ go test ./cache
ok  	example.com/races/cache	0.002s
ana@vm:~/races$ go test -count=5 ./cache
ok  	example.com/races/cache	0.002s
```

**Six passing runs, and the type is broken.** Every answer the tests checked was right, because a
wrong answer was never the risk: the risk was two goroutines writing the map at the same moment,
which a check on the answers cannot see. `-count=5` ran the tests five times over, and asking again
did not help, because what decides the outcome is timing, and timing was kind every time.

With the detector the same tests fail:

```
ana@vm:~/races$ go test -race ./cache > race.log 2>&1; echo $?
1
ana@vm:~/races$ head -17 race.log
==================
WARNING: DATA RACE
Read at 0x00c0001166c0 by goroutine 11:
  runtime.mapaccess2_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:120 +0x0
  example.com/races/cache.(*Cache).Get()
      /home/ana/races/cache/cache.go:17 +0x64
  example.com/races/cache.TestGetFromManyGoroutines.func1()
      /home/ana/races/cache/cache_test.go:27 +0x5e

Previous write at 0x00c0001166c0 by goroutine 13:
  runtime.mapassign_faststr()
      /usr/local/go/src/internal/runtime/maps/runtime_faststr.go:261 +0x0
  example.com/races/cache.(*Cache).Get()
      /home/ana/races/cache/cache.go:21 +0xdb
  example.com/races/cache.TestGetFromManyGoroutines.func1()
      /home/ana/races/cache/cache_test.go:27 +0x5e
```

`head -17` kept the first report's two accesses, and they read the way section 03 taught. Line 21
of `cache.go` is `c.seen[key] = v`, the write; line 17 is `if v, ok := c.seen[key]; ok`, the read.
Both stacks run up through `TestGetFromManyGoroutines.func1()` at line 27 of the test, the
`c.Get(k)` inside the goroutine. The end of the output is the test's verdict:

```
ana@vm:~/races$ tail -5 race.log
--- FAIL: TestGetFromManyGoroutines (0.00s)
    testing.go:1865: race detected during execution of test
FAIL
FAIL	example.com/races/cache	0.032s
FAIL
```

**`race detected during execution of test` turns a report into a failing test.** That is what
makes the detector usable in CI: nobody has to read the output for the run to go red.

## The fix, and the run that proves it

Every access to `seen` happens inside `Get`, so one mutex held for the whole of `Get` covers them
all. Edited, saved again as `cache/cache.go`:

```go
// Package cache remembers the answers of a slow lookup.
package cache

import "sync"

// Cache asks lookup once per key and remembers the answer.
// It is safe for use by several goroutines at once.
type Cache struct {
	lookup func(string) string
	mu     sync.Mutex
	seen   map[string]string
}

// New returns an empty Cache in front of lookup.
func New(lookup func(string) string) *Cache {
	return &Cache{lookup: lookup, seen: map[string]string{}}
}

// Get returns the answer for key, asking lookup only the first time.
func (c *Cache) Get(key string) string {
	c.mu.Lock()
	defer c.mu.Unlock()
	if v, ok := c.seen[key]; ok {
		return v
	}
	v := c.lookup(key)
	c.seen[key] = v
	return v
}
```

```
ana@vm:~/races$ go test -race -count=20 ./cache
ok  	example.com/races/cache	1.018s
```

Clean, twenty times over with the detector watching. The doc comment now says what the type
promises, which is part of the fix: whoever uses `Cache` next can read that it is safe from
several goroutines without opening the file.

Holding the lock across `lookup` has a price. Two goroutines asking for two different keys wait
for each other's slow lookup, and lesson 8 shows how to hold a lock for less time and lesson 9 how
`sync.Map` and `sync.OnceValue` change the trade. **Correct first, then fast**, and the detector
re-run after every change of that kind.

## The habit, and the end of the first half

Three habits come out of this lesson. Run `go test -race ./...` on every change, in CI and on
your own machine. Write a test that calls a type from several goroutines whenever the type says it
is safe for that. And when a report appears, read its two accesses before touching the code.

**This lesson closes the concurrency half of the course**: goroutines, channels, `select`, the
`sync` package, `context`, the patterns and now the tool that checks them. Lesson 17 opens the
second half, the standard library a Go program is built from, starting with the two interfaces
almost all of it reads and writes through.
