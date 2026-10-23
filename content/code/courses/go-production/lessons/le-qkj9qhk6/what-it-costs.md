---
title: What it costs, measured on hits
version: 1
---

`go-concurrency` lesson 16 measured the detector on a program that did nothing but take a lock and
touch a map, and found it twelve times slower with nine times the memory. **Those ratios belong to
that program, and a pipeline runs yours.** So measure the price on the code the pipeline will
actually test: `BenchmarkCountParallel` from section 02, which parses 20,000 lines with four
workers, now on the fixed `CountParallel` of section 03.

## Time, with the benchmark

`-run "^$"` matches no test name, so only the benchmark runs. Once plainly and once with the
detector:

```
ana@vm:~/race-hits$ go test -run "^$" -bench . -benchmem ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCountParallel-4   	      93	  10830468 ns/op	 4132806 B/op	   40042 allocs/op
PASS
ok  	example.com/hits/internal/tally	1.032s
ana@vm:~/race-hits$ go test -race -run "^$" -bench . -benchmem ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCountParallel-4   	      20	  50833093 ns/op	 4133512 B/op	   40044 allocs/op
PASS
ok  	example.com/hits/internal/tally	2.059s
```

**10,830,468 nanoseconds per run plainly, 50,833,093 with the detector: nearly five times as long.**
The ratio moves between runs on a machine other work shares, from under five to over seven in the
runs made for this lesson, so read it as "several times", not as 4.7. The
other two columns are the surprise. `-benchmem` reported 4,132,806 bytes per run against 4,133,512,
and 40,042 allocations against 40,044: the same. That is not the detector being free. `-benchmem`
counts what the Go heap handed out, and **the detector keeps its records outside the Go heap**, in
memory the runtime's allocation statistics never see. To see that memory you have to ask the
operating system.

## Memory, from the kernel

`go test -c` builds a package's test binary without running it, so the two builds can be run like
any program. The kernel keeps a high-water mark of each process's memory, the `VmHWM` line of
`/proc/PID/status`; the loop below reads it every tenth of a second while the benchmark runs and
prints the last reading before the process goes:

```
ana@vm:~/race-hits$ go test -c -o tally.test ./internal/tally && go test -race -c -o tally-race.test ./internal/tally
ana@vm:~/race-hits$ stat -c "%s bytes  %n" tally.test tally-race.test
4745513 bytes  tally.test
6049910 bytes  tally-race.test
ana@vm:~/race-hits$ ./tally.test -test.run "^$" -test.bench . > /dev/null & p=$!; while m=$(grep VmHWM /proc/$p/status 2>/dev/null); do h=$m; sleep 0.1; done; echo "$h"
VmHWM:	   19748 kB
ana@vm:~/race-hits$ ./tally-race.test -test.run "^$" -test.bench . > /dev/null & p=$!; while m=$(grep VmHWM /proc/$p/status 2>/dev/null); do h=$m; sleep 0.1; done; echo "$h"
VmHWM:	   46020 kB
```

**19,748 kB at the peak plainly, 46,020 kB with the detector: more than twice as much**, for the same benchmark and the same Go heap. The binary grew from 4,745,513 bytes to
6,049,910, about 1.3 MB, which is the detector's runtime linked in plus the extra calls compiled
around every memory access. As `go-concurrency` lesson 16 found on its own program, the size is small and the price
is paid while the program runs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Bar chart: the race-enabled build of the CountParallel benchmark compared with the plain build. Time per run 10.83 ms against 50.83 ms, 4.7 times. Peak memory 19,748 kB against 46,020 kB, 2.3 times. Test binary 4,745,513 against 6,049,910 bytes, 1.3 times. Heap allocated per run, as -benchmem reports it, 4,132,806 against 4,133,512 bytes, the same: the detector's own memory is not on the Go heap.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the -race build, as a multiple of the plain build</text><text x=\"20\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">time per benchmark run</text><text x=\"20\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.83 ms / 50.83 ms</text><rect x=\"230\" y=\"50\" width=\"243.9\" height=\"22\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"483.88\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4.7 times</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">peak memory, VmHWM</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19,748 kB / 46,020 kB</text><rect x=\"230\" y=\"96\" width=\"121.2\" height=\"22\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"361.15999999999997\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2.3 times</text><text x=\"20\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">size of the test binary</text><text x=\"20\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,745,513 B / 6,049,910 B</text><rect x=\"230\" y=\"142\" width=\"66.0\" height=\"22\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"306.04\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1.3 times</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">heap per run, B/op</text><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,132,806 / 4,133,512</text><rect x=\"230\" y=\"188\" width=\"52.0\" height=\"22\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"292.0\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the same</text><path d=\"M282 40 V47\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M282 75 V93\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M282 121 V139\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M282 167 V185\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M282 213 V224\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" fill=\"none\"></path><text x=\"282\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">plain build</text></svg>", "caption": "One benchmark, measured twice. The detector costs time and memory while the program runs; -benchmem counts only the Go heap, so it shows none of the memory."}
```

There is no fixed ratio to quote. Code that spends its time on memory, like a parser filling maps,
pays the most; code that spends its time waiting on a disk or a network pays the least, because
waiting touches no memory the detector has to check. **Measure your own test suite once with and
without `-race`** and you know what the pipeline step will cost; the next section budgets for it.

## A second at every exit

One cost is not proportional at all. Here is the same package's tests, plain and then with the
detector:

```
ana@vm:~/race-hits$ go test -count=1 ./internal/tally; go test -race -count=1 ./internal/tally
ok  	example.com/hits/internal/tally	0.003s
ok  	example.com/hits/internal/tally	1.017s
ana@vm:~/race-hits$ GORACE=atexit_sleep_ms=0 go test -race -count=1 ./internal/tally
ok  	example.com/hits/internal/tally	0.013s
```

Three milliseconds plainly and 1.017 seconds with the detector, for tests that take almost no time.
**A program built with `-race` waits one second before it exits.** The detector's own description of its options gives it as `atexit_sleep_ms`, at 1,000, "useful to catch 'at exit' races". A goroutine still running when `main` returns gets a moment to make its accesses and be reported.
With `GORACE=atexit_sleep_ms=0` the same run took 0.013 seconds.

Every test binary in a module pays that second, so a module of thirty packages pays about thirty
seconds of sleeping, spread across the parallel runs `go test` makes. It is also part of any timing
of a short `-race` program with the shell's `time`, which is one more reason to measure with a
benchmark: `ns/op` is taken inside the run and never includes the exit. Setting it to 0 in CI trades
those seconds for the races that happen as the program ends. **Keep the default unless the seconds hurt**, and if you change it, change it knowing which goroutines in your code outlive `main`.

## What it needs

The detector is a C++ runtime, ThreadSanitizer from the LLVM project, linked into the Go binary, so
`-race` needs cgo, and cgo needs a C compiler. Lesson 1 installed `gcc` for this reason and showed
what a machine without one prints. A pipeline can lose cgo another way, by setting `CGO_ENABLED=0`
for the whole job, which many do to build static binaries:

```
ana@vm:~/race-hits$ CGO_ENABLED=0 go test -race ./...; echo $?
go: -race requires cgo; enable cgo by setting CGO_ENABLED=1
2
```

**Same message as lesson 1, different cause**: here the compiler is installed and the variable
turned cgo off. Section 05 sets `CGO_ENABLED=1` on the step that runs the detector for exactly this
reason.

The second limit is the platform. `go help build` lists where `-race` works, and asking for any other
platform fails before anything is compiled:

```
ana@vm:~/race-hits$ go help build | grep -A4 "enable data race"
		enable data race detection.
		Supported only on darwin/amd64, darwin/arm64, freebsd/amd64, linux/amd64,
		linux/arm64 (only for 48-bit VMA), linux/ppc64le, linux/riscv64 and
		windows/amd64.
	-msan
ana@vm:~/race-hits$ GOARCH=386 go test -race ./...; echo $?
-race is not supported on linux/386
2
```

Eight pairs of operating system and architecture, all 64-bit. The toolchain's own list, in its
source, admits three more than the help text names, `linux/loong64`, `linux/s390x` and
`netbsd/amd64`, and race runtimes for them ship in `/usr/local/go/src/runtime/race`. **For a
pipeline the practical answer is short: run the race step on `linux/amd64` or `linux/arm64`**, which
is where most CI machines run, and let the cross-compiled release builds of lesson 16 go without it.
A 32-bit target like `linux/386` has no detector at all.
