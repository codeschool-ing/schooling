---
title: Measuring allocations
version: 1
---
Section 04 tuned the collector, and found that the biggest lever was not a setting at all. **The
collector's work is proportional to what the program allocates and keeps, so the measurement that
leads somewhere is of allocations**, and Go has one tool for each scale: the whole process, one
function, and the line of code responsible. They are not interchangeable, and the oldest of them has
a cost the others do not.

## The whole process: MemStats or runtime/metrics

`runtime.ReadMemStats`, which lesson 24 of the `go` course used, fills a struct with the runtime's
accounting. `runtime/metrics`, which `~/mem-stacks` and `slowest` used, reads the same kind of
numbers by name. The difference that matters in production is in the first function's body:

```
ana@vm:~/mem-stats$ sed -n 356,365p /usr/local/go/src/runtime/mstats.go
func ReadMemStats(m *MemStats) {
	_ = m.Alloc // nil check test before we switch stacks, see issue 61158
	stw := stopTheWorld(stwReadMemStats)

	systemstack(func() {
		readmemstats_m(m)
	})

	startTheWorld(stw)
}
```

**`ReadMemStats` stops the world** to take a consistent snapshot: every goroutine, for as long as
the copy takes. `metrics.Read` takes only a lock of its own, and the program goes on running while
it reads. A benchmark of each, in `~/mem-stats`, a module of its own with a single test file. Save
it as `stats_test.go`:

```go
package memstats

import (
	"runtime"
	"runtime/metrics"
	"testing"
)

func BenchmarkReadMemStats(b *testing.B) {
	var m runtime.MemStats
	for b.Loop() {
		runtime.ReadMemStats(&m)
	}
}

func BenchmarkMetricsRead(b *testing.B) {
	s := []metrics.Sample{
		{Name: "/gc/heap/allocs:bytes"},
		{Name: "/gc/heap/allocs:objects"},
		{Name: "/gc/cycles/total:gc-cycles"},
	}
	for b.Loop() {
		metrics.Read(s)
	}
}
```

```
ana@vm:~/mem-stats$ go test -bench . -benchmem
goos: linux
goarch: amd64
pkg: example.com/memstats
cpu: Intel(R) Xeon(R) Processor
BenchmarkReadMemStats-4   	  171919	     11398 ns/op	       0 B/op	       0 allocs/op
BenchmarkMetricsRead-4    	 3624614	       338.8 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	example.com/memstats	3.198s
```

**11,398 nanoseconds against 338.8, more than thirty times as long**, and the slow one stopped every
goroutine of the program for part of it. A program that reads its memory once a minute for a
dashboard can afford either. One that reads it on every request should use `runtime/metrics`, which
also names its units in every key and documents each metric in `go doc runtime/metrics`. The two
columns on the right are the next tool.

## One function: benchmarks that count

`-benchmem` adds `B/op` and `allocs/op` to every benchmark in the run. `b.ReportAllocs()` adds them
to one benchmark always, whether or not the flag is given, which suits a benchmark whose whole point
is allocation. `keep.Load` takes a hint for how many lines to expect, and section 04 always passed
0. A benchmark of both, beside `keep.go`, reads the same 100,000-line log as lesson 12's benchmark.
Save it as `internal/keep/keep_test.go`:

```go
package keep_test

import (
	"bytes"
	"os"
	"strconv"
	"testing"

	"example.com/hits/internal/keep"
	"example.com/hits/internal/tally"
)

func BenchmarkLoad(b *testing.B) {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		b.Fatal(err)
	}
	lines := bytes.Count(data, []byte("\n"))
	for _, hint := range []int{0, lines} {
		b.Run("hint="+strconv.Itoa(hint), func(b *testing.B) {
			b.ReportAllocs()
			for b.Loop() {
				if _, err := keep.Load(bytes.NewReader(data), hint); err != nil {
					b.Fatal(err)
				}
			}
		})
	}
}

func TestBySlowestDoesNotAllocate(t *testing.T) {
	entries := []tally.Entry{{Duration: 3}, {Duration: 1}, {Duration: 2}}
	allocs := testing.AllocsPerRun(100, func() { keep.BySlowest(entries) })
	if allocs != 0 {
		t.Errorf("BySlowest allocates %v times a call, want 0", allocs)
	}
}
```

`b.Run` makes two sub-benchmarks, one with no hint and one with the exact number of lines, counted
once with `bytes.Count` before either starts. The test at the bottom is the third tool, and it waits
for its paragraph. Run without `-benchmem`:

```
ana@vm:~/mem-hits$ ./genlog -n 100000 > internal/keep/testdata/access.log
ana@vm:~/mem-hits$ go test -run "^$" -bench Load ./internal/keep
goos: linux
goarch: amd64
pkg: example.com/hits/internal/keep
cpu: Intel(R) Xeon(R) Processor
BenchmarkLoad/hint=0-4         	      22	  53056937 ns/op	53802259 B/op	  200033 allocs/op
BenchmarkLoad/hint=100000-4    	      46	  24474033 ns/op	20523557 B/op	  200003 allocs/op
PASS
ok  	example.com/hits/internal/keep	2.310s
```

The memory columns are there because of `ReportAllocs`. And they tell two different stories:

| | `hint=0` | `hint=100000` |
|---|---|---|
| ns/op | 53,056,937 | 24,474,033 |
| B/op | 53,802,259 | 20,523,557 |
| allocs/op | 200,033 | 200,003 |

**Thirty fewer allocations, 33 MB fewer bytes, and less than half the time.** Counting allocations
alone would call the hint worthless: 200,000 of the allocations are the two a line from lesson 12,
the string from `Text` and the slice from `strings.Fields`, and the hint touches neither. The thirty
it removed were enormous ones. Without a hint, `append` grows the slice by allocating a bigger array
and copying the old one into it, and the runtime's rule for how much bigger makes that a long series
for a large slice:

```
ana@vm:~/mem-hits$ sed -n 337,341p /usr/local/go/src/runtime/slice.go
	for {
		// Transition from growing 2x for small slices
		// to growing 1.25x for large slices. This formula
		// gives a smooth-ish transition between the two.
		newcap += (newcap + 3*threshold) >> 2
```

Past 256 elements, each new array is about a quarter larger than the last, so a slice of 100,000
entries is built through some thirty arrays, each one copied into the next. **`B/op` sees those
copies; `allocs/op` counts each of them as one.** Read both columns, every time.

## One line of code: the heap profile

When a benchmark says how much and not where, the heap profile says where. Lesson 12 showed how to
take one and what its four views are; one command is enough to confirm the reading above:

```
ana@vm:~/mem-hits$ go test -run "^$" -bench "Load/hint=0" -memprofile mem.out ./internal/keep > /dev/null && go tool pprof -top -sample_index=alloc_space mem.out | sed /^Time:/d | head -9
File: keep.test
Build ID: 78759425bf4cfa842ab0d3475d27dd21a0fb9aab
Type: alloc_space
Showing nodes accounting for 1249.59MB, 99.53% of 1255.46MB total
Dropped 19 nodes (cum <= 6.28MB)
      flat  flat%   sum%        cum   cum%
  935.07MB 74.48% 74.48%  1249.59MB 99.53%  example.com/hits/internal/keep.Load
  205.02MB 16.33% 90.81%   205.02MB 16.33%  strings.Fields
  109.51MB  8.72% 99.53%   109.51MB  8.72%  bufio.(*Scanner).Text (inline)
```

**`keep.Load` itself is 74.48% of every byte allocated**, flat: those are the arrays `append` grew,
charged to the function that called it. `strings.Fields` and `Scanner.Text` share the rest, the two
a line that lesson 12 found.

## A budget the tests enforce

Some code should not allocate at all, and the way to keep it that way is a test.
`testing.AllocsPerRun` calls a function many times and returns the average number of allocations per
call; the `go` course's lesson 24 called it from `main`, and in a test it becomes a rule. The last
function of `keep_test.go` holds `BySlowest` to zero, because sorting in place has no reason to
allocate:

```
ana@vm:~/mem-hits$ go test -count=1 -run Allocate -v ./internal/keep
=== RUN   TestBySlowestDoesNotAllocate
--- PASS: TestBySlowestDoesNotAllocate (0.00s)
PASS
ok  	example.com/hits/internal/keep	0.002s
```

It passes today. **The day somebody changes `BySlowest` so that it allocates**, by copying the slice
before sorting it, say, or by passing it through an interface the compiler cannot see past, the test
fails and names the number, long before anybody profiles the program that calls it. A budget of 0 is
the strictest; a function that must allocate once can be held to 1 the same way.
