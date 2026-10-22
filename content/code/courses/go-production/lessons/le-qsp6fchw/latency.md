---
title: Waiting is time too
version: 1
---

**A goroutine's wall time is the time it ran, the time it was ready and had no processor, and the
time it was blocked.** Lesson 12's CPU profile measures the first and only the first, since it
samples what is on a processor. Its block and mutex profiles count the third, once turned on, by
the call that blocked. The middle one, ready and not running, is in no pprof profile at all, and
it is what people mean by **scheduler latency**. A trace has all three, for every goroutine, in
order.

The usual wrong idea is that a program that got no faster with more goroutines must be doing too
much work. Sometimes it is doing too much waiting, and from the outside the two look the same.

## More workers, no faster

`pcount` with one, two, four and eight workers, one after the other:

```
ana@vm:~/trace-hits$ for w in 1 2 4 8; do ./pcount -workers $w big.log; done
3000000 lines (0 bad), 8 paths, 1 workers, 1.466s
3000000 lines (0 bad), 8 paths, 2 workers, 1.689s
3000000 lines (0 bad), 8 paths, 4 workers, 2.084s
3000000 lines (0 bad), 8 paths, 8 workers, 2.053s
```

On four CPUs, four workers took longer than one. Section 02's traced runs had gone the other way,
958ms against 1.357s, and **that disagreement is itself the first finding**: whatever limits this
program, it is not the number of goroutines parsing.

## A lock held too long

`-shared` is the version a hurried person writes: one `tally.Summary` for everybody, behind one
mutex, locked around every line, the parse included. It is correct, as the test in section 02
checks. Timed with the shell's `time`, beside one worker:

```
ana@vm:~/trace-hits$ time ./pcount -workers 1 big.log
3000000 lines (0 bad), 8 paths, 1 workers, 1.058s

real	0m1.060s
user	0m1.111s
sys	0m0.166s
ana@vm:~/trace-hits$ time ./pcount -workers 4 -shared big.log
3000000 lines (0 bad), 8 paths, 4 workers, 1.144s

real	0m1.149s
user	0m1.213s
sys	0m0.119s
```

`user` is the processor time the program used: 1.111 seconds for one worker and 1.213 for four
sharing a lock. **Four goroutines did the work of one and used the processor time of one**, so a
CPU profile of the `-shared` run would show `tally.Parse`, `strings.Fields` and the map updates in
much the same proportions as the single worker's. Nothing in it would say that three goroutines
were standing still at any moment.

The trace says so directly. `go tool trace -pprof=sync` turns the time goroutines spent blocked on
synchronisation into a pprof file, which `go tool pprof` reads like any other. `-focus=main.count`
keeps the stacks that pass through `count` and drops the runtime's own goroutines:

```
ana@vm:~/trace-hits$ ./pcount -workers 4 -shared -trace shared.trace big.log
3000000 lines (0 bad), 8 paths, 4 workers, 1.023s
ana@vm:~/trace-hits$ go tool trace -pprof=sync shared.trace > sync.pprof
ana@vm:~/trace-hits$ go tool pprof -top -focus=main.count sync.pprof
Main binary filename not available.
Type: delay
Active filters:
   focus=main.count
Showing nodes accounting for 2.16s, 50.73% of 4.26s total
Dropped 11 nodes (cum <= 0.02s)
      flat  flat%   sum%        cum   cum%
     1.71s 40.15% 40.15%      1.71s 40.15%  sync.(*Mutex).Lock
     0.32s  7.53% 47.68%      0.32s  7.53%  runtime.chansend1
     0.10s  2.27% 49.96%      0.10s  2.27%  runtime.chanrecv2
     0.02s  0.41% 50.36%      0.02s  0.41%  runtime.gcMarkDone
     0.02s  0.37% 50.73%      0.02s  0.37%  runtime.gcStart
         0     0% 50.73%      0.01s  0.32%  example.com/hits/internal/tally.Parse
         0     0% 50.73%      0.01s  0.32%  main.(*part).add
         0     0% 50.73%      0.34s  8.02%  main.count
         0     0% 50.73%      1.82s 42.75%  main.count.func1
         0     0% 50.73%      1.72s 40.47%  main.count.func1.1
         0     0% 50.73%      0.34s  8.02%  main.main
         0     0% 50.73%      0.34s  8.02%  main.run
         0     0% 50.73%      0.02s  0.41%  runtime.gcAssistAlloc
         0     0% 50.73%      0.02s  0.56%  runtime.makeslice
         0     0% 50.73%      0.03s  0.77%  runtime.mallocgc
         0     0% 50.73%      0.01s  0.32%  runtime.mallocgcSmallScanNoHeaderSC7
         0     0% 50.73%      1.72s 40.47%  runtime/trace.WithRegion
         0     0% 50.73%      0.01s  0.32%  strings.Fields
         0     0% 50.73%      1.82s 42.75%  sync.(*WaitGroup).Go.func1
```

`Type: delay` says the numbers are time spent blocked, not time on a processor. **1.71 seconds in
`sync.(*Mutex).Lock`, in a run that lasted 1.023 seconds**. The four workers' waits overlap, so they
add up to more than the wall clock; on average 1.7 of the four were waiting for the lock at any
moment. `main.count.func1.1` is the closure inside `WithRegion`, the one that locks per line.
The first line, `Main binary filename not available.`, is pprof noting that the file names no
binary; the trace carried its own symbols, so nothing is missing.

The same question asked of section 02's four-worker trace, which takes no lock of its own:

```
ana@vm:~/trace-hits$ go tool trace -pprof=sync w4.trace > sync4.pprof && go tool pprof -top -focus=main.count sync4.pprof
Main binary filename not available.
Type: delay
Active filters:
   focus=main.count
Showing nodes accounting for 1497.97ms, 60.10% of 2492.53ms total
Dropped 3 nodes (cum <= 12.46ms)
      flat  flat%   sum%        cum   cum%
  605.17ms 24.28% 24.28%   605.17ms 24.28%  runtime.gcStart
  570.17ms 22.88% 47.15%   570.17ms 22.88%  runtime.chanrecv2
  248.04ms  9.95% 57.11%   248.04ms  9.95%  runtime.gcMarkDone
   74.60ms  2.99% 60.10%    74.60ms  2.99%  runtime.chansend1
         0     0% 60.10%    93.23ms  3.74%  bufio.(*Scanner).Text
         0     0% 60.10%   687.18ms 27.57%  example.com/hits/internal/tally.Parse
         0     0% 60.10%   687.18ms 27.57%  main.(*part).add
         0     0% 60.10%   241.39ms  9.68%  main.count
         0     0% 60.10%  1257.35ms 50.44%  main.count.func1
         0     0% 60.10%   687.18ms 27.57%  main.count.func1.1
         0     0% 60.10%   241.39ms  9.68%  main.main
         0     0% 60.10%   241.39ms  9.68%  main.run
         0     0% 60.10%     8.31ms  0.33%  runtime.deductAssistCredit
         0     0% 60.10%   248.04ms  9.95%  runtime.gcAssistAlloc
         0     0% 60.10%   759.99ms 30.49%  runtime.makeslice
         0     0% 60.10%   853.21ms 34.23%  runtime.mallocgc
         0     0% 60.10%    71.60ms  2.87%  runtime.mallocgcSmallNoScanSC5
         0     0% 60.10%    21.62ms  0.87%  runtime.mallocgcSmallNoScanSC6
         0     0% 60.10%    41.42ms  1.66%  runtime.mallocgcSmallNoScanSlowPath
         0     0% 60.10%    64.50ms  2.59%  runtime.mallocgcSmallScanHeader
         0     0% 60.10%   687.18ms 27.57%  runtime.mallocgcSmallScanNoHeaderSC7
         0     0% 60.10%   205.60ms  8.25%  runtime.mallocgcSmallScanSlowPath
         0     0% 60.10%    93.23ms  3.74%  runtime.slicebytetostring
         0     0% 60.10%   687.18ms 27.57%  runtime/trace.WithRegion
         0     0% 60.10%   687.18ms 27.57%  strings.Fields
         0     0% 60.10%  1257.35ms 50.44%  sync.(*WaitGroup).Go.func1
```

No mutex at all. **The `sync` waits section 03 counted belong to the collector**: `runtime.gcStart`
and `runtime.gcMarkDone` are workers that allocated enough to start a collection, or to help finish
one, and then waited on the collector's own semaphores. `runtime.chanrecv2` is the `range batches`
loop waiting for the reader, 570.17ms of it across the four workers.

## Where the time went, run by run

The Goroutine analysis page splits each goroutine's life into states. Added up over the four
workers, or the one, for each traced run in this lesson, including the `GOMAXPROCS=1` run below:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Stacked bars of how the workers spent their time in four traced runs of pcount. One worker: 73 percent running, 13 runnable, 4 waiting in sync, 10 waiting on a channel receive. Four workers: 31 running, 35 runnable, 18 sync, 15 channel. Four workers sharing one mutex: 22 running, 33 runnable, 42 sync, 2 channel. Four workers with GOMAXPROCS=1: 19 running, 80 runnable, 2 channel.\"><text x=\"200.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">where the workers' time went</text><text x=\"690.0\" y=\"20.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">run</text><text x=\"190.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 worker</text><rect x=\"200.0\" y=\"38.0\" width=\"305.8\" height=\"24.0\" fill=\"var(--phosphor)\"></rect><text x=\"352.9\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">73%</text><rect x=\"505.8\" y=\"38.0\" width=\"53.9\" height=\"24.0\" fill=\"var(--amber)\"></rect><text x=\"532.8\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">13%</text><rect x=\"559.7\" y=\"38.0\" width=\"18.2\" height=\"24.0\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"577.8\" y=\"38.0\" width=\"41.0\" height=\"24.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"598.3\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10%</text><rect x=\"618.8\" y=\"38.0\" width=\"1.2\" height=\"24.0\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"690.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.36 s</text><text x=\"190.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 workers</text><rect x=\"200.0\" y=\"78.0\" width=\"129.4\" height=\"24.0\" fill=\"var(--phosphor)\"></rect><text x=\"264.7\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">31%</text><rect x=\"329.4\" y=\"78.0\" width=\"147.7\" height=\"24.0\" fill=\"var(--amber)\"></rect><text x=\"403.2\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">35%</text><rect x=\"477.0\" y=\"78.0\" width=\"75.3\" height=\"24.0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"514.7\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">18%</text><rect x=\"552.4\" y=\"78.0\" width=\"62.5\" height=\"24.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"583.6\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15%</text><rect x=\"614.9\" y=\"78.0\" width=\"5.1\" height=\"24.0\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"690.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">958 ms</text><text x=\"190.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 workers, -shared</text><rect x=\"200.0\" y=\"118.0\" width=\"93.1\" height=\"24.0\" fill=\"var(--phosphor)\"></rect><text x=\"246.5\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">22%</text><rect x=\"293.1\" y=\"118.0\" width=\"139.2\" height=\"24.0\" fill=\"var(--amber)\"></rect><text x=\"362.7\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">33%</text><rect x=\"432.2\" y=\"118.0\" width=\"176.9\" height=\"24.0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"520.7\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">42%</text><rect x=\"609.2\" y=\"118.0\" width=\"9.9\" height=\"24.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"619.1\" y=\"118.0\" width=\"0.9\" height=\"24.0\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"690.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.02 s</text><text x=\"190.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 workers, GOMAXPROCS=1</text><rect x=\"200.0\" y=\"158.0\" width=\"78.5\" height=\"24.0\" fill=\"var(--phosphor)\"></rect><text x=\"239.2\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">19%</text><rect x=\"278.5\" y=\"158.0\" width=\"335.2\" height=\"24.0\" fill=\"var(--amber)\"></rect><text x=\"446.1\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--ink)\">80%</text><rect x=\"613.7\" y=\"158.0\" width=\"6.3\" height=\"24.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"690.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">768 ms</text><rect x=\"40.0\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--phosphor)\"></rect><text x=\"60.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">running</text><rect x=\"130.8\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--amber)\"></rect><text x=\"150.8\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runnable</text><rect x=\"228.0\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"248.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">waiting: sync</text><rect x=\"357.2\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"377.2\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">waiting: chan receive</text><rect x=\"537.6\" y=\"210.0\" width=\"14.0\" height=\"12.0\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"557.6\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">other</text></svg>", "caption": "The workers' time in four traced runs, from the Goroutine analysis page of go tool trace: each bar adds up every worker's time over the run, with the run's length on the right."}
```

**One worker ran 73% of its time; four workers ran 31% of theirs.** The rest of the four-worker
bar is the answer to section 02's puzzle. A third of it is runnable: four workers, the reader and
the collector's own workers wanted more processors than there were, so ready goroutines queued for
a `P`. Almost a fifth is the collector, and a seventh is waiting for a reader that could not keep
up. In the `-shared` run the lock takes the largest share, 42%, and the running share falls to 22%, below
the 31% of the four workers that shared nothing.

One caveat about all of these. **The trace is the Go scheduler's view.** When the operating system
takes a CPU away from one of the program's threads, as it did often on this shared machine, the
goroutine on that thread still counts as running. A trace explains the time the runtime controls;
the rest shows up as running that took longer than it should.

## Scheduler latency

To see the middle state on its own, give the program one `P` and four workers:

```
ana@vm:~/trace-hits$ GOMAXPROCS=1 ./pcount -workers 4 -trace p1.trace big.log
3000000 lines (0 bad), 8 paths, 4 workers, 768ms
ana@vm:~/trace-hits$ go tool trace -pprof=sched p1.trace > sched.pprof && go tool pprof -top -focus=main -nodecount=6 sched.pprof
Main binary filename not available.
Type: delay
Active filters:
   focus=main
Showing nodes accounting for 3184.43ms, 75.21% of 4234.05ms total
Dropped 4 nodes (cum <= 21.17ms)
Showing top 6 nodes out of 20
      flat  flat%   sum%        cum   cum%
 2437.01ms 57.56% 57.56%  2437.01ms 57.56%  runtime.chansend1
  476.27ms 11.25% 68.81%   476.27ms 11.25%  runtime.chanrecv2
  271.15ms  6.40% 75.21%   271.15ms  6.40%  runtime.systemstack_switch
         0     0% 75.21%    71.73ms  1.69%  bufio.(*Scanner).Text
         0     0% 75.21%   199.43ms  4.71%  example.com/hits/internal/tally.Parse
         0     0% 75.21%   199.43ms  4.71%  main.(*part).add
```

`-pprof=sched` measures **the time between a goroutine becoming runnable and starting to run**. The
profile's total, 4,234.05ms, is five and a half times the run's 768ms: on average more than five
goroutines, the runtime's included, stood ready behind the one that had the `P`. The stack it
charges is where the goroutine was made runnable, which is not where it was waiting. `runtime.chansend1` under `main.count` is the reader
sending a batch: each send woke a worker, and the workers woken that way waited 2,437.01ms in total
for their turn.

The bar for this run in the figure is 80% runnable, and yet 768ms is the shortest run in this
lesson. **Parallelism bought this program nothing on that machine**, because its limit was never the parsing. It was one goroutine reading and allocating a string per line, and a collector
cleaning up after it, 94 times in the four-worker run's 958ms. The trace is what says so, and it also says where to look
next. Lessons 12 and 13 measure the allocations; lessons 19 and 20 explain why they cost what they
do.

| `go tool trace -pprof=` | what it measures | where it charges the time |
|---|---|---|
| `sync` | blocked on a channel, a `select`, a mutex, a `WaitGroup` or a runtime semaphore | the call that blocked |
| `sched` | runnable and waiting for a `P` | where the goroutine was made runnable |
| `syscall` | blocked in a system call | the call that entered it |
| `net` | blocked waiting for the network | the read or write that waited |
