---
title: Recording a trace
version: 1
---

A profile and a trace look like two settings of one tool, and they are not. **Lesson 12's CPU
profile samples**: about a hundred times a second it asks which function is on a processor, and
the answer is a count. **An execution trace records events**: every time a goroutine is created,
starts running, blocks, wakes up or makes a system call, the runtime writes down what happened,
on which thread and processor, with a timestamp in nanoseconds and usually a stack. Nothing is
estimated, and the cost follows how much happens rather than how long the program runs.

That difference decides what each one can see. A goroutine parked on a mutex is on no processor,
so no sample ever lands on it. In a trace, the moment it parked and the moment it woke are both
events, and the gap between them is time you can measure.

## Three ways to start one

| how | what records | when it fits |
|---|---|---|
| `trace.Start(w)` and `trace.Stop()` | the program, between the two calls | a command you can add a flag to |
| `go test -trace=file` | one run of a package's tests | a test or benchmark that shows the problem |
| `import _ "net/http/pprof"` | `/debug/pprof/trace` on a running server | a long-lived process, asked over HTTP |

The third is the same tracer behind an HTTP handler, and `go doc runtime/trace` names it; this
lesson uses the first two, because neither needs a server.

## A program worth tracing

`hits` from lesson 1 counts on one goroutine, which gives a trace very little to say. The program
here counts the same log with several, the way `go-concurrency` lesson 7 built a worker pool: one
goroutine reads lines, a fixed number of workers parse them, and the workers' tallies are merged at
the end. It lives in a module of its own, `~/trace-hits`, made with `go mod init example.com/hits`,
with lesson 1's `tools/genlog/main.go` and `internal/tally/tally.go` copied in unchanged. The new
program is `cmd/pcount/main.go`:

```schooling-example
{
  "language": "go",
  "file": "cmd/pcount/main.go",
  "parts": [
    {
      "code": "// Command pcount counts an access log with several goroutines: one reads\n// the lines, the workers parse them, and their tallies are merged at the end.\npackage main\n\nimport (\n\t\"bufio\"\n\t\"context\"\n\t\"flag\"\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\t\"runtime/trace\"\n\t\"sync\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n\nconst batchSize = 1000\n",
      "note": "A second program in the same module as `hits`, under `cmd/`, using lesson 1's `tally` package for the parsing. `runtime/trace` is the only import this lesson adds."
    },
    {
      "code": "func main() {\n\tos.Exit(run())\n}\n\nfunc run() int {\n\tworkers := flag.Int(\"workers\", 4, \"how many goroutines parse lines\")\n\tshared := flag.Bool(\"shared\", false, \"share one summary behind one mutex, held for each line\")\n\tout := flag.String(\"trace\", \"\", \"write an execution trace to this file\")\n\tflag.Parse()\n\tif flag.NArg() != 1 {\n\t\tfmt.Fprintln(os.Stderr, \"usage: pcount [-workers N] [-shared] [-trace file] access.log\")\n\t\treturn 2\n\t}\n\tf, err := os.Open(flag.Arg(0))\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"pcount:\", err)\n\t\treturn 1\n\t}\n\tdefer f.Close()\n",
      "note": "Three flags: how many workers, a deliberately bad way of sharing the counts that section 04 needs, and **the file to write a trace to**. With no `-trace`, nothing is recorded and the program pays nothing for it."
    },
    {
      "code": "\tif *out != \"\" {\n\t\tstop, err := startTrace(*out)\n\t\tif err != nil {\n\t\t\tfmt.Fprintln(os.Stderr, \"pcount:\", err)\n\t\t\treturn 1\n\t\t}\n\t\tdefer func() {\n\t\t\tif err := stop(); err != nil {\n\t\t\t\tfmt.Fprintln(os.Stderr, \"pcount:\", err)\n\t\t\t}\n\t\t}()\n\t}\n\n\tstart := time.Now()\n\ts, bad, err := count(context.Background(), f, *workers, *shared)\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, \"pcount:\", err)\n\t\treturn 1\n\t}\n\tfmt.Printf(\"%d lines (%d bad), %d paths, %d workers, %v\\n\",\n\t\ts.Lines, bad, len(s.ByPath), *workers, time.Since(start).Round(time.Millisecond))\n\treturn 0\n}\n",
      "note": "**Tracing starts before the work and stops after it**, in a deferred call. `run` returns an exit code instead of calling `os.Exit` itself, because `os.Exit` skips deferred calls and the trace would never be finished."
    },
    {
      "code": "// startTrace starts the execution tracer writing to a new file, and returns\n// the function that stops it and closes the file.\nfunc startTrace(name string) (func() error, error) {\n\tf, err := os.Create(name)\n\tif err != nil {\n\t\treturn nil, err\n\t}\n\tif err := trace.Start(f); err != nil {\n\t\tf.Close()\n\t\treturn nil, err\n\t}\n\treturn func() error {\n\t\ttrace.Stop()\n\t\treturn f.Close()\n\t}, nil\n}\n",
      "note": "`trace.Start` takes any `io.Writer` and writes to it while the program runs. `trace.Stop` returns only after every write of the trace has completed, so the file is closed after it and not before."
    },
    {
      "code": "// count reads r on this goroutine and hands batches of lines to the workers.\nfunc count(ctx context.Context, r io.Reader, workers int, shared bool) (tally.Summary, int, error) {\n\tctx, task := trace.NewTask(ctx, \"count\")\n\tdefer task.End()\n",
      "note": "**`trace.NewTask` names one logical operation** and puts it in the context. Everything recorded with that context is attached to the task, and `task.End` marks when it finished."
    },
    {
      "code": "\tbatches := make(chan []string, workers)\n\tparts := make(chan part, workers)\n\tvar mu sync.Mutex\n\ttotal := part{s: newSummary()}\n",
      "note": "Two channels: batches of lines going out to the workers, and each worker's tally coming back. Both are buffered with one slot per worker."
    },
    {
      "code": "\tvar wg sync.WaitGroup\n\tfor range workers {\n\t\twg.Go(func() {\n\t\t\town := part{s: newSummary()}\n\t\t\tfor b := range batches {\n\t\t\t\ttrace.WithRegion(ctx, \"parse\", func() {\n\t\t\t\t\tfor _, line := range b {\n\t\t\t\t\t\tif shared {\n\t\t\t\t\t\t\tmu.Lock()\n\t\t\t\t\t\t\ttotal.add(line)\n\t\t\t\t\t\t\tmu.Unlock()\n\t\t\t\t\t\t} else {\n\t\t\t\t\t\t\town.add(line)\n\t\t\t\t\t\t}\n\t\t\t\t\t}\n\t\t\t\t})\n\t\t\t}\n\t\t\tparts <- own\n\t\t})\n\t}\n",
      "note": "The worker pool of `go-concurrency` lesson 7, with `WaitGroup.Go` (Go 1.25) doing the `Add` and the `Done`. **Each worker counts into its own `part`**, so no two goroutines touch the same map. `-shared` instead sends every line through one mutex, held while the line is parsed; `trace.WithRegion` marks each batch as a `parse` region."
    },
    {
      "code": "\tsc := bufio.NewScanner(r)\n\tb := make([]string, 0, batchSize)\n\tfor sc.Scan() {\n\t\tb = append(b, sc.Text())\n\t\tif len(b) == batchSize {\n\t\t\tbatches <- b\n\t\t\tb = make([]string, 0, batchSize)\n\t\t}\n\t}",
      "note": "The reader is this goroutine: it collects lines into batches of a thousand and sends each one. A send blocks when every slot of the channel is full, which is what happens when the workers fall behind."
    },
    {
      "code": "\tbatches <- b\n\tclose(batches)\n\twg.Wait()\n\tclose(parts)\n\n\ttrace.WithRegion(ctx, \"merge\", func() {\n\t\tfor p := range parts {\n\t\t\ttotal.merge(p)\n\t\t}\n\t})\n\ttrace.Logf(ctx, \"lines\", \"%d\", total.s.Lines)\n\treturn total.s, total.bad, sc.Err()\n}\n",
      "note": "The last, partly filled batch goes out, closing the channel ends every worker's `range`, and the tallies are merged once all of them have finished. `trace.Logf` leaves one message in the trace: the number of lines."
    },
    {
      "code": "// part is one worker's tally, and the lines it could not parse.\ntype part struct {\n\ts   tally.Summary\n\tbad int\n}\n\nfunc newSummary() tally.Summary {\n\treturn tally.Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}\n}\n\nfunc (p *part) add(line string) {\n\te, err := tally.Parse(line)\n\tif err != nil {\n\t\tp.bad++\n\t\treturn\n\t}\n\tp.s.Lines++\n\tp.s.ByStatus[e.Status]++\n\tp.s.ByPath[e.Path]++\n\tp.s.Total += e.Duration\n}\n\nfunc (p *part) merge(q part) {\n\tp.s.Lines += q.s.Lines\n\tp.bad += q.bad\n\tfor k, v := range q.s.ByStatus {\n\t\tp.s.ByStatus[k] += v\n\t}\n\tfor k, v := range q.s.ByPath {\n\t\tp.s.ByPath[k] += v\n\t}\n\tp.s.Total += q.s.Total\n}",
      "note": "`add` parses one line with `tally.Parse` and counts it, or counts it as bad. `merge` adds one tally into another. Neither knows about goroutines."
    }
  ]
}
```

Three files, and a log big enough to keep four goroutines busy for a second. `genlog` writes three
million lines with lesson 1's default seed, so your file has these bytes too:

```
ana@vm:~/trace-hits$ find . -name "*.go" | sort
./cmd/pcount/main.go
./internal/tally/tally.go
./tools/genlog/main.go
ana@vm:~/trace-hits$ go run ./tools/genlog -n 3000000 > big.log && stat -c "%s bytes  %n" big.log
137194124 bytes  big.log
ana@vm:~/trace-hits$ go build -o pcount ./cmd/pcount && ./pcount -h
Usage of ./pcount:
  -shared
    	share one summary behind one mutex, held for each line
  -trace string
    	write an execution trace to this file
  -workers int
    	how many goroutines parse lines (default 4)
```

## Recording, and what it costs

Each run below writes a trace beside the log:

```
ana@vm:~/trace-hits$ ./pcount -workers 4 -trace w4.trace big.log
3000000 lines (0 bad), 8 paths, 4 workers, 958ms
ana@vm:~/trace-hits$ ./pcount -workers 1 -trace w1.trace big.log
3000000 lines (0 bad), 8 paths, 1 workers, 1.357s
ana@vm:~/trace-hits$ stat -c "%s bytes  %n" w1.trace w4.trace
9453261 bytes  w1.trace
5257509 bytes  w4.trace
```

**A trace's size follows the events, not the work.** Both runs parsed the same three million
lines, and the one-worker run wrote 9,453,261 bytes against 5,257,509, because it ran longer and
the runtime kept producing events the whole time: the garbage collector alone is a stream of them,
as section 03 counts. That is between five and seven megabytes for every second of this program;
an hour at that rate would be some twenty gigabytes, which is the problem section 05 solves.

The cost in time is harder to see, and the honest way to show it is to try. Three pairs of runs,
each without a trace and then with one:

```
ana@vm:~/trace-hits$ for i in 1 2 3; do printf "plain   "; ./pcount big.log; printf "traced  "; ./pcount -trace x.trace big.log; done
plain   3000000 lines (0 bad), 8 paths, 4 workers, 1.021s
traced  3000000 lines (0 bad), 8 paths, 4 workers, 689ms
plain   3000000 lines (0 bad), 8 paths, 4 workers, 953ms
traced  3000000 lines (0 bad), 8 paths, 4 workers, 878ms
plain   3000000 lines (0 bad), 8 paths, 4 workers, 883ms
traced  3000000 lines (0 bad), 8 paths, 4 workers, 737ms
```

Every traced run was faster than the plain one before it, which nobody believes. **The noise
between two identical runs was larger than whatever tracing costs**, on a lab machine with four
CPUs shared with other work, and three pairs cannot separate the two. What can be said is that the
cost was not big enough to show through that noise. Measuring it properly takes many runs on a quiet
machine and a statistical comparison, the discipline `go-concurrency` lesson 29 applies to
benchmarks. **Every timing in this lesson came from that machine**, so read each one as a single
run.

## From a test

`go test -trace` needs nothing in the code. A test for `count` that checks both ways of sharing
against `tally.Count`, in `cmd/pcount/main_test.go`:

```go
package main

import (
	"context"
	"fmt"
	"reflect"
	"strings"
	"testing"

	"example.com/hits/internal/tally"
)

// TestCountAgrees checks that both ways of counting in parallel find what
// tally.Count finds on its own.
func TestCountAgrees(t *testing.T) {
	var log strings.Builder
	for i := range 20000 {
		fmt.Fprintf(&log, "2026-10-01T09:00:01Z GET /p%d %d %dms\n", i%7, 200+i%3, i%50)
	}
	want, err := tally.Count(strings.NewReader(log.String()))
	if err != nil {
		t.Fatal(err)
	}
	for _, shared := range []bool{false, true} {
		got, bad, err := count(context.Background(), strings.NewReader(log.String()), 4, shared)
		if err != nil || bad != 0 {
			t.Fatalf("shared=%t: %d bad lines, error %v", shared, bad, err)
		}
		if !reflect.DeepEqual(got, want) {
			t.Errorf("shared=%t: got %+v, want %+v", shared, got, want)
		}
	}
}
```

```
ana@vm:~/trace-hits$ go test -count=1 -trace=test.trace ./cmd/pcount
ok  	example.com/hits/cmd/pcount	0.027s
ana@vm:~/trace-hits$ stat -c "%s bytes  %n" test.trace
21214 bytes  test.trace
```

The file goes to the directory `go test` was run from, and it covers the whole test binary: both
calls to `count` are in it, each as its own `count` task. **A test is the cheapest place to trace
something that is already reproducible**, because the run is short, the input is fixed and nothing
in the program changes to record it.
