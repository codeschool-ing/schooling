---
title: A profile from a running process
version: 1
---

The programs that most need a profile are the ones you cannot stop to add flags to: **a service
that has been running for a week and has started using more memory, or more processor, than it did
on Monday**. Restarting it with profiling turned on throws away the state you wanted to look at.
`net/http/pprof` is the answer the standard library gives. A program that imports it serves every
profile of section 02 over HTTP, on demand, while it carries on working, and `go tool pprof` can
read a profile straight from the address.

This course does not assume you have written a web server, and this section does not need one beyond
a few lines. `net/http` can listen on a network address and answer requests; **a handler is a
function that answers one, and a mux is the table that says which handler answers which path**.
`http.ListenAndServe(addr, nil)` listens on `addr` and uses the package's default mux,
`http.DefaultServeMux`. That is all the server code below.

## A service with a defect

`profserve` stands in for a service. It counts the big log of section 04 over and over, as a server
handles one request after another, and it gives each count a deadline. In `~/prof`, save it as
`tools/profserve/main.go`:

```schooling-example
{
  "language": "go",
  "file": "tools/profserve/main.go",
  "parts": [
    {
      "code": "// Command profserve counts a log again and again, the way a service that\n// runs for weeks does its work, and serves its own profiles on localhost.\npackage main\n\nimport (\n\t\"errors\"\n\t\"flag\"\n\t\"log\"\n\t\"net/http\"\n\t_ \"net/http/pprof\"\n\t\"os\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "**Importing `net/http/pprof` for its side effect registers handlers under `/debug/pprof/`** on `http.DefaultServeMux`, the server's default table of routes. The blank name `_` says the program uses nothing else from the package."
    },
    {
      "code": "func main() {\n\taddr := flag.String(\"pprof\", \"127.0.0.1:6060\", \"where to serve the profiles\")\n\ttimeout := flag.Duration(\"timeout\", 2*time.Second, \"how long one count may take\")\n\tflag.Parse()\n\tlog.SetFlags(0)\n\tif flag.NArg() != 1 {\n\t\tlog.Fatal(\"usage: profserve [-pprof addr] [-timeout d] file\")\n\t}\n",
      "note": "Two flags: where to serve the profiles, and how long one count may take. **The default address is `127.0.0.1`**, the machine's own loopback interface, which nothing on the network can reach."
    },
    {
      "code": "\tgo func() {\n\t\tlog.Println(http.ListenAndServe(*addr, nil))\n\t}()\n",
      "note": "`http.ListenAndServe` with a `nil` handler serves `DefaultServeMux`, where the import put the profiles. It never returns while the server runs, so it gets a goroutine of its own and the program's real work carries on in `main`."
    },
    {
      "code": "\tfor round := 1; ; round++ {\n\t\ts, err := countBefore(flag.Arg(0), *timeout)\n\t\tif err != nil {\n\t\t\tlog.Printf(\"round %d: %v\", round, err)\n\t\t\tcontinue\n\t\t}\n\t\tlog.Printf(\"round %d: %d lines\", round, s.Lines)\n\t}\n}\n",
      "note": "The work: count the file, report, and start again, forever. A service handling requests looks like this to a profiler: the same code running over and over, for as long as anybody watches."
    },
    {
      "code": "type result struct {\n\ts   tally.Summary\n\terr error\n}\n\n// countBefore counts the file at path, and gives up after d.\nfunc countBefore(path string, d time.Duration) (tally.Summary, error) {\n\tdone := make(chan result)\n\tgo func() {\n\t\ts, err := countFile(path)\n\t\tdone <- result{s, err}\n\t}()\n\tselect {\n\tcase r := <-done:\n\t\treturn r.s, r.err\n\tcase <-time.After(d):\n\t\treturn tally.Summary{}, errors.New(\"timed out\")\n\t}\n}\n",
      "note": "**The defect is here.** The count runs in a goroutine so that `select` can stop waiting after `d`. When the timer wins, `countBefore` returns and nobody is left to receive from `done`: the goroutine finishes counting, reaches `done <- result{s, err}` and waits there for ever."
    },
    {
      "code": "func countFile(path string) (tally.Summary, error) {\n\tf, err := os.Open(path)\n\tif err != nil {\n\t\treturn tally.Summary{}, err\n\t}\n\tdefer f.Close()\n\treturn tally.Count(f)\n}",
      "note": "Open and count, closing the file whatever happens."
    }
  ]
}
```

**`127.0.0.1` is the loopback address**: a server listening there accepts connections from programs
on the same machine and from nowhere else. Two terminals, then. In the first, Ana starts the service
with a deadline shorter than a count of 91 MB takes on this machine, which is the situation in
which the defect shows:

```
ana@vm:~/prof$ ./profserve -timeout 500ms big.log
round 1: timed out
round 2: timed out
round 3: timed out
round 4: timed out
round 5: timed out
round 6: timed out
```

Every round gives up after half a second, the program goes on to the next one, and nothing in its
output looks wrong. The rest of this section happens in the second terminal.

## What it serves

`/debug/pprof/` is an HTML page listing the profiles with a count beside each. `curl` fetches it, and
the `grep` and `sed` reduce the table to its rows:

```
ana@vm:~/prof$ curl -s http://127.0.0.1:6060/debug/pprof/ | grep "<tr>" | sed "s/<[^>]*>/ /g"
  9   allocs   
  0   block   
  0   cmdline   
  11   goroutine   
  0   goroutineleak   
  9   heap   
  0   mutex   
  0   profile   
  0   symbol   
  10   threadcreate   
  0   trace   
```

**These are section 02's profiles, by the same names**, plus four the package adds: `profile` is the
CPU profile, `trace` is the execution trace of lesson 14, and `cmdline` and `symbol` are helpers for
the tools. The counts are what each profile holds right now. `block` and `mutex` are at 0, as section
02 said they would be in a program that never called `SetBlockProfileRate` or
`SetMutexProfileFraction`. `goroutine` says 11, three seconds after the start; keep that number in
mind.

## A CPU profile over the network

The CPU profile is taken on request: `?seconds=5` asks the process to sample itself for five seconds
and send the result. `go tool pprof` accepts the address wherever it accepts a file:

```
ana@vm:~/prof$ go tool pprof -top "http://127.0.0.1:6060/debug/pprof/profile?seconds=5" | sed /^Time:/d | head -12
Fetching profile over HTTP from http://127.0.0.1:6060/debug/pprof/profile?seconds=5
Saved profile in /home/ana/pprof/pprof.profserve.samples.cpu.001.pb.gz
File: profserve
Build ID: 5f0f43423e37f4038fb1f9893cbbd59c5978ff16
Type: cpu
Duration: 5s, Total samples = 7.52s (150.30%)
Showing nodes accounting for 6.85s, 91.09% of 7.52s total
Dropped 118 nodes (cum <= 0.04s)
      flat  flat%   sum%        cum   cum%
     1.21s 16.09% 16.09%      2.76s 36.70%  strings.Fields
     0.72s  9.57% 25.66%      0.72s  9.57%  runtime.asyncPreempt
     0.28s  3.72% 29.39%      0.31s  4.12%  runtime.lock2
     0.23s  3.06% 32.45%      0.29s  3.86%  runtime.unlock2
     0.22s  2.93% 35.37%      0.22s  2.93%  internal/runtime/syscall/linux.Syscall6
```

The command waited five seconds for the profile, then **saved a copy under `~/pprof`**, so it can be
read again after the process has gone, and printed the report. 7.52 seconds of samples in 5 seconds
of wall time means one and a half processors busy on average: the counts overlap, because each round
starts a new one before the old one has finished. And the top row is the one sections 03 and 04
found, `strings.Fields`, at 36.70% counting what it calls. **Three ways of taking a profile, of two
different programs, agree on where the time goes**, which is what makes the finding worth acting on in
lesson 13.

## The goroutines

The goroutine profile with `?debug=1` is text rather than the binary format: each distinct stack
once, with the number of goroutines sitting on it. Thirteen seconds later:

```
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=1" | head -10
goroutine profile: total 37
30 @ 0x48c1ea 0x418d1c 0x418917 0x682af2 0x4930c1
#	0x682af1	main.countBefore.func1+0x51	/home/ana/prof/tools/profserve/main.go:50

1 @ 0x448bf1 0x48afbd 0x666211 0x665ee5 0x662e49 0x67cd94 0x67d7dc 0x643329 0x644eaf 0x64b12e 0x64199c 0x4930c1
#	0x666210	runtime/pprof.writeRuntimeProfile+0xb0	/usr/local/go/src/runtime/pprof/pprof.go:848
#	0x665ee4	runtime/pprof.writeGoroutine+0x44	/usr/local/go/src/runtime/pprof/pprof.go:781
#	0x662e48	runtime/pprof.(*Profile).WriteTo+0x148	/usr/local/go/src/runtime/pprof/pprof.go:405
#	0x67cd93	net/http/pprof.handler.ServeHTTP+0x553	/usr/local/go/src/net/http/pprof/pprof.go:272
#	0x67d7db	net/http/pprof.Index+0xdb		/usr/local/go/src/net/http/pprof/pprof.go:391
```

**37 goroutines, and 30 of them are on exactly the same line**, `main.go:50`, which is
`done <- result{s, err}` in `countBefore`. The second record is the goroutine answering this very
request. `?debug=2` prints every goroutine separately in the format of a panic, with the state each
one is waiting in, and the state confirms it:

```
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=2" | grep -A2 "chan send" | head -3
goroutine 9 [chan send]:
main.countBefore.func1()
	/home/ana/prof/tools/profserve/main.go:50 +0x52
```

**`chan send`: a goroutine trying to hand its result to a receiver who has already left.** Each round
that timed out left one behind, and each one holds a goroutine's stack and the summary it computed,
for as long as the process lives. The count went from 11 to 37 in thirteen seconds and does not come
down. In a service that runs for a week, that is the memory growth somebody eventually notices,
with no error anywhere in the logs.

`goroutineleak` says the same thing without the reasoning:

```
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutineleak?debug=1" | head -3
goroutineleak profile: total 30
30 @ 0x48c1ea 0x418d1c 0x418917 0x682af2 0x4930c1
#	0x682af1	main.countBefore.func1+0x51	/home/ana/prof/tools/profserve/main.go:50
```

To build it, the runtime runs a garbage collection that also asks, for every blocked goroutine,
whether any goroutine that might still run can reach the channel or lock it is blocked on. The
channel `done` is referenced by nothing but the goroutine waiting on it, so nothing can ever receive
from it, and **those 30 goroutines are reported as leaked rather than merely waiting**. The check
has a limit worth knowing: a goroutine blocked on a channel that something reachable still points
to, a global variable for instance, is not reported, because the runtime cannot tell that nobody will
use it.

## The fix

The goroutine needs somewhere to put its result that does not need a receiver. **A channel with a
buffer of one accepts one send without waiting**, so the goroutine can always finish, and the channel
becomes garbage once both sides are done with it. One edit, the service stopped in the first
terminal, rebuilt and started again with the same command:

```
ana@vm:~/prof$ sed -i 's/done := make(chan result)/done := make(chan result, 1)/' tools/profserve/main.go
ana@vm:~/prof$ go build -o profserve ./tools/profserve
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutineleak?debug=1" | head -3
goroutineleak profile: total 0
ana@vm:~/prof$ curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=1" | head -1
goroutine profile: total 15
```

**No leaked goroutines after twelve seconds.** The 15 goroutines are the server's own and the counts
still in flight: each round still times out and starts a new count, but every count now finishes,
sends into the buffer and returns.

## Keep it off the network

The handlers `net/http/pprof` registers have no authentication, and what they serve is not harmless.
The goroutine profile shows the source paths and the shape of the code, and `cmdline` shows
the command line with whatever secrets were passed on it. A request for `profile?seconds=60` or a
trace keeps a processor busy for as long as the caller asks. **An endpoint like this must never be
reachable from the internet.** Three habits keep it that way:

- **Listen on `127.0.0.1`**, as `profserve` does, and reach it from elsewhere through an SSH tunnel
  such as `ssh -L 6060:127.0.0.1:6060 server`, which makes the remote port appear on your own
  machine.
- **Serve it on its own port, never on the public one.** The import registers its handlers on
  `http.DefaultServeMux`. A program that also serves its public traffic from `DefaultServeMux`,
  which is what `http.ListenAndServe(":8080", nil)` does, has just published `/debug/pprof/` to
  everybody who can reach port 8080. The safe shape keeps them apart: the public server on a mux of
  its own, made with `http.NewServeMux()`, and the default mux, with the profiles on it, on a
  loopback address.
- **Make the address a flag**, as `-pprof` is here, so an operator can move it to a port that only
  the internal network reaches without rebuilding the program.
