---
title: GOGC and GOMEMLIMIT, measured
version: 1
---
Both settings are easy to change and both are often changed for the wrong reason. **`GOGC` decides
how far the heap may grow past what survived the last cycle; `GOMEMLIMIT` puts a ceiling on all the
memory the runtime holds.** Lesson 24 of the `go` course introduced the two and measured them on a
small program. This section measures them on a program with a large live heap, reads the pacer's
arithmetic out of a trace, and ends with the case where a limit makes things much worse.

## A program that keeps what it reads

`hits count` keeps nothing, so section 03 found `GOGC` deciding very little for it. Some questions
need every line at once: the 99th percentile of the durations, for one, needs them all sorted. A
small package in `~/mem-hits` loads a whole log, built on lesson 1's `tally.Parse`. Save it as
`internal/keep/keep.go`:

```go
// Package keep holds a whole access log in memory, for the questions that
// need every line at once.
package keep

import (
	"bufio"
	"cmp"
	"fmt"
	"io"
	"slices"

	"example.com/hits/internal/tally"
)

// Load parses every line of r. hint is how many lines the caller expects,
// and 0 means it does not know.
func Load(r io.Reader, hint int) ([]tally.Entry, error) {
	entries := make([]tally.Entry, 0, hint)
	sc := bufio.NewScanner(r)
	for n := 1; sc.Scan(); n++ {
		e, err := tally.Parse(sc.Text())
		if err != nil {
			return nil, fmt.Errorf("line %d: %w", n, err)
		}
		entries = append(entries, e)
	}
	return entries, sc.Err()
}

// BySlowest sorts entries in place, the slowest first.
func BySlowest(entries []tally.Entry) {
	slices.SortFunc(entries, func(a, b tally.Entry) int {
		return cmp.Compare(b.Duration, a.Duration)
	})
}
```

And a command that uses it:

```schooling-example
{
  "language": "go",
  "file": "cmd/slowest/main.go",
  "parts": [
    {
      "code": "// Command slowest reads a whole access log into memory and prints the 99th\n// percentile of its durations, then what that cost the garbage collector.\npackage main\n\nimport (\n\t\"bufio\"\n\t\"flag\"\n\t\"fmt\"\n\t\"os\"\n\t\"runtime/metrics\"\n\t\"strings\"\n\t\"time\"\n\n\t\"example.com/hits/internal/keep\"\n)\n",
      "note": "A second command in the same module, in `cmd/slowest`. It imports `keep`, and through it lesson 1's `tally`."
    },
    {
      "code": "func main() {\n\thint := flag.Int(\"hint\", 0, \"how many lines to expect (0: unknown)\")\n\tflag.Parse()\n\tif flag.NArg() != 1 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: slowest [-hint lines] file\")\n\t\tos.Exit(2)\n\t}\n\tf, err := os.Open(flag.Arg(0))\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, err)\n\t\tos.Exit(1)\n\t}\n\tdefer f.Close()\n",
      "note": "`-hint` is passed straight to `keep.Load`. It stays at 0 until section 06, which measures what it is worth."
    },
    {
      "code": "\tstart := time.Now()\n\tentries, err := keep.Load(f, *hint)\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, err)\n\t\tos.Exit(1)\n\t}\n\tkeep.BySlowest(entries)\n\tfmt.Printf(\"%d requests, p99 %v, slowest %v\\n\",\n\t\tlen(entries), entries[len(entries)/100].Duration, entries[0].Duration)\n",
      "note": "**The work: every line parsed and kept, then sorted.** The 99th percentile is the duration one hundredth of the way down the sorted list; 1% of requests took longer."
    },
    {
      "code": "\ts := []metrics.Sample{{Name: \"/gc/cycles/total:gc-cycles\"}}\n\tmetrics.Read(s)\n\tfmt.Printf(\"%v, %d collections, peak %s\\n\",\n\t\ttime.Since(start).Round(time.Millisecond), s[0].Value.Uint64(), peak())\n}\n",
      "note": "Then what it cost: the wall-clock time, the number of collections the runtime counted, and the peak memory."
    },
    {
      "code": "// peak is the most memory the process has held at once, as Linux counts it.\nfunc peak() string {\n\tf, err := os.Open(\"/proc/self/status\")\n\tif err != nil {\n\t\treturn \"unknown\"\n\t}\n\tdefer f.Close()\n\tsc := bufio.NewScanner(f)\n\tfor sc.Scan() {\n\t\tif v, ok := strings.CutPrefix(sc.Text(), \"VmHWM:\"); ok {\n\t\t\treturn strings.TrimSpace(v)\n\t\t}\n\t}\n\treturn \"unknown\"\n}",
      "note": "**`VmHWM` is the kernel's high-water mark** for the process's resident memory, read from `/proc/self/status`. It counts everything the process ever had in memory at once, not only what the runtime calls heap, which makes it the number a container's memory limit would be compared with."
    }
  ]
}
```

Built, and run on the two million lines of section 03:

```
ana@vm:~/mem-hits$ go build -o slowest ./cmd/slowest && ./slowest big.log
2000000 requests, p99 396ms, slowest 400ms
1.73s, 20 collections, peak 616320 kB
```

1% of the requests took 396 ms or more and the slowest took 400, which is `genlog`'s ceiling.
**Twenty collections in 1.73 seconds, and a peak of 616,320 kB**, about 600 MiB, for a 91 MB file.
Every line is kept twice over: the `Entry`, and the line's text, which the `Method` and `Path`
strings still point into, the effect lesson 24 of the `go` course showed with a 16-byte substring.

## The pacer's arithmetic

Two consecutive lines of its trace, from the part of the run where the heap is growing:

```
ana@vm:~/mem-hits$ GODEBUG=gctrace=1 ./slowest big.log 2>&1 | grep -E "^gc 1[45] "
gc 14 @0.306s 6%: 0.018+12+1.9 ms clock, 0.073+0/11/13+7.7 ms cpu, 98->98->92 MB, 107 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 15 @0.385s 5%: 0.13+23+0.031 ms clock, 0.52+0/18/41+0.12 ms cpu, 156->158->79 MB, 184 MB goal, 0 MB stacks, 0 MB globals, 4 P
ana@vm:~/mem-hits$ sed -n 1295p /usr/local/go/src/runtime/mgcpacer.go
		gcPercentHeapGoal = c.heapMarked + (c.heapMarked+c.lastStackScan.Load()+c.globalsScan.Load())*uint64(gcPercent)/100
```

**The goal of each cycle is set by the one before it.** `gc 14` found 92 MB alive, and `gc 15` aimed
to finish under 184 MB, twice that. The line of `mgcpacer.go` is the whole rule: the heap marked
alive, plus that heap and the scanned stacks and package variables multiplied by `GOGC` over 100.
Stacks and globals are 0 MB here, so the goal is 92 + 92 × 100/100. A program with a hundred
thousand deep goroutines would see its stacks raise the goal too, which is why the trace reports
them.

`gc 15` also started at 156 MB, well before the goal: the runtime starts a cycle early enough that
marking can finish before the heap reaches its goal, judging from how the previous cycle went. Its
23 ms of marking ran beside the program.

## GOGC on the table

The same binary under five settings, the program's last line each time:

```
ana@vm:~/mem-hits$ for g in 50 100 200 400 off; do echo "GOGC=$g: $(GOGC=$g ./slowest big.log | tail -1)"; done
GOGC=50: 1.852s, 25 collections, peak 518160 kB
GOGC=100: 1.598s, 15 collections, peak 682448 kB
GOGC=200: 1.52s, 9 collections, peak 577992 kB
GOGC=400: 1.417s, 5 collections, peak 746924 kB
GOGC=off: 1.287s, 0 collections, peak 1016500 kB
```

Read the columns separately, because they do not move together.

- Collections fall cleanly: 25, 15, 9, 5, 0. Doubling `GOGC` roughly halves them, because each
  cycle may let the heap grow twice as far.
- Time falls a little: from 1.85 to 1.29 seconds, end to end, on four processors where most of
  the marking ran in parallel with the program.
- The peak does not follow the setting between 50 and 400: 518,160 kB, then 682,448, 577,992
  and 746,924. Only `off` stands apart, at 1,016,500 kB, everything the program ever allocated.

The peak is noisy because **the largest allocations in this program are its own**. `Load` grows its
slice with `append`, and each time the array is full, a larger one is allocated beside it and the
old contents copied across. Near the end both arrays exist at once, and where a cycle falls relative
to that moment decides the peak more than `GOGC` does. Section 06 removes those copies and the peak
drops by a third. A knob on the collector cannot fix memory the program asks for itself.

What `off` buys shows best in processor time:

```
ana@vm:~/mem-hits$ time ./slowest big.log > /dev/null

real	0m1.609s
user	0m1.256s
sys	0m0.550s
ana@vm:~/mem-hits$ time GOGC=off ./slowest big.log > /dev/null

real	0m1.393s
user	0m0.739s
sys	0m0.596s
```

**Without collection the program used 0.74 seconds of user time instead of 1.26**, the marking it no
longer did. The wall clock moved only from 1.61 to 1.39 seconds, because that marking had been
running on processors that were otherwise idle. On a machine with spare processors and spare memory,
a larger `GOGC` is nearly free. On a busy one, or a small one, those 0.5 seconds of processor are
taken from something else.

## GOMEMLIMIT: a ceiling, and where it stops helping

A container's memory limit is a number of bytes; `GOGC` is a proportion, and knows nothing of the
container. **The runtime does not look for that limit itself.** It does read the container's
processor quota, to set `GOMAXPROCS`, and that is the only thing its control-group code reads:

```
ana@vm:~/mem-hits$ grep -n "^func" /usr/local/go/src/runtime/cgroup_linux.go
45:func defaultGOMAXPROCSInit() {
75:func defaultGOMAXPROCSUpdateGODEBUG() {
85:func defaultGOMAXPROCS(ncpu int32) int32 {
109:func adjustCgroupGOMAXPROCS(procs int32, cpu cgroup.CPU) int32 {
```

So the limit has to be passed in, and the useful pattern for a program alone in a container of known
size is to turn the proportional rule off and let only the limit trigger collections:

```
ana@vm:~/mem-hits$ GOGC=off GOMEMLIMIT=400MiB ./slowest big.log
2000000 requests, p99 396ms, slowest 400ms
1.639s, 3 collections, peak 464288 kB
```

**Three collections instead of twenty, and a peak of 464,288 kB**, which is 453 MiB, past the 400
MiB limit. Two things make that possible, and a container needs a margin for both. The limit is
soft: it makes the runtime collect harder, and it cannot free memory the program still uses. And it
counts what the runtime manages, not everything Linux counts as resident:
`runtime/debug.SetMemoryLimit`'s documentation lists what it leaves out, the binary itself and
memory that C code or the kernel holds for the process among them.

Now the other direction: a limit of 100 MiB, well under what this program keeps alive, as its trace
will show:

```
ana@vm:~/mem-hits$ GOMEMLIMIT=100MiB ./slowest big.log
2000000 requests, p99 396ms, slowest 400ms
3.13s, 66 collections, peak 343024 kB
ana@vm:~/mem-hits$ GOMEMLIMIT=100MiB GODEBUG=gctrace=1 ./slowest big.log 2>&1 | grep -E "^gc 3[89] "
gc 38 @1.530s 18%: 0.11+41+0.037 ms clock, 0.45+0/36/68+0.14 ms cpu, 161->164->162 MB, 161 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 39 @1.578s 18%: 0.34+66+0.036 ms clock, 1.3+7.0/58/115+0.14 ms cpu, 162->168->166 MB, 162 MB goal, 0 MB stacks, 0 MB globals, 4 P
```

**Sixty-six collections and 3.13 seconds, against twenty and 1.73.** The two trace lines show why.
`161->164->162 MB, 161 MB goal`: the cycle started at its goal, marked, and found 162 MB of the 164
alive. It freed nothing worth having, the heap is already past the limit, so the next goal is the
heap as it stands, and the next cycle starts almost at once. `gc 38` and `gc 39` began 48 ms apart.
The `18%` is the share of the whole run spent collecting; the run with no limit printed 6% and 5%
with a heap of similar size.

Without a brake, that loop is a **death spiral**: the closer the live heap comes to the limit, the
more often the collector runs, until it takes every processor and the program makes no progress at
all. The runtime has a brake for exactly this:

```
ana@vm:~/mem-hits$ sed -n 9,14p /usr/local/go/src/runtime/mgclimit.go
// gcCPULimiter is a mechanism to limit GC CPU utilization in situations
// where it might become excessive and inhibit application progress (e.g.
// a death spiral).
//
// The core of the limiter is a leaky bucket mechanism that fills with GC
// CPU time and drains with mutator time. Because the bucket fills and
```

The rest of that comment explains that the bucket's arithmetic amounts to a limit of 50%: past it,
the collector is held back and the heap is allowed to exceed the limit instead. **The program
finished, slowly, which is what soft means**, and it is a better outcome than a process killed for
using too much memory. It is still a program running at half speed with nobody told why, and a
`gctrace` line whose start, end, live heap and goal are all the same number is the sign to look for.

## Setting them from inside the program

The environment variables are how an operator chooses; `runtime/debug` has a function for each, for
a program that chooses for itself. Both return the old value, which makes them readable too. In
`~/mem-knobs`, `main.go`:

```go
// Command knobs reads the collector's two settings from inside a program,
// and changes one of them.
package main

import (
	"fmt"
	"runtime/debug"
)

func main() {
	old := debug.SetGCPercent(200)
	fmt.Printf("GOGC was %d, and is now 200\n", old)
	limit := debug.SetMemoryLimit(-1) // a negative value changes nothing
	fmt.Printf("the memory limit is %d bytes\n", limit)
}
```

```
ana@vm:~/mem-knobs$ go run .
GOGC was 100, and is now 200
the memory limit is 9223372036854775807 bytes
ana@vm:~/mem-knobs$ GOGC=off GOMEMLIMIT=512MiB go run .
GOGC was -1, and is now 200
the memory limit is 536870912 bytes
```

`GOGC=off` reads back as -1, which is also what `SetGCPercent(-1)` sets. **With no limit given, the
limit is 9,223,372,036,854,775,807 bytes, `math.MaxInt64`**, the runtime's way of saying there is
none, and `512MiB` is read as 536,870,912 bytes, powers of two as the documentation promises.

## When to touch them

Rarely, and with a number in hand. A setting changed because a blog post said so costs memory or
processor in a direction nobody measured.

| situation | what the numbers say | what to do |
|---|---|---|
| a CLI like `hits count` | `#%` at 0 to 1%, live heap near 0 | nothing: there is nothing to gain |
| a container with a hard memory limit | the process is killed near the limit | set `GOMEMLIMIT` a margin below it, perhaps with `GOGC=off` |
| memory to spare, processors busy | `#%` high, live heap far below the machine | raise `GOGC`, and measure the peak |
| memory is the constraint | peak too high, `#%` low | lower `GOGC`, or keep less alive |
| the heap is mostly the program's own growth | peak noisy whatever `GOGC` says | change the program: section 06 |

The first column of a `gctrace` line that matters is `#%`, and the second is the live heap. If the
first is small, no setting will make the program noticeably faster, and if the limit is under the
second, no setting will make it smaller.
