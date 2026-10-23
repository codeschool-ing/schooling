---
title: What a profile records
version: 1
---

The picture most people bring to a profiler is a stopwatch on every function: each call timed on
the way in and on the way out, then added up. **Go's profiler does not time calls at all. It
samples.** While a CPU profile is being taken, the runtime interrupts whatever is running a hundred
times a second, writes down the stack of function calls it finds, and lets the program carry on. A
function that appears in many of those stacks is where the time went, whether it ran once for a
long time or two million times for a moment each.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"A goroutine runs for 60 milliseconds, calling Count, Parse and Fields thousands of times. Every 10 milliseconds the runtime records the stack that is running at that instant: strings.Fields over tally.Parse over tally.Count; tally.Count alone; runtime.mallocgc over Scanner.Text over tally.Count; time.Parse over tally.Parse over tally.Count; and strings.Fields twice more. The profile keeps the six stacks. strings.Fields is on top of three of them, about 30 milliseconds of its own; tally.Count is in all six, about 60 milliseconds including what it called.\"><text x=\"110\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one goroutine counting lines, for 60 ms</text><rect x=\"110\" y=\"32\" width=\"540\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Count, Parse, Fields, Parse, Text, Parse... thousands of calls, none of them timed</text><text x=\"110\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M200 58 V64 M200 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"200\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">10 ms</text><rect x=\"157\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"157\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Parse</text><rect x=\"157\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">strings.Fields</text><path d=\"M290 58 V64 M290 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"290\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">20 ms</text><rect x=\"247\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><path d=\"M380 58 V64 M380 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">30 ms</text><rect x=\"337\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"337\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">(*Scanner).Text</text><rect x=\"337\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">runtime.mallocgc</text><path d=\"M470 58 V64 M470 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">40 ms</text><rect x=\"427\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"427\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Parse</text><rect x=\"427\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">time.Parse</text><path d=\"M560 58 V64 M560 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"560\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">50 ms</text><rect x=\"517\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"517\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Parse</text><rect x=\"517\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">strings.Fields</text><path d=\"M650 58 V64 M650 80 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"650\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">60 ms</text><rect x=\"607\" y=\"158\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Count</text><rect x=\"607\" y=\"132\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">tally.Parse</text><rect x=\"607\" y=\"106\" width=\"86\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">strings.Fields</text><text x=\"16\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">every 10 ms the runtime</text><text x=\"16\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">records the stack</text><path d=\"M16 196 H704\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"16\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what the profile keeps: six stacks, each standing for 10 ms</text><text x=\"16\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">strings.Fields on top of 3 of the 6 stacks: about 30 ms of its own</text><text x=\"16\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tally.Count in all 6 stacks: about 60 ms, counting what it called</text></svg>", "caption": "A CPU profile is a pile of stacks taken at the ticks of a 100 Hz clock, and nothing in between. These six are stacks of the kind the benchmark's profile holds, cut down to the frames from tally.Count up."}
```

**A sample costs the same whatever the program is doing**, which is why it is reasonable to take a
profile from a process serving real traffic, where a stopwatch around every call would not be.
The price is resolution. A tick every 10 milliseconds sees nothing shorter than a tick unless it
happens often. A profile of a run that lasted one second holds about a hundred stacks, so the
third digit of any percentage in it is noise. Section 03 profiles a benchmark that ran for about a
second and gets exactly that.

## Eight profiles, one format

CPU time is one question. The runtime keeps records for several others, and every one of them is
written in the same format and read with the same tool, `go tool pprof`:

| profile | what one sample is | collecting? |
|---|---|---|
| CPU | the stack running when a 10 ms tick fired | only between `StartCPUProfile` and `StopCPUProfile`, or under `-cpuprofile` |
| `heap` | the stack that allocated, picked about once per 512 KB allocated | always |
| `allocs` | the same records as `heap`, shown by default as everything ever allocated | always |
| `goroutine` | the stack of every goroutine that exists at this moment | taken when asked |
| `goroutineleak` | the stack of every goroutine blocked for ever on something no running goroutine can reach | taken when asked, after a garbage collection that looks for them |
| `block` | time a goroutine spent waiting on a channel, a mutex, a `WaitGroup` | **off** until `runtime.SetBlockProfileRate` |
| `mutex` | time other goroutines spent waiting for a lock, charged to whoever held it | **off** until `runtime.SetMutexProfileFraction` |
| `threadcreate` | the stack that made the runtime start an operating system thread | always |

The names in the first column are the runtime's own: `runtime/pprof` lists them in its documentation
and `net/http/pprof` serves them under those names in section 05. The CPU profile has no name in
that list because it works differently: **it streams samples to a file while it runs**, so it has a
start and a stop, where the others are a snapshot of records the runtime is already keeping.

## The heap profile has four views

The memory profiler samples allocations as they happen. `runtime.MemProfileRate` is 512 × 1024,
which means one sample for roughly every 512 KB allocated, and each sample remembers the stack that
allocated and the size. When the object is collected, the record learns that too. So **every
sample carries four numbers**, and `go tool pprof` shows one at a time:

| `-sample_index` | the question it answers |
|---|---|
| `inuse_space` | how many bytes are live now, and who allocated them |
| `inuse_objects` | how many objects are live now |
| `alloc_space` | how many bytes were allocated since the program started, garbage included |
| `alloc_objects` | how many allocations were made since the program started |

**A leak shows in `inuse`, and churn shows in `alloc`.** A program whose memory grows for a week
has its answer in the first view. A program that is slow because it makes and throws away millions
of small objects has its answer in the third and fourth, and its `inuse` view may be nearly empty.
`hits` is the second kind, which section 04 shows on two million lines. `heap` and `allocs` are the
same records with a different default view: `heap` opens on `inuse_space` and `allocs` on
`alloc_space`.

The heap view also comes with a lag that surprises people: **it describes the heap as of the most
recent garbage collection**, so an allocation made a moment ago is not in it yet. A program that
wants the heap as it is now calls `runtime.GC()` before writing the profile, which is what section 04
does.

## Two that are off, and why

`block` and `mutex` record waiting, and waiting happens constantly in a concurrent program: every
channel receive that finds nothing, every `Lock` that finds the mutex held. **Recording every one
would slow down exactly the programs that need the profile**, so both start switched off and record
nothing until the program asks. `runtime.SetBlockProfileRate(rate)` aims at one sampled event for
every `rate` nanoseconds spent blocked, and 1 means all of them; `runtime.SetMutexProfileFraction(n)`
reports one contention event in `n` on average. Section 05 shows the list of profiles a running
program serves, with both still at zero.

The goroutine profiles are different again. They cost nothing until somebody asks, and then they
are a census: every goroutine and where it is waiting. **A goroutine count that only goes up is the
signature of a leak**, and `goroutineleak` goes one step further and names the goroutines that can
never run again. Section 05 finds thirty of them in a program that had been running for about
sixteen seconds.
