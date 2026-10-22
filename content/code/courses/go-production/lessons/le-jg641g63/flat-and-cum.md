---
title: Flat and cum
version: 1
---

Lesson 12 ended with three profiles that agreed on one name, `strings.Fields`, and with a
promise that reading them properly was the job of this lesson. **Every row of `go tool pprof -top` carries two
measurements of the same function, and most misreadings of a profile come from looking at one and
thinking it is the other.** This section takes them apart on a profile with enough samples to trust.

## A profile worth reading

A one-second benchmark gave lesson 12 about 120 samples. `-benchtime 200x` runs exactly 200
iterations instead, a few seconds of work, and `-run '^$'` matches no test name, so the tests in the
package do not run first and end up in the profile beside the benchmark. Ana is in `~/prof` as
lesson 12 left it:

```
ana@vm:~/prof$ go test -run '^$' -bench Count -benchtime 200x -cpuprofile cpu.out -memprofile mem.out ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	     200	  31520093 ns/op	 145.05 MB/s
PASS
ok  	example.com/hits/internal/tally	6.369s
```

Each iteration took about 31.5 milliseconds, so the 200 of them are 20 million calls of `Parse` on
the 100,000 lines of `testdata/access.log`. The report, sorted the default way:

```
ana@vm:~/prof$ go tool pprof -top cpu.out | sed /^Time:/d | head -16
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Showing nodes accounting for 5.51s, 91.83% of 6s total
Dropped 81 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
     1.20s 20.00% 20.00%      2.53s 42.17%  strings.Fields
     0.53s  8.83% 28.83%      0.53s  8.83%  runtime.asyncPreempt
     0.31s  5.17% 34.00%      0.70s 11.67%  runtime.mallocgcSmallScanNoHeaderSC7
     0.28s  4.67% 38.67%      0.29s  4.83%  runtime.unlock2
     0.22s  3.67% 42.33%      4.95s 82.50%  example.com/hits/internal/tally.Count
     0.22s  3.67% 46.00%      0.23s  3.83%  runtime.lock2
     0.19s  3.17% 49.17%      0.22s  3.67%  time.parseRFC3339[go.shape.string].func1 (inline)
     0.15s  2.50% 51.67%      0.15s  2.50%  internal/runtime/maps.memHashAES
     0.14s  2.33% 54.00%      0.14s  2.33%  runtime.memmove
```

600 samples this time, each worth 10 ms. Five columns of numbers, in two groups:

| column | what it says |
|---|---|
| `flat` | samples in which this function was the one running: the top frame of the stack |
| `flat%` | the same, as a share of all samples |
| `sum%` | the running total of `flat%` down the list |
| `cum` | samples in which this function was **anywhere** on the stack: itself and everything it called |
| `cum%` | the same, as a share |

**Flat is the time spent in a function's own code. Cum is the time spent from the moment it was
called until it returned**, whoever did the work. `strings.Fields` has 1.20 seconds flat and 2.53
cum: of the 2.53 seconds during which a `Fields` call was in progress, 1.20 were its own loops over
the bytes and the other 1.33 were in functions it called, which the next section names. `-top` sorts
by flat, so the first rows are the functions whose own code is busiest.

## The same profile by cum

`-cum` sorts by the other column. In the interactive prompt, `go tool pprof cpu.out`, the same two
reports are the commands `top` and `top -cum`:

```
ana@vm:~/prof$ go tool pprof -top -cum cpu.out | sed /^Time:/d | head -16
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Showing nodes accounting for 5.51s, 91.83% of 6s total
Dropped 81 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
     0.22s  3.67%  3.67%      4.95s 82.50%  example.com/hits/internal/tally.Count
         0     0%  3.67%      4.95s 82.50%  example.com/hits/internal/tally_test.BenchmarkCount
         0     0%  3.67%      4.95s 82.50%  testing.(*B).run1.func1
         0     0%  3.67%      4.95s 82.50%  testing.(*B).runN
     0.02s  0.33%  4.00%      3.82s 63.67%  example.com/hits/internal/tally.Parse
     1.20s 20.00% 24.00%      2.53s 42.17%  strings.Fields
     0.02s  0.33% 24.33%      1.05s 17.50%  runtime.mallocgc
     0.03s   0.5% 24.83%      0.75s 12.50%  runtime.makeslice
     0.31s  5.17% 30.00%      0.70s 11.67%  runtime.mallocgcSmallScanNoHeaderSC7
```

**`tally.Count` is first, with 82.50% cum and 0.22 seconds flat.** Both numbers are right. `Count`
is on the stack of nearly every sample, because everything the benchmark does happens inside it.
Almost none of its own instructions are running at any moment: it loops, calls `Scan`, calls
`Parse`, updates two maps, and each of those is a function of its own with its own samples. The
three rows with the same 82.50% and a flat of zero, `BenchmarkCount`, `runN` and `run1.func1`, are
the frames below it, the benchmark harness, which spends no time of its own at all.

**A high cum with a tiny flat is a function that delegates.** Optimising its own code buys at most
its flat, 3.67% here; what it buys by changing what it calls, or how often, is up to its cum. A high
flat is the opposite: the work is in the function's own loop, and that loop is what to look at. The
remaining 17.5% of the samples are not under `Count` at all. They are the runtime's own goroutines, the garbage collector sweeping memory and a goroutine being rescheduled, which do their work on other threads and show up in the profile like any other code.

Two runtime rows deserve a sentence, because they appear in almost every Go profile.
`runtime.mallocgc` and its relatives are **allocation**: 17.50% cum here, the price of two
allocations a line. `runtime.asyncPreempt`, 8.83% flat, is where a sample lands when the runtime has
just interrupted a running goroutine to let the scheduler or the collector act; it is real time, and
it grows when the machine is busy with other work.

## The most frequent and the most expensive

The question this lesson's title asks is easy to get backwards. **A CPU profile does not count
calls.** `Parse` is called 20 million times and `Count` 200 times, and nothing in the report says
so: both are only stacks that were caught at a tick. A function called very often and very cheaply,
and a function called once and slowly, look the same in the profile if they add up to the same time.

So the cost of one call is something you work out, from the profile's total and a count you know
from the program. `strings.Fields` was on the stack for 2.53 seconds across about 20 million calls:
**about 126 nanoseconds a call**, out of the 315 or so that a whole line costs at 31.5 ms for
100,000 lines. That number is what tells you whether a function is slow or merely busy, and it is
the number to compare against an alternative.

The memory profile makes the distinction visible, because it records both counts and sizes. The two
views that `go tool pprof` calls `alloc_objects` and `alloc_space`:

```
ana@vm:~/prof$ go tool pprof -top -sample_index=alloc_objects mem.out | sed /^Time:/d | head -8
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: alloc_objects
Showing nodes accounting for 39884661, 100% of 39895461 total
Dropped 37 nodes (cum <= 199477)
      flat  flat%   sum%        cum   cum%
  20343925 50.99% 50.99%   20343925 50.99%  strings.Fields
  19538916 48.98%   100%   19538916 48.98%  bufio.(*Scanner).Text (inline)
ana@vm:~/prof$ go tool pprof -top -sample_index=alloc_space mem.out | sed /^Time:/d | head -8
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: alloc_space
Showing nodes accounting for 2550.17MB, 99.62% of 2559.89MB total
Dropped 37 nodes (cum <= 12.80MB)
      flat  flat%   sum%        cum   cum%
 1552.12MB 60.63% 60.63%  1552.12MB 60.63%  strings.Fields
  997.55MB 38.97% 99.60%   997.55MB 38.97%  bufio.(*Scanner).Text (inline)
```

**By count, the two allocators are level: one allocation each per line**, about 20 million each over
the run, and the 4% between them is the sampler, not the code. By size, `strings.Fields` made
1,552.12 MB against 997.55 MB for `Scanner.Text`. Each call of `Fields` allocates a slice of five
strings, 5 × 16 = 80 bytes, while `Text` copies the line, about 45 bytes, which the allocator rounds
up to one of its size classes, 48 or 64 bytes. The most frequent allocation and the most expensive
one are different questions, and **`-sample_index` is how you ask the second**: `alloc_objects`
finds the code that allocates often, `alloc_space` the code that allocates a lot.