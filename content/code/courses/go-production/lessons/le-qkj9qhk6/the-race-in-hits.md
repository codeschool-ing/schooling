---
title: A race that passes every other check
version: 1
---

`go-concurrency` lesson 16 ran the race detector by hand, on small programs written to have a race.
This lesson is about the run nobody has to remember to type. **A race does not announce itself:
the build succeeds, `go vet` is quiet, the tests pass and the program prints a number that looks
like a count.** The only thing that finds it is a run with `-race`, and the only way to be sure that
run happens is to make the pipeline do it. So the lesson starts with a race in `hits` that gets past
everything else.

## Counting with four workers

Lesson 1's `Count` reads one line at a time on one goroutine. On a machine with four CPUs the obvious
next step is to share the parsing out. The lesson works in `~/race-hits`, a copy of lesson 1's
`hits`: the same `go.mod`, the same 20,000-line `access.log`, and the four files lesson 1 printed,
`tools/genlog/main.go`, `internal/tally/tally.go`, `main.go` and `main_test.go`. Beside `tally.go`,
save `internal/tally/parallel.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/parallel.go",
  "parts": [
    {
      "code": "package tally\n\nimport (\n\t\"bufio\"\n\t\"errors\"\n\t\"fmt\"\n\t\"io\"\n\t\"runtime\"\n\t\"sync\"\n)\n",
      "note": "A second file in the same package, beside lesson 1's `tally.go`. It uses that file's `Parse` and `Summary` and changes neither."
    },
    {
      "code": "// CountParallel does what Count does, with several workers parsing the\n// lines at once. With workers below 1 it starts one per CPU, as GOMAXPROCS\n// counts them. It reports every line it cannot parse, not only the first.\nfunc CountParallel(r io.Reader, workers int) (Summary, error) {\n\tif workers < 1 {\n\t\tworkers = runtime.GOMAXPROCS(0)\n\t}",
      "note": "**Zero or a negative number of workers means one per CPU**, which is what `runtime.GOMAXPROCS(0)` reports. Section 03 shows why that sentence matters to a test."
    },
    {
      "code": "\tvar lines []string\n\tsc := bufio.NewScanner(r)\n\tfor sc.Scan() {\n\t\tlines = append(lines, sc.Text())\n\t}\n\tif err := sc.Err(); err != nil {\n\t\treturn Summary{}, err\n\t}\n",
      "note": "The lines are read first, by one goroutine, so that the workers can share out a slice instead of a scanner, which is not safe to call from two goroutines."
    },
    {
      "code": "\ts := Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}\n\terrs := make([]error, workers)\n\tvar mu sync.Mutex\n\tvar wg sync.WaitGroup",
      "note": "One `Summary` for all the workers, one mutex, and **one error slot per worker**: worker `w` writes only `errs[w]`, so the slots need no lock."
    },
    {
      "code": "\tfor w := range workers {\n\t\twg.Go(func() {\n\t\t\tfor i := w; i < len(lines); i += workers {\n\t\t\t\te, err := Parse(lines[i])\n\t\t\t\tif err != nil {\n\t\t\t\t\terrs[w] = errors.Join(errs[w], fmt.Errorf(\"line %d: %w\", i+1, err))\n\t\t\t\t\tcontinue\n\t\t\t\t}\n\t\t\t\ts.Lines++\n\t\t\t\ts.Total += e.Duration\n\t\t\t\tmu.Lock() // two goroutines must never write a map at once\n\t\t\t\ts.ByStatus[e.Status]++\n\t\t\t\ts.ByPath[e.Path]++\n\t\t\t\tmu.Unlock()\n\t\t\t}\n\t\t})\n\t}",
      "note": "Worker `w` takes lines `w`, `w+workers`, `w+2*workers` and so on, so no line is parsed twice. The two counters are raised first, and then the two maps are updated under the lock."
    },
    {
      "code": "\twg.Wait()\n\treturn s, errors.Join(errs...)\n}",
      "note": "`errors.Join` drops the nil slots and returns nil when every slot is nil."
    }
  ]
}
```

Its author met the map problem first. Two goroutines writing one map at the same moment is
something the Go runtime detects and stops the program for, so the map updates went under a mutex
and the crash went away. **The two lines above the lock were left where they were**, because
`s.Lines++` and `s.Total += e.Duration` never crashed anything.

The test compares `CountParallel` with `Count`, which lesson 1 already trusts, on four lines. A
helper takes the number of workers, because section 03 calls it twice more. The benchmark is for
section 04. `internal/tally/parallel_test.go`:

```go
package tally

import (
	"maps"
	"strings"
	"testing"
)

const sample = "2026-10-01T09:00:01Z GET / 200 5ms\n" +
	"2026-10-01T09:00:02Z GET /login 404 7ms\n" +
	"2026-10-01T09:00:03Z POST /login 200 9ms\n" +
	"2026-10-01T09:00:04Z GET / 304 1ms\n"

// checkParallel compares CountParallel, with this many workers, with Count.
func checkParallel(t *testing.T, workers int) {
	t.Helper()
	want, err := Count(strings.NewReader(sample))
	if err != nil {
		t.Fatal(err)
	}
	got, err := CountParallel(strings.NewReader(sample), workers)
	if err != nil {
		t.Fatal(err)
	}
	if got.Lines != want.Lines || got.Total != want.Total ||
		!maps.Equal(got.ByStatus, want.ByStatus) || !maps.Equal(got.ByPath, want.ByPath) {
		t.Errorf("CountParallel(%d workers) = %+v, want %+v", workers, got, want)
	}
}

func TestCountParallel(t *testing.T) { checkParallel(t, 2) }

func BenchmarkCountParallel(b *testing.B) {
	log := strings.Repeat(sample, 5000) // 20,000 lines
	for b.Loop() {
		if _, err := CountParallel(strings.NewReader(log), 4); err != nil {
			b.Fatal(err)
		}
	}
}
```

And a command small enough to read at a glance, which runs `CountParallel` over standard input with
one worker per CPU. `tools/pcount/main.go`:

```go
// Command pcount counts a log from standard input with tally.CountParallel,
// one worker per CPU, and prints how many lines and how much time it found.
package main

import (
	"fmt"
	"os"

	"example.com/hits/internal/tally"
)

func main() {
	s, err := tally.CountParallel(os.Stdin, 0)
	if err != nil {
		fmt.Fprintln(os.Stderr, "pcount:", err)
		os.Exit(1)
	}
	fmt.Println(s.Lines, "lines,", s.Total, "in total")
}
```

## Everything passes

```
ana@vm:~/race-hits$ go vet ./... && go test -count=1 ./...
ok  	example.com/hits	0.005s
ok  	example.com/hits/internal/tally	0.003s
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
ana@vm:~/race-hits$ go build -o pcount ./tools/pcount && for i in 1 2 3 4 5 6; do ./pcount < access.log; done
20000 lines, 1h6m37.778s in total
19998 lines, 1h6m37.524s in total
19999 lines, 1h6m37.275s in total
19994 lines, 1h6m36.788s in total
19992 lines, 1h6m36.31s in total
19909 lines, 1h6m18.232s in total
```

**`go vet` found nothing and both test packages passed.** Then six runs of `pcount` over the same
20,000-line file printed six different counts. The first run was right. The other five were short
by between 1 and 91 lines, and not one of them looked wrong: 19,994 is a perfectly believable number
of requests, and nothing in the output says that it was ever in doubt. The total time drifted with
the count, down to `1h6m18.232s` from the `1h6m37.778s` of the right run. Had the first run been the
only one, as it would be in a quick check by hand, the bug would have looked fixed.

Two things kept the test green. Four lines split between two workers give each goroutine two lines
of work, which is over before the other one has properly started, so the increments almost never
overlap in time. And a lost increment needs two goroutines to read the same old value of
`s.Lines` in the same few nanoseconds. With 20,000 lines and four workers that happened anywhere from
none to 91 times per run, and with four lines it practically never does. **A test that checks results can only
fail when the timing goes wrong during that run**, and here it had no reason to.

## One flag

The same test, with the detector, and with `GORACE=halt_on_error=1` so that the run stops at the first
report, the setting `go-concurrency` lesson 16 used to keep the output to one report:

```
ana@vm:~/race-hits$ GORACE=halt_on_error=1 go test -race -count=1 ./internal/tally
==================
WARNING: DATA RACE
Read at 0x00c0000301e0 by goroutine 9:
  example.com/hits/internal/tally.CountParallel.func1()
      /home/ana/race-hits/internal/tally/parallel.go:40 +0x3f8

Previous write at 0x00c0000301e0 by goroutine 10:
  example.com/hits/internal/tally.CountParallel.func1()
      /home/ana/race-hits/internal/tally/parallel.go:40 +0x410

Goroutine 9 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
  example.com/hits/internal/tally.checkParallel()
      /home/ana/race-hits/internal/tally/parallel_test.go:21 +0x1f8
  example.com/hits/internal/tally.TestCountParallel()
      /home/ana/race-hits/internal/tally/parallel_test.go:31 +0x2b
  testing.tRunner()
      /usr/local/go/src/testing/testing.go:2193 +0x21c
  testing.(*T).Run.gowrap1()
      /usr/local/go/src/testing/testing.go:2258 +0x38

Goroutine 10 (finished) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
  example.com/hits/internal/tally.checkParallel()
      /home/ana/race-hits/internal/tally/parallel_test.go:21 +0x1f8
  example.com/hits/internal/tally.TestCountParallel()
      /home/ana/race-hits/internal/tally/parallel_test.go:31 +0x2b
  testing.tRunner()
      /usr/local/go/src/testing/testing.go:2193 +0x21c
  testing.(*T).Run.gowrap1()
      /usr/local/go/src/testing/testing.go:2258 +0x38
==================
FAIL	example.com/hits/internal/tally	0.010s
FAIL
```

**The test that passed a moment ago now fails, and it fails every time**: the detector does not wait
for two increments to collide, it notices that two goroutines touched `s.Lines` with nothing
ordering the two accesses. The report reads the way `go-concurrency` lesson 16 taught. Both accesses are at line 40 of
`parallel.go`, `s.Lines++`, a read by goroutine 9 and an earlier write by goroutine 10. The `++` reads
the old value and writes the new one, and the two goroutines did that with no lock between them.

The birthplaces need one more fact than that lesson gave. Under `sync.(*WaitGroup).Go()` the next frame
is `checkParallel()` at line 21 of the test, the call to `CountParallel`.
**The frame for `CountParallel` itself, whose loop called `wg.Go`, is not there.** The detector builds these stacks
from bookkeeping the compiler adds at the entry and exit of every function, and the toolchain leaves
that bookkeeping out of the `sync` package. So the frame below `sync.(*WaitGroup).Go()` is the caller
of the function you are looking for, one level too high, and the function you want is the one that
frame was calling.

Without `halt_on_error` the detector carries on, and the whole run holds two reports, the second
being the same story for `s.Total` on line 41:

```
ana@vm:~/race-hits$ go test -race -count=1 ./internal/tally 2>&1 | grep -c "WARNING: DATA RACE"
2
ana@vm:~/race-hits$ go build -race -o pcount-race ./tools/pcount && ./pcount-race < access.log 2>/dev/null; echo $?
19666 lines, 1h5m34.74s in total
66
```

The last command is `pcount` built with `-race`. It printed 19,666 lines, wrong again, and **exited
with status 66**, the detector's code for "this run had a race", even though standard error, where
the reports went, was thrown away. A script that ignores every word of the output still gets the
answer, which is what section 05 builds a pipeline on.

Section 03 keeps this broken version a little longer, because the next question is the
uncomfortable one: when would `-race` have missed it?
