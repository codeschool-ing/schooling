---
title: Doing something exactly once
version: 1
---

Some work should happen once in the life of a program and not before it is needed: reading a
configuration file, opening a connection pool, compiling a large regular expression. With
goroutines the obvious version, *if it is not loaded yet, load it*, is a race, because two
goroutines can both see "not loaded yet". **`sync.Once` runs a function the first time `Do` is
called and never again, and every other caller waits until that first run has finished.**

## `sync.Once`

Eight goroutines ask for a configuration at the same moment, and a counter records how many times
it was loaded. Saved as `once.go`:

```go
// Command once loads a configuration lazily, from eight goroutines, exactly once.
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

var loads atomic.Int64

type Config struct{ Workers int }

func load() Config {
	loads.Add(1)
	time.Sleep(10 * time.Millisecond) // reading a file, say
	return Config{Workers: 4}
}

var (
	once   sync.Once
	config Config
)

// Get returns the configuration, loading it on the first call.
func Get() Config {
	once.Do(func() { config = load() })
	return config
}

func main() {
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() { _ = Get().Workers })
	}
	wg.Wait()
	fmt.Println("callers: 8  loads:", loads.Load(), " workers:", Get().Workers)
}
```

```
ana@vm:~/waitonce$ go run once.go
callers: 8  loads: 1  workers: 4
```

Eight callers, one load. The seven goroutines that arrived while the first was still inside `load`
waited for it, so none of them saw an empty `Config`. That waiting is the part a hand-written flag
gets wrong: a boolean set at the start of the work tells the others *somebody is loading*, not *it
is ready*.

## `OnceValue` and `OnceValues`

Go 1.21 added three functions that wrap the pattern without the two package-level variables.
`sync.OnceFunc(f)` returns a function that calls `f` once; `sync.OnceValue(f)` does the same and
returns `f`'s result to every caller; `sync.OnceValues(f)` returns a result and an error. The one
worth a demonstration is the last, because of what it does with the error. It is run in a
directory with no `token.txt`, and saved as `oncevalues.go`:

```go
// Command oncevalues caches a result and an error with sync.OnceValues.
package main

import (
	"fmt"
	"os"
	"sync"
)

var attempts int

// token reads the file at most once, however many times it is called.
var token = sync.OnceValues(func() (string, error) {
	attempts++
	b, err := os.ReadFile("token.txt")
	return string(b), err
})

func main() {
	for range 3 {
		t, err := token()
		fmt.Printf("token %q, err %v\n", t, err)
	}
	os.WriteFile("token.txt", []byte("s3cr3t"), 0o600)
	t, err := token()
	fmt.Printf("after writing the file: token %q, err %v\n", t, err)
	fmt.Println("attempts:", attempts)
}
```

```
ana@vm:~/waitonce$ go run oncevalues.go
token "", err open token.txt: no such file or directory
token "", err open token.txt: no such file or directory
token "", err open token.txt: no such file or directory
after writing the file: token "", err open token.txt: no such file or directory
attempts: 1
```

**The error was cached as faithfully as a result would have been.** The file did not exist on the
first call, so every later call got the same error, including the one after the file had been
written. `attempts: 1` says the file was read once. That is correct behaviour for "do this once",
and wrong for "do this until it works". If a failed first attempt should be retried, `Once` is the
wrong tool, and a mutex around a "loaded" flag that is set only on success is the right one.

One more rule from the documentation of `sync.Once`: if the function passed to `Do` panics, `Do`
considers it done, and later calls do not run it again.
