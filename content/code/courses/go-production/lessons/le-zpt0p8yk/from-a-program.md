---
title: A profile from a program
version: 1
---

A benchmark measures a function on input you chose. Sometimes the question is about the whole
program on its real input: **the slow thing is a command somebody runs, and it is slow on their
file**. Then the program profiles itself. `runtime/pprof` has four functions that matter for that,
`StartCPUProfile` and `StopCPUProfile` around the work, and `WriteHeapProfile` or `Lookup` for the
memory, and they are what `go test` calls on your behalf when you pass it `-cpuprofile`.

Rather than add flags to `hits` itself, the profiling goes into a second program beside `genlog`,
which counts a file the way `hits count` does and writes the two profiles. In `~/prof`, save it as
`tools/profcount/main.go`:

```schooling-example
{
  "language": "go",
  "file": "tools/profcount/main.go",
  "parts": [
    {
      "code": "// Command profcount counts a log the way hits count does, and writes a CPU\n// profile of the count and a heap profile at the end of it.\npackage main\n\nimport (\n\t\"flag\"\n\t\"fmt\"\n\t\"os\"\n\t\"runtime\"\n\t\"runtime/pprof\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "A program of its own under `tools/`, like `genlog`, so the tool that ships stays free of profiling code. `runtime/pprof` is the package that writes profiles; the flags name the files."
    },
    {
      "code": "func main() {\n\tcpu := flag.String(\"cpuprofile\", \"\", \"write a CPU profile to `file`\")\n\tmem := flag.String(\"memprofile\", \"\", \"write a heap profile to `file`\")\n\tflag.Parse()\n\tif err := run(flag.Arg(0), *cpu, *mem); err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"profcount:\", err)\n\t\tos.Exit(1)\n\t}\n}\n",
      "note": "**`main` only reads the flags and reports an error.** The work is in `run`, which returns instead of exiting, and the reason is in the next part."
    },
    {
      "code": "func run(path, cpu, mem string) error {\n\tif cpu != \"\" {\n\t\tf, err := os.Create(cpu)\n\t\tif err != nil {\n\t\t\treturn err\n\t\t}\n\t\tdefer f.Close()\n\t\tif err := pprof.StartCPUProfile(f); err != nil {\n\t\t\treturn err\n\t\t}\n\t\tdefer pprof.StopCPUProfile()\n\t}\n",
      "note": "**`StartCPUProfile` turns the 100 Hz sampling on and streams samples to the file; `StopCPUProfile` turns it off and writes the end of the profile.** Deferred calls run last first, so the profile is stopped before its file is closed. An `os.Exit` or a `log.Fatal` inside `run` would skip both defers and leave an empty file, which is why `run` returns its errors to `main`."
    },
    {
      "code": "\tin, err := os.Open(path)\n\tif err != nil {\n\t\treturn err\n\t}\n\tdefer in.Close()\n\ts, err := tally.Count(in)\n\tif err != nil {\n\t\treturn err\n\t}\n\tfmt.Printf(\"%d lines, %d paths\\n\", s.Lines, len(s.ByPath))\n",
      "note": "The part being measured: open the file and count it, exactly as `hits count` does. Everything between `StartCPUProfile` and the return of `run` is in the CPU profile."
    },
    {
      "code": "\tif mem != \"\" {\n\t\tf, err := os.Create(mem)\n\t\tif err != nil {\n\t\t\treturn err\n\t\t}\n\t\tdefer f.Close()\n\t\truntime.GC()\n\t\treturn pprof.WriteHeapProfile(f)\n\t}\n\treturn nil\n}",
      "note": "**The heap profile describes the heap as of the most recent garbage collection**, so `runtime.GC()` first makes it describe now. `WriteHeapProfile` writes the `heap` profile; the same file holds all four views of section 02."
    }
  ]
}
```

`hits` never learns that it was measured, and the measuring code never ships. When the program you
need to profile is the one that ships, the same calls go into it, behind a flag such as
`-cpuprofile`; the Go compiler itself has exactly that flag, and `go tool compile -help` lists it
beside `-memprofile`.

## Two million lines

Section 03's log was 4.6 MB. What matters for `hits` is the log a busy server writes in a day,
and `genlog` makes one of those as easily:

```
ana@vm:~/prof$ go run ./tools/genlog -n 2000000 > big.log
ana@vm:~/prof$ stat -c "%s bytes  %n" big.log
91465537 bytes  big.log
ana@vm:~/prof$ go build -o profcount ./tools/profcount
ana@vm:~/prof$ ./profcount -cpuprofile count.cpu -memprofile count.mem big.log
2000000 lines, 8 paths
ana@vm:~/prof$ stat -c "%s bytes  %n" count.cpu count.mem
6657 bytes  count.cpu
1355 bytes  count.mem
```

**91,465,537 bytes**, two million lines, and the eight paths of `genlog`'s list. The profiles are
small, a few kilobytes each, because a profile holds each distinct stack once with a count beside
it, and a program this simple has few distinct stacks however many times it runs them.

The CPU profile first:

```
ana@vm:~/prof$ go tool pprof -top count.cpu | sed /^Time:/d | head -10
File: profcount
Build ID: e7da116405d9a0162329433c437ea1a89bdf4d5d
Type: cpu
Duration: 615.04ms, Total samples = 620ms (100.81%)
Showing nodes accounting for 620ms, 100% of 620ms total
      flat  flat%   sum%        cum   cum%
     120ms 19.35% 19.35%      210ms 33.87%  strings.Fields
      40ms  6.45% 25.81%       40ms  6.45%  runtime.asyncPreempt
      30ms  4.84% 30.65%       30ms  4.84%  runtime.lock2
      30ms  4.84% 35.48%       40ms  6.45%  runtime.unlock2
```

The run lasted 615 milliseconds and the profile holds 62 samples, too few to rank anything but the
first row with confidence. That row is the one the benchmark found: **`strings.Fields`, about a fifth
of the samples on its own and a third counting what it calls**. The rows below it are small and
belong to the runtime. `runtime.asyncPreempt` is where a sample lands when the runtime has just
interrupted a goroutine to let something else run, the garbage collector for one, and `lock2` and
`unlock2` are its internal locks; in a run this short, three or four samples apiece is all they are.

## Live memory and all memory

The heap profile is the more surprising of the two. Opened as it is, on its default view:

```
ana@vm:~/prof$ go tool pprof -top count.mem | sed /^Time:/d | head -9
File: profcount
Build ID: e7da116405d9a0162329433c437ea1a89bdf4d5d
Type: inuse_space
Showing nodes accounting for 2210.27kB, 100% of 2210.27kB total
      flat  flat%   sum%        cum   cum%
 1184.27kB 53.58% 53.58%  1184.27kB 53.58%  runtime/pprof.StartCPUProfile
    1026kB 46.42%   100%     1026kB 46.42%  runtime.mallocgc
         0     0%   100%  1184.27kB 53.58%  main.main
         0     0%   100%  1184.27kB 53.58%  main.run
```

**2.2 MB live, and none of it belongs to `tally`.** More than half is the CPU profiler's own buffer,
allocated by `StartCPUProfile`, and the rest the runtime's. By the time the heap profile was written,
after `runtime.GC()`, everything `Count` had made was garbage and had been collected, and the two
small maps of eight paths and ten statuses are far too little to be picked by one sample in 512 KB.
`inuse_space` answers "what is holding memory now", and for `hits` the answer is nothing.

The other question is "what was allocated along the way":

```
ana@vm:~/prof$ go tool pprof -top -sample_index=alloc_space count.mem | sed /^Time:/d | head -8
File: profcount
Build ID: e7da116405d9a0162329433c437ea1a89bdf4d5d
Type: alloc_space
Showing nodes accounting for 253.02MB, 99.15% of 255.18MB total
Dropped 15 nodes (cum <= 1.28MB)
      flat  flat%   sum%        cum   cum%
  143.51MB 56.24% 56.24%   143.51MB 56.24%  strings.Fields
  109.51MB 42.91% 99.15%   109.51MB 42.91%  bufio.(*Scanner).Text (inline)
```

**255.18 MB allocated to count a 91 MB file**, all of it by the same two functions the benchmark
named, and all of it garbage within moments. That is about 133 bytes a line, which is what section
03's 13,323,728 bytes for 100,000 lines works out to as well. Two profiles of different programs
on different input agree to the byte per line, which is the kind of check worth making before
believing either. A count that allocates nearly three times the size of its input and keeps none
of it is the second finding of this lesson, and lesson 13 removes most of it.
