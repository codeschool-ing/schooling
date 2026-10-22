---
title: The flight recorder
version: 1
---

The incidents worth a trace are rarely the ones you can reproduce. A request that takes two
seconds once an hour will not happen while you watch, and **tracing a server for the hour before it
costs gigabytes**: section 02 measured five to seven megabytes a second for `pcount`. Writing it all
down in case something goes wrong is the wrong shape.

A flight recorder is the right one. **It keeps the most recent stretch of trace in memory, throws
away what is older, and writes nothing until the program asks.** When something slow happens, the
program asks, and the snapshot holds the seconds that led up to it. It arrived in Go 1.25 as
`trace.FlightRecorder`:

| | |
|---|---|
| `trace.NewFlightRecorder(cfg)` | makes one; `cfg` is a `trace.FlightRecorderConfig` |
| `cfg.MinAge` | keep at least this much recent trace; zero means a few seconds |
| `cfg.MaxBytes` | keep at most about this many bytes; it wins over `MinAge` |
| `fr.Start()`, `fr.Stop()` | begin and end recording into the window |
| `fr.WriteTo(w)` | copy the window to `w`, and return how many bytes |
| `fr.Enabled()` | whether it is recording |

`go doc runtime/trace.FlightRecorder` adds the limits: only one flight recorder may be active in a
program, one `WriteTo` may run at a time, and both settings are hints rather than guarantees. It can
run at the same time as a `trace.Start`.

## A program that catches its own slow batch

The program counts the log on one goroutine in batches of a thousand lines and times each batch,
as a server would time a request. A second goroutine shares the counts and, every half second,
holds their lock far too long. Nothing in the counting loop knows that. `cmd/flight/main.go`:

```schooling-example
{
  "language": "go",
  "file": "cmd/flight/main.go",
  "parts": [
    {
      "code": "// Command flight counts an access log in batches with the flight recorder\n// running, and writes out the last second of trace when a batch is slow.\npackage main\n\nimport (\n\t\"bufio\"\n\t\"context\"\n\t\"flag\"\n\t\"fmt\"\n\t\"os\"\n\t\"runtime/trace\"\n\t\"sync\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n\nconst batchSize = 1000\n",
      "note": "A third program in the module, beside `pcount`. It counts in batches of a thousand lines on one goroutine, and treats each batch the way a server treats a request: it has a duration, and a slow one is worth explaining."
    },
    {
      "code": "func main() {\n\tos.Exit(run())\n}\n\nfunc run() int {\n\tslow := flag.Duration(\"slow\", 50*time.Millisecond, \"a batch slower than this writes a snapshot\")\n\tout := flag.String(\"o\", \"slow.trace\", \"the file the snapshot goes to\")\n\tflag.Parse()\n\tif flag.NArg() != 1 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: flight [-slow d] [-o file] access.log\")\n\t\treturn 2\n\t}\n\tf, err := os.Open(flag.Arg(0))\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\treturn 1\n\t}\n\tdefer f.Close()\n",
      "note": "`-slow` is the threshold: **a batch that takes longer than this is the incident**. `-o` is where the snapshot goes."
    },
    {
      "code": "\tfr := trace.NewFlightRecorder(trace.FlightRecorderConfig{\n\t\tMinAge:   time.Second,\n\t\tMaxBytes: 16 << 20,\n\t})\n\tif err := fr.Start(); err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\treturn 1\n\t}\n\tdefer fr.Stop()\n",
      "note": "**The flight recorder keeps a moving window of trace in memory and writes nothing until asked.** `MinAge` asks it to keep at least the last second; `MaxBytes` caps the window at 16 MiB and wins when the two disagree. Both are hints, as `go doc` says."
    },
    {
      "code": "\tvar mu sync.Mutex\n\ts := tally.Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}\n\tdone := make(chan struct{})\n\tdefer close(done)\n\tgo publish(&mu, &s, done)\n",
      "note": "The counts are shared with a second goroutine, `publish`, through a mutex. That goroutine is the cause of the slow batches, and nothing in the counting loop says so."
    },
    {
      "code": "\tctx := context.Background()\n\tvar batches int\n\tvar worst time.Duration\n\tsaved := false\n\tbatch := func(b []string) error {\n\t\tstart := time.Now()\n\t\ttrace.WithRegion(ctx, \"batch\", func() {\n\t\t\tmu.Lock()\n\t\t\tdefer mu.Unlock()\n\t\t\tfor _, line := range b {\n\t\t\t\tif e, err := tally.Parse(line); err == nil {\n\t\t\t\t\ts.Lines++\n\t\t\t\t\ts.ByPath[e.Path]++\n\t\t\t\t}\n\t\t\t}\n\t\t})",
      "note": "One batch: take the lock, parse a thousand lines, release it, inside a `batch` region so the trace shows where each one starts and ends. The duration includes the time spent waiting for the lock."
    },
    {
      "code": "\t\td := time.Since(start)\n\t\tbatches++\n\t\tworst = max(worst, d)\n\t\tif d <= *slow || saved {\n\t\t\treturn nil\n\t\t}\n\t\tsaved = true\n\t\ttrace.Logf(ctx, \"slow\", \"batch %d took %v\", batches, d)\n\t\tn, err := snapshot(fr, *out)\n\t\tif err != nil {\n\t\t\treturn err\n\t\t}\n\t\tfmt.Printf(\"batch %d took %v: wrote %d bytes to %s\\n\",\n\t\t\tbatches, d.Round(time.Millisecond), n, *out)\n\t\treturn nil\n\t}\n",
      "note": "**The first slow batch takes the snapshot**, and only the first: `WriteTo` copies the window out, and one file is enough to explain the incident. `trace.Logf` goes in just before, so the snapshot itself says which batch it was taken for."
    },
    {
      "code": "\tsc := bufio.NewScanner(f)\n\tb := make([]string, 0, batchSize)\n\tfor sc.Scan() {\n\t\tb = append(b, sc.Text())\n\t\tif len(b) == batchSize {\n\t\t\tif err := batch(b); err != nil {\n\t\t\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\t\t\treturn 1\n\t\t\t}\n\t\t\tb = b[:0]\n\t\t}\n\t}\n\tif err := batch(b); err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\treturn 1\n\t}\n\tif err := sc.Err(); err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"flight:\", err)\n\t\treturn 1\n\t}\n\tfmt.Printf(\"%d lines in %d batches, the slowest %v\\n\",\n\t\ts.Lines, batches, worst.Round(time.Millisecond))\n\treturn 0\n}\n",
      "note": "The reading loop: collect a thousand lines, run them as a batch, start again. The last, shorter batch runs after the loop."
    },
    {
      "code": "// snapshot writes the flight recorder's window to a new file.\nfunc snapshot(fr *trace.FlightRecorder, name string) (int64, error) {\n\tf, err := os.Create(name)\n\tif err != nil {\n\t\treturn 0, err\n\t}\n\tn, err := fr.WriteTo(f)\n\tif cerr := f.Close(); err == nil {\n\t\terr = cerr\n\t}\n\treturn n, err\n}\n",
      "note": "`WriteTo` returns how many bytes it wrote. An error from `Close` is kept too, since a snapshot cut short is a file `go tool trace` cannot read."
    },
    {
      "code": "// publish takes the lock every half second to read the top paths.\n// The sleep stands for a slow write of them, made while still holding it.\nfunc publish(mu *sync.Mutex, s *tally.Summary, done <-chan struct{}) {\n\ttick := time.NewTicker(500 * time.Millisecond)\n\tdefer tick.Stop()\n\tfor {\n\t\tselect {\n\t\tcase <-done:\n\t\t\treturn\n\t\tcase <-tick.C:\n\t\t\tmu.Lock()\n\t\t\t_ = tally.Top(*s, 3)\n\t\t\ttime.Sleep(100 * time.Millisecond)\n\t\t\tmu.Unlock()\n\t\t}\n\t}\n}",
      "note": "**The culprit**, written on purpose: every 500 ms it holds the lock for 100 ms. A batch that needs the lock in that window waits for it, and its duration says only that it was slow."
    }
  ]
}
```

Built and run with the default threshold of 50 ms:

```
ana@vm:~/trace-hits$ go build -o flight ./cmd/flight && ./flight big.log
batch 1594 took 100ms: wrote 1606654 bytes to slow.trace
3000000 lines in 3001 batches, the slowest 101ms
```

A batch normally takes well under a millisecond, and **batch 1,594 took 100ms**, which is the 100ms
`publish` holds the lock for. The program noticed, wrote a snapshot of 1,606,654 bytes and carried
on to the end. How far back the snapshot reaches is the configuration's business: at least the last
second, as `MinAge` asked, and never much more than 16 MiB.

## Reading the snapshot

The snapshot is an ordinary trace file, and every tool in this lesson reads it. The message
`trace.Logf` left just before taking it is inside, which is how you tell one snapshot from another
a week later:

```
ana@vm:~/trace-hits$ go tool trace -d=parsed slow.trace | grep 'Category="slow"'
M=20599 P=0 G=1 Log Time=900271165120 Task=0 Category="slow" Message="batch 1594 took 100.38373ms"
```

And the question the batch's duration could not answer, what it was doing for those 100ms:

```
ana@vm:~/trace-hits$ go tool trace -pprof=sync slow.trace > slow.pprof && go tool pprof -top -focus=Mutex slow.pprof
Main binary filename not available.
Type: delay
Active filters:
   focus=Mutex
Showing nodes accounting for 100.89ms, 7.78% of 1296.33ms total
      flat  flat%   sum%        cum   cum%
  100.89ms  7.78%  7.78%   100.89ms  7.78%  sync.(*Mutex).Lock
         0     0%  7.78%   100.16ms  7.73%  main.main
         0     0%  7.78%     0.74ms 0.057%  main.publish
         0     0%  7.78%   100.16ms  7.73%  main.run
         0     0%  7.78%   100.16ms  7.73%  main.run.func1
         0     0%  7.78%   100.16ms  7.73%  main.run.func1.1
         0     0%  7.78%   100.16ms  7.73%  runtime/trace.WithRegion
```

**100.89ms blocked in `sync.(*Mutex).Lock`**, which is the whole of the slow batch. The batch was
not slow at parsing; it was waiting for a lock, and in this program only one other goroutine takes
that lock. In `go tool trace slow.trace`, the `batch` regions on the User-defined regions page put
that one 100ms batch beside three thousand fast ones. The cause was found without anybody
reproducing the incident.

A threshold above the stall takes no snapshot at all, which is the other half of the contract:

```
ana@vm:~/trace-hits$ ./flight -slow 200ms -o none.trace big.log; ls none.trace
3000000 lines in 3001 batches, the slowest 101ms
ls: cannot access 'none.trace': No such file or directory
```

## Using it in a real program

**The threshold is a statement about what counts as an incident**, and it has to sit above the
normal noise. Set too low, it catches whatever else slowed a batch down, a busy machine for one, and
the snapshot then explains that instead. In a server
the usual trigger is a request slower than some multiple of its normal latency, or an error that
should not happen. Two more choices follow from the API:

- **Take one snapshot per incident, then wait.** `flight` stops after the first. A server would
  allow one every few minutes; `WriteTo` refuses to run twice at once anyway, and a hundred
  snapshots of the same stall explain nothing more than one.
- **The recorder costs what tracing costs, all the time.** It keeps the runtime's tracer running
  from `Start` to `Stop`, and only the writing out waits for `WriteTo`. Section 02 could not see
  that cost through the noise of a busy machine; on the machine that matters to you, measure it
  before leaving it on.
