---
title: A profile from a benchmark
version: 1
---

The cheapest profile to get is one of a benchmark, because **`go test` already knows how to take
it**: two flags, and the test binary writes a CPU profile and a memory profile when it finishes. A
benchmark is also the right place to start for a second reason. It runs the code you care about in a
loop, on input you chose, with nothing else going on, so the profile is about that code and not
about whatever else a whole program does while it starts up and shuts down.

The work to measure is the `tally` package from lesson 1, counting lines. Ana works on a copy of
lesson 1's `hits` in `~/prof`, so the profiles and a large log in sections 04 and 05 stay out of
her real project. The copy has the three files lesson 1 printed (`main.go`, `tools/genlog/main.go`
and `internal/tally/tally.go`) and its own `go.mod`.

## A benchmark for `Count`

`go-concurrency` lesson 29 taught benchmarks; this one is the shape it taught, in a file of its own
beside `tally.go`. Save it as `internal/tally/bench_test.go`:

```go
package tally_test

import (
	"bytes"
	"os"
	"testing"

	"example.com/hits/internal/tally"
)

func BenchmarkCount(b *testing.B) {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		b.Fatal(err)
	}
	b.SetBytes(int64(len(data)))
	for b.Loop() {
		if _, err := tally.Count(bytes.NewReader(data)); err != nil {
			b.Fatal(err)
		}
	}
}
```

**The log is read once, before the loop**, so what is timed is counting and not reading a disk.
`b.Loop` runs the body as many times as it takes to get a stable time and excludes everything before
the loop from it. `b.SetBytes` tells the framework how much input one iteration consumes, which adds
a throughput column to the result. `go test` runs a package's tests with the package's directory as
the working directory, so `testdata/access.log` means `internal/tally/testdata/access.log`, and the
go command ignores a directory called `testdata` when it looks for packages. The input is
`genlog`'s, a hundred thousand lines:

```
ana@vm:~/prof$ mkdir -p internal/tally/testdata
ana@vm:~/prof$ go run ./tools/genlog -n 100000 > internal/tally/testdata/access.log
ana@vm:~/prof$ stat -c "%s bytes  %n" internal/tally/testdata/access.log
4571935 bytes  internal/tally/testdata/access.log
```

## Two flags

`-cpuprofile` and `-memprofile` each take a file name. **With either one, the go command also keeps
the test binary**, which `go help testflag` describes as writing it "as -c would":

```
ana@vm:~/prof$ go test -bench Count -benchmem -cpuprofile cpu.out -memprofile mem.out ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	      43	  25577435 ns/op	 178.75 MB/s	13323728 B/op	  200009 allocs/op
PASS
ok  	example.com/hits/internal/tally	1.115s
ana@vm:~/prof$ ls
cpu.out
go.mod
internal
main.go
mem.out
tally.test
tools
```

The benchmark line is the one `go-concurrency` lesson 29 explained: 43 iterations, 25,577,435
nanoseconds each, which is about 25.6 milliseconds to count 4.57 MB, 178.75 MB a second. With
`-benchmem` it adds the memory columns, and they are the first finding before any profile is opened:
**200,009 allocations per iteration, for 100,000 lines, is two allocations a line**. `cpu.out`,
`mem.out` and `tally.test` are in the directory where `go test` ran.

## The first look

`go tool pprof` reads a profile. With an output format such as `-top` it prints that report and
exits; without one it opens an interactive prompt, which lesson 13 uses. The `sed` drops the line
holding the date of the run:

```
ana@vm:~/prof$ go tool pprof -top cpu.out | sed /^Time:/d | head -14
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 1.10s, Total samples = 1.20s (108.63%)
Showing nodes accounting for 1.20s, 100% of 1.20s total
      flat  flat%   sum%        cum   cum%
     0.25s 20.83% 20.83%      0.39s 32.50%  strings.Fields
     0.05s  4.17% 25.00%      0.05s  4.17%  runtime.memmove
     0.05s  4.17% 29.17%      0.05s  4.17%  time.parseRFC3339[go.shape.string].func1 (inline)
     0.04s  3.33% 32.50%      0.04s  3.33%  internal/strconv.Atoi
     0.04s  3.33% 35.83%      0.06s  5.00%  runtime.mallocgcSmallNoScanSC6
     0.04s  3.33% 39.17%      0.09s  7.50%  runtime.mapassign_fast64
     0.04s  3.33% 42.50%      0.09s  7.50%  time.ParseDuration
     0.03s  2.50% 45.00%         1s 83.33%  example.com/hits/internal/tally.Count
```

The header says what was profiled. The run lasted 1.10 seconds and holds 1.20 seconds of samples,
which is 120 ticks of the 10 ms clock, more than the duration because the garbage collector worked
on other cores while the benchmark ran. Below it comes one row per function. **`strings.Fields` is
first with a fifth of all samples**, and `tally.Count`, near the bottom of the excerpt, has hardly
any samples of its own and appears in 83% of the stacks. What the two columns of numbers mean, and
why they rank functions so differently, is lesson 13's subject; this lesson is about getting the
file.

Section 02 said the CPU profiler ticks a hundred times a second, and the file says so. `-raw` prints
the profile as it is stored, and its first lines name what a sample measures:

```
ana@vm:~/prof$ go tool pprof -raw cpu.out | sed /^Time:/d | head -5
PeriodType: cpu nanoseconds
Period: 10000000
Duration: 1.10
Samples:
samples/count cpu/nanoseconds
```

A period of 10,000,000 nanoseconds is 10 ms. Every sample carries two values, a count and the
nanoseconds it stands for.

## The memory profile

The same commands on `mem.out`:

```
ana@vm:~/prof$ go tool pprof -top mem.out | sed /^Time:/d | head -9
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: alloc_space
Showing nodes accounting for 554.90MB, 98.95% of 560.77MB total
Dropped 32 nodes (cum <= 2.80MB)
      flat  flat%   sum%        cum   cum%
  332.53MB 59.30% 59.30%   332.53MB 59.30%  strings.Fields
  217.51MB 38.79% 98.09%   217.51MB 38.79%  bufio.(*Scanner).Text (inline)
    4.37MB  0.78% 98.86%     4.37MB  0.78%  os.readFileContents
ana@vm:~/prof$ go tool pprof -raw mem.out | sed /^Time:/d | head -4
PeriodType: space bytes
Period: 524288
Samples:
alloc_objects/count alloc_space/bytes[dflt] inuse_objects/count inuse_space/bytes
```

**`go test -memprofile` writes the `allocs` profile**, so the report opens on `alloc_space`: 560.77
MB allocated over every iteration the benchmark ran, almost all of it by two functions,
`strings.Fields` and `bufio.(*Scanner).Text`. Those are the two allocations a line that
`-benchmem` counted. The `-raw` header shows the four views of section 02 in one file, with
`[dflt]` beside the one shown by default, and a period of 524,288 bytes, the 512 KB of
`runtime.MemProfileRate`.

Two practical notes. **A profile of a one-second run is a hundred-odd samples**, enough to see that
`strings.Fields` dominates and not enough to rank the functions taking 3% each. `-benchtime`
runs the benchmark longer, `5s` for five seconds or `200x` for exactly 200 iterations, and fills the
profile accordingly; lesson 13 uses the second. And a profile carries its own function names, which
is why `go tool pprof cpu.out` needed nothing else. The views that show machine code are the exception, and they want the binary named before the profile, as in
`go tool pprof -disasm Count tally.test cpu.out`. That is what the `tally.test` left behind is for.
