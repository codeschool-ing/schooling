---
title: Measuring the fix
version: 1
---

A change made because of a profile is finished when **a measurement says it worked, by how much, and
what the profile looks like now**. Three tools do that: benchstat compares two sets of benchmark
runs and says whether the difference is real, `-diff_base` subtracts one profile from another, and
the new profile shows what is left to find.

## Ten runs against ten runs

The same benchmark command as before, into a second file, and benchstat to compare them. It is not
in the standard distribution. It lives in `golang.org/x/perf`, a module with no release tags, so the
version to pin is a pseudo-version, a date and a commit:

```
ana@vm:~/prof$ go test -run '^$' -bench Count -benchmem -count 10 ./internal/tally > new.txt
ana@vm:~/prof$ go install golang.org/x/perf/cmd/benchstat@v0.0.0-20261009192801-be2c69fb417e
ana@vm:~/prof$ benchstat old.txt new.txt
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
        │   old.txt   │               new.txt               │
        │   sec/op    │   sec/op     vs base                │
Count-4   33.52m ± 7%   18.33m ± 7%  -45.31% (p=0.000 n=10)

        │   old.txt    │               new.txt                │
        │     B/s      │     B/s       vs base                │
Count-4   130.1Mi ± 7%   237.9Mi ± 7%  +82.87% (p=0.000 n=10)

        │    old.txt    │               new.txt                │
        │     B/op      │     B/op      vs base                │
Count-4   12.706Mi ± 0%   5.077Mi ± 0%  -60.04% (p=0.000 n=10)

        │   old.txt   │               new.txt               │
        │  allocs/op  │  allocs/op   vs base                │
Count-4   200.0k ± 0%   100.0k ± 0%  -50.00% (p=0.000 n=10)
```

Each table is one measurement, old on the left, new in the middle, and the change on the right.
**33.52 ms to 18.33 ms a count, −45.31%**: the median of ten runs each, and the `± 7%` beside each
is the 95% confidence interval around that median, wider when the runs disagree. `p=0.000` is the
probability of seeing a difference this large if the change had done nothing; benchstat prints `~`
instead of a percentage when that probability is too high to call it a change. Memory moved exactly
as designed, with no spread at all, because allocation does not depend on how busy the machine is:
**5.077 MiB a count instead of 12.706, and 100,000 allocations instead of 200,000**, one per line,
the slice gone.

**The spread is the reason for ten runs.** On the shared machine these were recorded on, one run of
the old code and one of the new could have landed anywhere in their 7%. On a busier machine the spread
widens, and a single before-and-after pair
would measure only the moment.

## The profile, before and after

`-diff_base` subtracts a base profile from the one being read, so each row shows what changed. Both
profiles come from `-benchtime 200x`, the same 200 iterations of the same work, which is what makes
subtracting them meaningful: two runs of different length would differ everywhere.

```
ana@vm:~/prof$ go test -run '^$' -bench Count -benchtime 200x -cpuprofile cpu.new -memprofile mem.new ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	     200	  17741499 ns/op	 257.70 MB/s
PASS
ok  	example.com/hits/internal/tally	3.573s
ana@vm:~/prof$ go tool pprof -top -diff_base cpu.out cpu.new | sed /^Time:/d | head -14
File: tally.test
Build ID: 8ae0c6b77bf75fbc30f6f2f69bb16d7310e9a8e2
Type: cpu
Duration: 9.90s, Total samples = 6s (60.63%)
Showing nodes accounting for -2.31s, 38.50% of 6s total
Dropped 70 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
    -1.20s 20.00% 20.00%     -2.53s 42.17%  strings.Fields
     0.68s 11.33%  8.67%      0.72s 12.00%  example.com/hits/internal/tally.split5
    -0.31s  5.17% 13.83%     -0.70s 11.67%  runtime.mallocgcSmallScanNoHeaderSC7
    -0.28s  4.67% 18.50%     -0.28s  4.67%  runtime.asyncPreempt
     0.20s  3.33% 15.17%     -1.63s 27.17%  example.com/hits/internal/tally.Parse
    -0.19s  3.17% 18.33%     -0.19s  3.17%  runtime.lock2
    -0.16s  2.67% 21.00%     -0.17s  2.83%  runtime.unlock2
```

Negative numbers are time that went away. **`strings.Fields` lost all of its 2.53 seconds and
`split5` added 0.72**, so the same lines were split for less than a third of the time. `tally.Parse` as a whole is 1.63 seconds lighter, and the allocator and the runtime's locks are lighter with it.
The new profile holds 3.55 seconds of samples against the old one's 6 for the same 200 iterations,
which agrees with benchstat in direction and roughly in size, as two independent measurements of one
change should.

## What is left

The new profile on its own, sorted by flat:

```
ana@vm:~/prof$ go tool pprof -top cpu.new | sed /^Time:/d | head -16
File: tally.test
Build ID: 8ae0c6b77bf75fbc30f6f2f69bb16d7310e9a8e2
Type: cpu
Duration: 3.56s, Total samples = 3.55s (99.61%)
Showing nodes accounting for 3.37s, 94.93% of 3.55s total
Dropped 43 nodes (cum <= 0.02s)
      flat  flat%   sum%        cum   cum%
     0.68s 19.15% 19.15%      0.72s 20.28%  example.com/hits/internal/tally.split5
     0.25s  7.04% 26.20%      0.25s  7.04%  runtime.asyncPreempt
     0.22s  6.20% 32.39%      2.19s 61.69%  example.com/hits/internal/tally.Parse
     0.18s  5.07% 37.46%      3.26s 91.83%  example.com/hits/internal/tally.Count
     0.18s  5.07% 42.54%      0.37s 10.42%  time.Date
     0.17s  4.79% 47.32%      0.50s 14.08%  time.ParseDuration
     0.15s  4.23% 51.55%      0.17s  4.79%  time.parseRFC3339[go.shape.string].func1 (inline)
     0.13s  3.66% 55.21%      0.13s  3.66%  internal/runtime/maps.memHashAES
     0.12s  3.38% 58.59%      0.12s  3.38%  runtime.unlock2
```

**The top row is now `split5`, 19.15% flat**, the loop that looks at every byte once. That is not a
sign of a new problem: some function is always first, and a loop that touches every byte of its
input has to cost something. Per call it is 0.72 seconds over about 20 million lines, some 36
nanoseconds, against the 126 that `strings.Fields` cost. Below it the samples are spread out: the
timestamp, `time.Date` and `time.ParseDuration`, the map lookups behind the counts, the runtime.
**No single row dominates any more**, and that is what a flat profile means.

The memory says the same thing:

```
ana@vm:~/prof$ go tool pprof -top -sample_index=alloc_space mem.new | sed /^Time:/d | head -8
File: tally.test
Build ID: 8ae0c6b77bf75fbc30f6f2f69bb16d7310e9a8e2
Type: alloc_space
Showing nodes accounting for 1.01GB, 99.21% of 1.02GB total
Dropped 31 nodes (cum <= 0.01GB)
      flat  flat%   sum%        cum   cum%
    1.01GB 99.21% 99.21%     1.01GB 99.21%  bufio.(*Scanner).Text (inline)
         0     0% 99.21%     1.01GB 99.26%  example.com/hits/internal/tally.Count
```

1.02 GB allocated over the 200 iterations, against 2,559.89 MB before, and **nearly all of it is
`Scanner.Text`**, the one string per line that `Count` asks for. Removing that one too is possible,
by working on the scanner's bytes and converting only the path into a string, and it costs a `Parse`
that takes a `[]byte` and a second set of tests. The `unsafe` package can skip the copy too, and
lesson 22 is about what that kind of shortcut costs.

## When to stop

Two rules come out of this lesson, and the second is the one people break.

**Profile before optimising.** Every instinct about this code pointed at `time.Parse`; the profile
pointed at `strings.Fields`, and a hand-written timestamp parser would have been a day's work for
the quarter of the cost the profile had already ruled out.

**Stop when the profile is flat.** Before the change, one function held 42% of the samples, and
removing most of its cost was a 45% faster count for a few dozen lines of code and a test. Now the
biggest row is 19%, and even making `split5` free, which is impossible, would buy at most that; the
next row is 7%. Each further change buys less than the last and adds code somebody has to read.
**What is enough is a decision about the program, not about the profile**: `hits` counts 91 MB in
well under a second, which is fast enough for a log a server writes in a day, and the profile now
says where to look if it ever is not.