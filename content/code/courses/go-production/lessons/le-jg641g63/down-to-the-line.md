---
title: Down to the line
version: 1
---

`-top` names functions. The fix will be a change to a line, so the next question is **which line of
`Parse` the 3.82 seconds belong to**, and after that, what `strings.Fields` spends its own 2.53
seconds on. `go tool pprof` answers both, and it can also narrow a report to the part of the program
you care about, which matters once the runtime's rows start to crowd out yours.

## `list`: the source, line by line

`-list` takes a regular expression, finds the functions whose names match, and prints their source
with two columns in front, flat and cum for each line. It reads the source file from the path stored
in the profile, so it works on the machine that built the binary:

```
ana@vm:~/prof$ go tool pprof -list "tally.Parse" cpu.out | head -21
Total: 6s
ROUTINE ======================== example.com/hits/internal/tally.Parse in /home/ana/prof/internal/tally/tally.go
      20ms      3.82s (flat, cum) 63.67% of Total
      10ms       10ms     26:func Parse(line string) (Entry, error) {
         .      2.53s     27:	f := strings.Fields(line)
         .          .     28:	if len(f) != 5 {
         .          .     29:		return Entry{}, fmt.Errorf("want 5 fields, got %d", len(f))
         .          .     30:	}
         .      670ms     31:	t, err := time.Parse(time.RFC3339, f[0])
         .          .     32:	if err != nil {
         .          .     33:		return Entry{}, err
         .          .     34:	}
         .      140ms     35:	status, err := strconv.Atoi(f[3])
         .          .     36:	if err != nil {
         .          .     37:		return Entry{}, fmt.Errorf("status: %w", err)
         .          .     38:	}
         .      460ms     39:	d, err := time.ParseDuration(f[4])
         .          .     40:	if err != nil {
         .          .     41:		return Entry{}, err
         .          .     42:	}
      10ms       10ms     43:	return Entry{Time: t, Method: f[1], Path: f[2], Status: status, Duration: d}, nil
```

**Line 27, `strings.Fields`, carries 2.53 of `Parse`'s 3.82 seconds**: two thirds of the function in
one call. The timestamp, line 31, is 670 ms; the duration, line 39, 460 ms; `strconv.Atoi`, 140 ms.
The dots are lines where no sample landed. `head -21` stops the listing at the end of `Parse`, since
`-list` prints a few lines past the function as context.

That listing also settles an argument before it starts. `time.Parse` with a layout is the call
people reach for first when they suspect a log parser, because parsing dates sounds slow. In Go 1.27
a timestamp in `time.RFC3339` takes a path written for that layout, `time.parseRFC3339` in the
profile, and the line costs about a quarter of what `strings.Fields` costs. **The profile has
already said where not to spend the afternoon.**

## `peek`: callers and callees

`-peek` prints, for each matching function, who called it above the line and what it called below
it, with the time that went each way:

```
ana@vm:~/prof$ go tool pprof -peek "strings.Fields" cpu.out | sed /^Time:/d
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Showing nodes accounting for 6s, 100% of 6s total
----------------------------------------------------------+-------------
      flat  flat%   sum%        cum   cum%   calls calls% + context 	 	 
----------------------------------------------------------+-------------
                                             2.53s   100% |   example.com/hits/internal/tally.Parse
     1.20s 20.00% 20.00%      2.53s 42.17%                | strings.Fields
                                             0.75s 29.64% |   runtime.makeslice
                                             0.33s 13.04% |   runtime.asyncPreempt
                                             0.24s  9.49% |   gcWriteBarrier
                                             0.01s   0.4% |   runtime.gcWriteBarrier2
----------------------------------------------------------+-------------
```

Every call of `strings.Fields` came from `tally.Parse`. Of its 2.53 seconds cum, **0.75 went to
`runtime.makeslice`**, which allocates the slice of fields it returns, and 0.33 to preemption.
Another 0.24 went to `gcWriteBarrier`, the bookkeeping the garbage collector needs when a pointer is
stored into heap memory, which is exactly what filling a freshly allocated slice of strings does.
The rest, its 1.20 seconds flat, is the loop that finds the spaces. The column says `calls`, but
what it holds is time: it is the time spent in each callee, not a count.

## Narrowing the report

A profile of a real program has hundreds of functions. Four options cut it down, and two of them are
easy to confuse:

- **`-focus=REGEXP`** keeps only the samples whose stack contains a matching function, so
  `-focus=tally.Parse` shows the world as seen from inside `Parse`.
- **`-hide=REGEXP`** removes matching frames from every stack but keeps the samples; their time is
  charged to whatever called them.
- **`-ignore=REGEXP`** drops every sample whose stack contains a matching function.
- **`-nodefraction=F`** hides rows whose cum is below that fraction of the total.

`-hide` and `-ignore` on the same pattern give opposite answers:

```
ana@vm:~/prof$ go tool pprof -top -hide=runtime cpu.out | sed /^Time:/d | head -14
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Active filters:
   hide=runtime
Showing nodes accounting for 4.92s, 82.00% of 6s total
Dropped 3 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
     2.53s 42.17% 42.17%      2.53s 42.17%  strings.Fields
     0.58s  9.67% 51.83%      4.95s 82.50%  example.com/hits/internal/tally.Count
     0.41s  6.83% 58.67%      0.41s  6.83%  bufio.(*Scanner).Text (inline)
     0.40s  6.67% 65.33%      0.45s  7.50%  time.ParseDuration
     0.22s  3.67% 69.00%      0.22s  3.67%  time.parseRFC3339[go.shape.string].func1 (inline)
ana@vm:~/prof$ go tool pprof -top -ignore=runtime cpu.out | sed /^Time:/d | head -12
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Active filters:
   ignore=runtime
Showing nodes accounting for 2.25s, 37.50% of 6s total
Dropped 2 nodes (cum <= 0.03s)
      flat  flat%   sum%        cum   cum%
     1.20s 20.00% 20.00%      1.20s 20.00%  strings.Fields
     0.22s  3.67% 23.67%      2.26s 37.67%  example.com/hits/internal/tally.Count
     0.19s  3.17% 26.83%      0.19s  3.17%  time.parseRFC3339[go.shape.string].func1 (inline)
```

With the runtime hidden, **`strings.Fields` has 2.53 seconds flat, the same as its cum**: the
allocation and write barriers it caused are now charged to it. That answers directly the question "how much does this line of my code cost, all in". `Scanner.Text` appears with 0.41 seconds flat,
which was the runtime copying the line and allocating its string. With the runtime ignored instead,
every sample that touched any `runtime.` function is gone, and **`tally.Count` drops from 82.50% to
37.67%**: the report now describes a different, imaginary program, one that never allocates.
`-ignore` is for removing something genuinely unrelated, a background job sharing the process; it is
the wrong tool for removing noise.

`-nodefraction` is the gentle version, hiding the small rows and touching nothing else:

```
ana@vm:~/prof$ go tool pprof -top -nodefraction=0.05 cpu.out | sed /^Time:/d
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 6.33s, Total samples = 6s (94.76%)
Showing nodes accounting for 2.70s, 45.00% of 6s total
Dropped 173 nodes (cum <= 0.30s)
      flat  flat%   sum%        cum   cum%
     1.20s 20.00% 20.00%      2.53s 42.17%  strings.Fields
     0.53s  8.83% 28.83%      0.53s  8.83%  runtime.asyncPreempt
     0.31s  5.17% 34.00%      0.70s 11.67%  runtime.mallocgcSmallScanNoHeaderSC7
     0.22s  3.67% 37.67%      4.95s 82.50%  example.com/hits/internal/tally.Count
     0.10s  1.67% 39.33%      0.45s  7.50%  time.ParseDuration
     0.10s  1.67% 41.00%      0.59s  9.83%  time.parseRFC3339[go.shape.string]
     0.07s  1.17% 42.17%      0.67s 11.17%  time.Parse
     0.06s  1.00% 43.17%      0.31s  5.17%  runtime.mapaccess2_faststr
     0.03s   0.5% 43.67%      0.51s  8.50%  runtime.bgsweep
     0.03s   0.5% 44.17%      0.75s 12.50%  runtime.makeslice
     0.02s  0.33% 44.50%      3.82s 63.67%  example.com/hits/internal/tally.Parse
     0.02s  0.33% 44.83%      1.05s 17.50%  runtime.mallocgc
     0.01s  0.17% 45.00%      0.30s  5.00%  runtime.unlockWithRank (inline)
         0     0% 45.00%      0.41s  6.83%  bufio.(*Scanner).Text (inline)
         0     0% 45.00%      4.95s 82.50%  example.com/hits/internal/tally_test.BenchmarkCount
         0     0% 45.00%      0.38s  6.33%  runtime.goschedImpl
         0     0% 45.00%      0.35s  5.83%  runtime.gosched_m
         0     0% 45.00%      0.37s  6.17%  runtime.mcall
         0     0% 45.00%      0.41s  6.83%  runtime.slicebytetostring
         0     0% 45.00%      0.51s  8.50%  runtime.systemstack
         0     0% 45.00%      0.30s  5.00%  runtime.unlock (inline)
         0     0% 45.00%      4.95s 82.50%  testing.(*B).run1.func1
         0     0% 45.00%      4.95s 82.50%  testing.(*B).runN
```

173 rows dropped, every one under 0.30 seconds cum, and the 23 left are the ones worth reading.

## The call graph, if you want it

`go tool pprof` can also draw the profile as a graph, one box per function and an arrow per call,
the size of its name following its flat and the weight of an arrow following its time. It uses
Graphviz's `dot`, which Ubuntu installs with `sudo apt install graphviz`, and writes SVG, PNG or
PDF:

```
ana@vm:~/prof$ go tool pprof -svg -output graph.svg cpu.out
Generating report in graph.svg
ana@vm:~/prof$ stat -c "%s bytes  %n" graph.svg
153168 bytes  graph.svg
```

The file opens in any browser. It shows the same numbers as `-peek` for every function at once, and
for a program with a deep, branching call tree it is the quickest way to see which path carries the
time. For `hits` the shape is simple enough that the next section's drawing says more.
