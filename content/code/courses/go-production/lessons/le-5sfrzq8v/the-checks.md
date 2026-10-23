---
title: Bugs that compile and run
version: 1
---

Each program in this section **compiles, runs, and prints something that looks like an answer**. That
is what makes them worth a tool: a program that crashes on its first run gets fixed before anybody
commits it, and these do not. Each is saved in `~/vetted` beside `report`, run once so you can see
what the bug does, and then shown to vet.

## `printf`, again: a wrapped error that cannot be found

The `printf` analyzer of section 02 also knows about `%w`, the verb `fmt.Errorf` uses to wrap one
error inside another. Save `notfound/main.go`:

```go
// Command notfound wraps an error and then asks what it was.
package main

import (
	"errors"
	"fmt"
)

// NotFound says which path had nothing behind it.
type NotFound struct{ Path string }

func (e NotFound) Error() string { return e.Path + ": not found" }

func open(path string) error {
	return fmt.Errorf("open: %w", &NotFound{path})
}

func main() {
	err := open("/api/orders/43")
	var nf NotFound
	fmt.Println(err)
	fmt.Println("is NotFound:", errors.As(err, &nf))
}
```

```
ana@vm:~/vetted$ go run ./notfound
open: /api/orders/43: not found
is NotFound: false
ana@vm:~/vetted$ go vet ./notfound
notfound/main.go:15:27: %w wants operand of error type NotFound, not pointer type *NotFound (defeats errors.Is)
```

The message reads well and the question gets the wrong answer. **`Error` has a value receiver, so the
error type is `NotFound`, and `open` wrapped a `*NotFound`**, a different type that `errors.As` will
not match against a `NotFound` target. A caller that turns a `NotFound` into a 404 would turn this one
into a 500 instead. This check is new in Go 1.27 and, as section 02 said, applies only to files whose
module declares at least that version. The fix is `fmt.Errorf("open: %w", NotFound{path})`.

## `copylocks`: a mutex that locks nothing

A type that embeds a `sync.Mutex` is safe only while everybody shares the same mutex.
`counter/main.go`:

```schooling-example
{
  "language": "go",
  "file": "counter/main.go",
  "parts": [
    {
      "code": "// Command counter counts requests per path from several goroutines.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"sync\"\n)\n\n// Counter is safe for concurrent use. Or so its author thought.\ntype Counter struct {\n\tmu sync.Mutex\n\tn  map[string]int\n}\n",
      "note": "A mutex beside the map it guards: the usual shape, and correct as long as every caller locks the same mutex."
    },
    {
      "code": "func (c Counter) Add(path string) {\n\tc.mu.Lock()\n\tdefer c.mu.Unlock()\n\tc.n[path]++\n}\n",
      "note": "**The receiver is a value, so every call works on a copy of the `Counter`, mutex included.** Each goroutine locks a mutex nobody else holds. The map is copied too, but a map value is a reference to one table, so all eight write to the same one."
    },
    {
      "code": "func main() {\n\tc := Counter{n: map[string]int{}}\n\tvar wg sync.WaitGroup\n\tfor range 8 {\n\t\twg.Go(func() {\n\t\t\tfor range 10000 {\n\t\t\t\tc.Add(\"/login\")\n\t\t\t}\n\t\t})\n\t}\n\twg.Wait()\n\tfmt.Println(c.n[\"/login\"])\n}",
      "note": "Eight goroutines adding ten thousand times each. `wg.Go`, added in Go 1.25, does the `Add`, the `go` and the `Done` in one call. A correct counter prints 80000."
    }
  ]
}
```

```
ana@vm:~/vetted$ go run ./counter 2>&1 | head -1
fatal error: concurrent map writes
ana@vm:~/vetted$ go vet ./counter
counter/main.go:15:9: Add passes lock by value: example.com/vetted/counter.Counter contains sync.Mutex
```

`fatal error` is the runtime's own map check catching two goroutines writing at once, and it ended the
process on every run here, with a goroutine dump below the line `head` kept. **A test that called
`Add` from one goroutine would pass**, which is exactly the test section 04 writes. Vet does not need
to run anything: it sees a method whose receiver is a value of a type containing a lock, and that is
enough. The fix is a pointer receiver, `func (c *Counter) Add`. `go-concurrency` lesson 16's race
detector finds the same bug, but only when a test happens to run two goroutines into it.

## `lostcancel`: a context that outlives its call

`context.WithTimeout` returns a function that releases the context's timer, and it must be called on
every path. `fetch/main.go`:

```go
// Command fetch waits for a slow answer, but not forever.
package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

func slow(ctx context.Context) error {
	select {
	case <-time.After(50 * time.Millisecond):
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

func fetch(parent context.Context, path string) error {
	ctx, cancel := context.WithTimeout(parent, 2*time.Second)
	if path == "" {
		return errors.New("no path to fetch")
	}
	defer cancel()
	return slow(ctx)
}

func main() {
	fmt.Println(fetch(context.Background(), "/api/orders"))
	fmt.Println(fetch(context.Background(), ""))
}
```

```
ana@vm:~/vetted$ go run ./fetch
<nil>
no path to fetch
ana@vm:~/vetted$ go vet ./fetch
fetch/main.go:21:2: the cancel function is not used on all paths (possible context leak)
fetch/main.go:23:3: this return statement may be reached without using the cancel var defined on line 21
```

**Both answers are right, and that is the problem**: the bug has no output. Every call that takes the
early return leaves a context and its timer alive for two seconds, until the timeout fires. On a
server doing that thousands of times a second, the leak is memory that grows with traffic. Vet reads
the control flow, finds the path from `WithTimeout` to a `return` that never meets `cancel`, and
names both lines. Moving `defer cancel()` up to the line after `WithTimeout` fixes it.

## `structtag`: a JSON field with the wrong name

A struct tag is a string the compiler does not read, and `encoding/json` reads it at run time with
`reflect.StructTag.Get`, which gives up on a tag it cannot parse. `rows/main.go`:

```go
// Command rows prints the busiest paths as JSON.
package main

import (
	"encoding/json"
	"os"
)

type PathCount struct {
	Path string `json:"path"`
	Hits int    `json: "hits"`
}

func main() {
	rows := []PathCount{{"/login", 2576}, {"/health", 2541}}
	json.NewEncoder(os.Stdout).Encode(rows)
}
```

```
ana@vm:~/vetted$ go run ./rows
[{"path":"/login","Hits":2576},{"path":"/health","Hits":2541}]
ana@vm:~/vetted$ go vet ./rows
rows/main.go:11:2: struct field tag `json: "hits"` not compatible with reflect.StructTag.Get: bad syntax for struct tag value
```

One space after the colon, and `Hits` came out under its Go name. **Nothing failed, because a
malformed tag is treated as no tag at all**, and a client reading `hits` now reads nothing, or a zero.
Vet parses every tag the way `reflect` would and says where it stopped making sense.

## Four smaller ones

`dedup/main.go` keeps one copy of each path from a sorted list:

```go
// Command dedup prints each path once, from a sorted list.
package main

import (
	"fmt"
	"slices"
)

func main() {
	paths := []string{"/", "/health", "/health", "/login", "/login", "/login"}
	slices.Compact(paths)
	fmt.Printf("%d paths: %q\n", len(paths), paths)
}
```

```
ana@vm:~/vetted$ go run ./dedup
6 paths: ["/" "/health" "/login" "" "" ""]
ana@vm:~/vetted$ go vet ./dedup
dedup/main.go:11:2: result of slices.Compact call not used
```

**`slices.Compact` returns the shorter slice and leaves the caller's slice header alone**, with the
tail it no longer uses zeroed, so the program printed six paths of which three are empty. `unusedresult`
keeps a list of standard library functions whose result is the whole point of calling them,
`slices.Compact`, `fmt.Sprintf` and `errors.New` among them, and reports a call that throws it away.
The fix is `paths = slices.Compact(paths)`.

`header/main.go` reads a 16-bit length from two bytes:

```go
// Command header reads a 16-bit length from the first two bytes of a record.
package main

import "fmt"

func length(b []byte) uint16 {
	hi, lo := b[0], b[1]
	return uint16(hi<<8 | lo)
}

func main() {
	fmt.Println(length([]byte{0x01, 0x2c}))
}
```

```
ana@vm:~/vetted$ go run ./header
44
ana@vm:~/vetted$ go vet ./header
header/main.go:8:16: hi (8 bits) too small for shift of 8
```

`0x012c` is 300. **The shift happened on `hi`, a `byte`, before the conversion**, so the high byte
was shifted out of its eight bits entirely and only `lo`, 44, survived. `shift` reports a shift as
wide as the type, or wider. The fix is `uint16(hi)<<8 | uint16(lo)`.

`limit/main.go` lets the first `n` requests through, and carries two mistakes:

```go
// Command limit lets the first n requests through and refuses the rest.
package main

import "fmt"

type Limiter struct {
	limit int
	seen  int
}

func NewLimiter(limit int) *Limiter {
	l := &Limiter{}
	l.limit = l.limit
	return l
}

func (l *Limiter) Allow() bool {
	l.seen++
	return l.seen <= l.limit
	fmt.Println("over the limit")
	return false
}

func main() {
	l := NewLimiter(3)
	fmt.Println(l.Allow(), l.Allow(), l.Allow())
}
```

```
ana@vm:~/vetted$ go run ./limit
false false false
ana@vm:~/vetted$ go vet ./limit
limit/main.go:13:2: self-assignment of l.limit
limit/main.go:20:2: unreachable code
```

A limit of three refused all three requests. **`l.limit = l.limit` assigns the zero to itself**,
where `l.limit = limit` was meant, and `assign` reports any `x = x`. The `return` above the
`Println` makes the last two lines dead, which `unreachable` reports: here the dead code is a log line
somebody expected to see, and its absence would have been the only clue. Neither is a compiler error,
because Go rejects an unused variable and does not reject an unused statement.
