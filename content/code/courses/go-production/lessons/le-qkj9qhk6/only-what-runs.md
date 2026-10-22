---
title: It sees only what runs
version: 1
---

The usual mental model of the race detector is a checker that reads the code and finds the races in
it. **It reads nothing. It watches one run of the program**, records every access the instrumented
code makes, and reports two accesses from different goroutines that nothing ordered. A race on a
line the run never reached, or on a line only one goroutine reached, did not happen in that run,
and the detector has nothing to say about it. So a green `go test -race` means "no race in what
these tests made the code do", and what the tests made the code do is your choice.

## Two tests that cannot see it

Both of these look like reasonable tests of `CountParallel`. The first pins the number of workers to
one, so that its result can never depend on timing. The second passes zero, the way `pcount` calls
it. Saved beside the others, `internal/tally/quiet_test.go`:

```go
package tally

import "testing"

// One worker, so that the test cannot be flaky.
func TestCountParallelOneWorker(t *testing.T) { checkParallel(t, 1) }

// One worker per CPU, the way pcount calls it.
func TestCountParallelDefault(t *testing.T) { checkParallel(t, 0) }
```

The code still has the race of section 02. The first test, with the detector watching:

```
ana@vm:~/race-hits$ go test -race -count=1 -run OneWorker -v ./internal/tally
=== RUN   TestCountParallelOneWorker
--- PASS: TestCountParallelOneWorker (0.00s)
PASS
ok  	example.com/hits/internal/tally	1.016s
```

**Passed, with `-race`, on code that has a race in it.** With one worker there is one goroutine
touching `s`, and a race needs two. The test is not wrong about what it checks; it just never runs
the code concurrently, and the detector can only report what ran.

The second test is subtler, because whether it sees the race depends on the machine. `taskset -c 0`
runs a command on the first CPU only, the position a program is in on a virtual machine with one
CPU, or on a CI runner that has been given one:

```
ana@vm:~/race-hits$ nproc; taskset -c 0 nproc
4
1
ana@vm:~/race-hits$ taskset -c 0 go test -race -count=1 -run Default ./internal/tally
ok  	example.com/hits/internal/tally	1.011s
```

On one CPU `runtime.GOMAXPROCS(0)` is 1, so "one worker per CPU" is one worker and the race never
happens. On all four, the same test, the same code and the same flag fail:

```
ana@vm:~/race-hits$ go test -race -count=1 -run Default ./internal/tally 2>&1 | tail -4
    testing.go:1865: race detected during execution of test
FAIL
FAIL	example.com/hits/internal/tally	0.020s
FAIL
```

**Whether CI catches this depends on the size of the machine it happens to get**, which is not a property anybody chose.

The documentation of `runtime.GOMAXPROCS`, which `go doc runtime.GOMAXPROCS` prints, says how that
number is picked: the logical CPUs, the CPU affinity mask that `taskset` sets, and on Linux the
container's CPU quota. It also says that a quota never brings the default below 2 unless the machine
or the mask has fewer than two CPUs, so a container limited to one CPU on a large machine still
gets two workers. A one-CPU virtual machine, or an affinity mask like the one above, gets one.

One CPU is no obstacle for the other test:

```
ana@vm:~/race-hits$ taskset -c 0 go test -race -count=1 -v ./internal/tally 2>&1 | grep -E "^(---|ok|FAIL)"
--- FAIL: TestCountParallel (0.00s)
--- PASS: TestCountParallelOneWorker (0.00s)
--- PASS: TestCountParallelDefault (0.00s)
FAIL
FAIL	example.com/hits/internal/tally	0.011s
FAIL
```

`TestCountParallel` asks for two workers, and two goroutines on one CPU still take turns at
`s.Lines` with no lock between them, so the detector reports it. **The detector needs two goroutines,
not two CPUs.** It follows the order of events, not the clock: two accesses that nothing ordered
are a race whether they ran a nanosecond apart or a whole time slice apart.

## `-cpu` and `-count`

`go test -cpu` takes a list of values for `GOMAXPROCS` and runs every test once per value. That
puts the second test right on the same single CPU:

```
ana@vm:~/race-hits$ taskset -c 0 go test -race -count=1 -cpu 1,4 -run Default -v ./internal/tally 2>&1 | grep -E "^(=== RUN|---|ok|FAIL)"
=== RUN   TestCountParallelDefault
--- PASS: TestCountParallelDefault (0.00s)
=== RUN   TestCountParallelDefault
--- FAIL: TestCountParallelDefault (0.00s)
FAIL
FAIL	example.com/hits/internal/tally	0.011s
FAIL
```

Two runs of `TestCountParallelDefault`: with `-cpu 1` it passed, and with `-cpu 4` it failed, on a
command still pinned to one CPU by `taskset`. **`-cpu` sets the number the code sees, not the number
of CPUs the machine has**, so any code that sizes itself from `GOMAXPROCS` can be made to take its
concurrent path anywhere. Use `-v` with it, as above, because without `-v` a test that passes at one
value and fails at another prints a single `--- FAIL` line and no hint of which value failed.

`go test -count=N` is the other repeat, and `go help testflag` describes it as running "each test,
benchmark, and fuzz seed n times"; combined with `-cpu`, it runs them n times for each value. It
earns its place when the racy path depends on timing, a branch that only runs if one goroutine
gets somewhere before another, so that some runs take it and some do not. This race does not need
it: whenever two workers exist, every run reports it. **`-count=1` has a second job in CI**, which
section 05 shows: it is the documented way to stop `go test` answering from its cache.

## The fix, and the run that proves it

Both counters are part of `s`, and every worker writes them, so they go under the same lock as the
maps. Section 04 measures this fixed version, with the detector on and off. Edited, saved again
as `internal/tally/parallel.go`:

```go
package tally

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"runtime"
	"sync"
)

// CountParallel does what Count does, with several workers parsing the
// lines at once. With workers below 1 it starts one per CPU, as GOMAXPROCS
// counts them. It reports every line it cannot parse, not only the first.
func CountParallel(r io.Reader, workers int) (Summary, error) {
	if workers < 1 {
		workers = runtime.GOMAXPROCS(0)
	}
	var lines []string
	sc := bufio.NewScanner(r)
	for sc.Scan() {
		lines = append(lines, sc.Text())
	}
	if err := sc.Err(); err != nil {
		return Summary{}, err
	}

	s := Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}
	errs := make([]error, workers)
	var mu sync.Mutex
	var wg sync.WaitGroup
	for w := range workers {
		wg.Go(func() {
			for i := w; i < len(lines); i += workers {
				e, err := Parse(lines[i])
				if err != nil {
					errs[w] = errors.Join(errs[w], fmt.Errorf("line %d: %w", i+1, err))
					continue
				}
				mu.Lock() // everything in s is shared: all of it under the lock
				s.Lines++
				s.Total += e.Duration
				s.ByStatus[e.Status]++
				s.ByPath[e.Path]++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	return s, errors.Join(errs...)
}
```

The one change is the position of `mu.Lock()`, now above `s.Lines++`, and its comment, which now says
why the lock covers everything. Then the run that proves it, at three values of `GOMAXPROCS`, three
times each, with the detector on and every package of the module included:

```
ana@vm:~/race-hits$ go test -race -count=3 -cpu 1,2,4 ./...
ok  	example.com/hits	1.019s
ok  	example.com/hits/internal/tally	1.022s
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
ana@vm:~/race-hits$ go build -o pcount ./tools/pcount && for i in 1 2 3 4 5 6; do ./pcount < access.log; done
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
20000 lines, 1h6m37.778s in total
```

**Nine runs of every test with the detector watching, and nothing to report**; `pcount` now prints
20,000 lines and the same total, `1h6m37.778s`, six times out of six. The two quiet tests stay in the
file. With the fix in neither has a race left to find, but `TestCountParallelDefault` at `-cpu 1,2,4`
exercises the default path at every size, and that is the test that would have caught the bug on a
one-CPU runner.
