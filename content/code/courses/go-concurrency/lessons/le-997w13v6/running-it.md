---
title: Running it, and what it costs
version: 1
---

Lesson 1 met the race detector once, on `count.go`, and lessons 2 to 15 have used it as a check
in passing. This lesson makes it the subject. **The race detector is not a separate program you
point at your code; it is a different build of your code**, compiled so that every read and every
write of memory goes through ThreadSanitizer first. ThreadSanitizer keeps, beside each piece of
memory, a short history of which goroutine touched it last and what that goroutine had
synchronised with. When two accesses meet with no synchronisation between them and at least one
is a write, it prints a report.

The flag is the same for every go command that builds something:

| command | what `-race` gives you |
|---|---|
| `go run -race file.go` | builds and runs one program with the detector inside |
| `go build -race` | a binary with the detector inside, to run as often as you like |
| `go test -race ./...` | every test of every package, with the detector watching |
| `go install -race` | the same as `build`, installed in `~/go/bin` |

## What the extra checking costs

Every memory access now does extra work, and the history needs memory of its own. The way to
know how much is to measure it. This lesson works in `~/races`, made with
`go mod init example.com/races`, and its first program has four goroutines share a map under a
mutex, which is lesson 8's tool, and reports its own peak memory as the kernel counted it. It has
no race in it, so the detector has nothing to report and only its cost shows. Saved as `cost.go`:

```go
// Command cost does a fixed amount of shared work under a mutex and reports its peak memory.
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"sync"
)

func main() {
	var mu sync.Mutex
	counts := make(map[int]int)
	var wg sync.WaitGroup
	for g := range 4 {
		wg.Go(func() {
			for i := range 500_000 {
				mu.Lock()
				counts[(g+i)%1000]++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	fmt.Println("keys:", len(counts), "peak memory:", peak())
}

// peak reads the most memory the process has held, as the kernel counts it.
func peak() string {
	f, err := os.Open("/proc/self/status")
	if err != nil {
		return "unknown"
	}
	defer f.Close()
	s := bufio.NewScanner(f)
	for s.Scan() {
		if v, ok := strings.CutPrefix(s.Text(), "VmHWM:"); ok {
			return strings.TrimSpace(v)
		}
	}
	return "unknown"
}
```

Built twice, once plainly and once with the detector, and timed with the shell's `time`:

```
ana@vm:~/races$ go build -o cost cost.go
ana@vm:~/races$ go build -race -o cost-race cost.go
ana@vm:~/races$ ls -l cost cost-race
-rwxr-xr-x 1 ana ana 2387083 Oct 16 19:27 cost
-rwxr-xr-x 1 ana ana 2976269 Oct 16 19:27 cost-race
ana@vm:~/races$ time ./cost
keys: 1000 peak memory: 2296 kB

real	0m0.156s
user	0m0.306s
sys	0m0.009s
ana@vm:~/races$ time ./cost-race
keys: 1000 peak memory: 21056 kB

real	0m1.852s
user	0m1.097s
sys	0m0.140s
```

**The same program took 1.852 seconds instead of 0.156, about twelve times as long, and held 21,056 kB
of memory at its peak instead of 2,296, about nine times as much.** The binary grew by under
600 kB, from 2,387,083 bytes to 2,976,269: the instrumentation is small, and the cost is paid while
the program runs. Those ratios belong to this program, which does almost nothing but take a lock
and touch a map, so nearly every instruction it runs is one the detector checks. A program that
spends its time waiting on a network pays far less, because waiting touches no memory.

## Where it belongs

Those numbers decide where the detector runs. **It belongs in your tests and in your own runs
while you develop, and in CI on every change**: `go test -race ./...` is the single most useful
line this course adds to a project. It does not belong in the binary you ship, where the slowdown
and the memory are paid by every user for a check that only helps the person reading its report.

Two more facts shape how it is used. **It finds only the races that happen while it watches**, so
a race on a path no test takes stays invisible, which is why section 05 of this lesson writes a
test whose whole job is to make the goroutines meet. And it reports rather than stops: the
program carries on after each report and exits with status 66 at the end, so a script or a CI
job can tell a clean run from a dirty one without reading the text.
