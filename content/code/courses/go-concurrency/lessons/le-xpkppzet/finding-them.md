---
title: Finding a leak, and where it is
version: 1
---

A count says that something leaked. It does not say what. **The runtime can name the line every
goroutine is stopped at**, and since the goroutines of a leak are all stopped at the same line, the
answer usually stands out from everything else. This section asks the runtime three questions, from
the cheapest to the most precise.

## How many: `runtime.NumGoroutine`

Section 02 already used it. One number, cheap enough to read on every request, and the one worth
putting on a dashboard: **a service at rest that has more goroutines every hour is leaking**,
whatever else is true. What it cannot say is which goroutines they are.

## Where: the goroutine profile

The package `runtime/pprof` keeps several profiles, and the one called `goroutine` is a list of
every goroutine with the stack it is stopped in. Asked with a debug level of 1, it groups
goroutines that share a stack and counts them. The program below leaks exactly as `first.go` did,
then prints a profile; its name comes from the command line and defaults to `goroutine`. Saved as
`find.go`:

```go
// Command find leaks the way first.go does, then asks the runtime where.
package main

import (
	"fmt"
	"os"
	"runtime/pprof"
	"time"
)

func ask(server int) string {
	time.Sleep(time.Duration(server) * 10 * time.Millisecond)
	return fmt.Sprint("answer from server ", server)
}

func first() string {
	ch := make(chan string)
	for s := 1; s <= 3; s++ {
		go func() { ch <- ask(s) }()
	}
	return <-ch
}

func main() {
	for range 100 {
		first()
	}
	time.Sleep(100 * time.Millisecond)
	profile := "goroutine"
	if len(os.Args) > 1 {
		profile = os.Args[1]
	}
	pprof.Lookup(profile).WriteTo(os.Stdout, 1)
}
```

```
ana@vm:~/leaks$ go run find.go
goroutine profile: total 201
200 @ 0x47d82a 0x41421c 0x413e17 0x4dea1e 0x483561
#	0x4dea1d	main.first.func1+0x3d	/home/ana/leaks/find.go:19

1 @ 0x440e11 0x47cb9d 0x4cc871 0x4cc545 0x4c94a9 0x4de9bd 0x44aa27 0x483561
#	0x4cc870	runtime/pprof.writeRuntimeProfile+0xb0	/usr/local/go/src/runtime/pprof/pprof.go:848
#	0x4cc544	runtime/pprof.writeGoroutine+0x44	/usr/local/go/src/runtime/pprof/pprof.go:781
#	0x4c94a8	runtime/pprof.(*Profile).WriteTo+0x148	/usr/local/go/src/runtime/pprof/pprof.go:405
#	0x4de9bc	main.main+0x7c				/home/ana/leaks/find.go:33
#	0x44aa26	runtime.main+0x426			/usr/local/go/src/runtime/proc.go:302

```

Read it from the top. `total 201` is the same number `NumGoroutine` would give. Then one entry per
distinct stack, largest first: **200 goroutines stopped at line 19 of `find.go`**, which is
`go func() { ch <- ask(s) }()`, inside the function literal the compiler named `main.first.func1`.
The other entry is `main` itself, caught in the act of writing the profile. Two hundred goroutines
on one send is the leak, with its address.

In a server you would not print this to the terminal. The package `net/http/pprof` serves the same
profiles over HTTP, and lesson 12 of `go-production` covers it; the reading is the same.

## Which ones are stuck for good: the leak profile

The goroutine profile lists every goroutine, the healthy ones too, and in a busy server the leak
is one entry among thousands. Go 1.27 has a second profile, `goroutineleak`, that lists only the
goroutines it can prove will never run again. Writing it starts a garbage collection that looks
for goroutines blocked on a channel, a lock or a `WaitGroup` that **no goroutine still running can
reach**: if nothing can ever send, receive or unlock, the wait cannot end. The same program, asked
for that profile:

```
ana@vm:~/leaks$ go run find.go goroutineleak
goroutineleak profile: total 200
200 @ 0x47d82a 0x41421c 0x413e17 0x4dea1e 0x483561
#	0x4dea1d	main.first.func1+0x3d	/home/ana/leaks/find.go:19

```

The 200 and nothing else. `main` is not in it, because `main` is running.

**The proof is about reachability, and that is also its limit.** If the channel can still be
reached from somewhere, the collector cannot prove nobody will use it, and says nothing. Here the
channel is kept in a package-level variable instead of a local one, and every goroutine still
leaks, saved as `hidden.go`:

```go
// Command hidden leaks like first.go, but through a channel a global variable keeps.
package main

import (
	"fmt"
	"os"
	"runtime"
	"runtime/pprof"
	"time"
)

var answers = make(chan string)

func ask(server int) string {
	time.Sleep(time.Duration(server) * 10 * time.Millisecond)
	return fmt.Sprint("answer from server ", server)
}

func first() string {
	for s := 1; s <= 3; s++ {
		go func() { answers <- ask(s) }()
	}
	return <-answers
}

func main() {
	for range 100 {
		first()
	}
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutines:", runtime.NumGoroutine())
	pprof.Lookup("goroutineleak").WriteTo(os.Stdout, 1)
}
```

```
ana@vm:~/leaks$ go run hidden.go
goroutines: 201
goroutineleak profile: total 0
```

Two hundred leaked goroutines and a leak profile of zero. A global variable lives as long as the
program, so as far as the collector can tell, somebody might yet receive from `answers`. **An empty
leak profile means no leak it could prove, not no leak.** The count and the goroutine profile
still see these 200, which is why the cheap number stays on the dashboard.
