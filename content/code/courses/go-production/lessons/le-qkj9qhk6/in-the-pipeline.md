---
title: The detector in the pipeline
version: 1
---

Sections 02 to 04 give the pipeline its three facts. A race passes every check except `-race`; the
detector reports only what the run exercised; and it costs several times the time and memory of a
plain build. **So it runs on every change, against tests written to make goroutines meet, and never
in the binary you ship.** Between the two sits one more place worth having, a staging run of a
race-enabled build, because real traffic takes paths no test thought of.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Four stages of a pipeline. One, pull request: go test -race -count=1 -cpu 1,4 on every change, before the merge. Two, push to main: the same tests on the merged result, and go build -race for the staging binary. Three, staging: the race-enabled pcount runs real traffic with GORACE log_path pointing at a directory, because real traffic takes paths no test took. Four, release: a plain go build, so what users run never carries the detector.\"><defs><marker id=\"l15pipe-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 pull request</text><rect x=\"20\" y=\"38\" width=\"160\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">go test -race</text><text x=\"100.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-count=1 -cpu 1,4 ./...</text><text x=\"100.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">with -race</text><text x=\"100.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every change, before</text><text x=\"100.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the merge</text><path d=\"M182 77 H194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15pipe-paper-dim)\"></path><text x=\"276.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2 push to main</text><rect x=\"196\" y=\"38\" width=\"160\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">go test -race ...</text><text x=\"276.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">go build -race</text><text x=\"276.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">with -race</text><text x=\"276.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the merged result, and</text><text x=\"276.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the staging binary</text><path d=\"M358 77 H370\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15pipe-paper-dim)\"></path><text x=\"452.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 staging</text><rect x=\"372\" y=\"38\" width=\"160\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"452.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">./pcount-race</text><text x=\"452.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GORACE=log_path=dir/race</text><text x=\"452.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">with -race</text><text x=\"452.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">real traffic takes paths</text><text x=\"452.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no test took</text><path d=\"M534 77 H546\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15pipe-paper-dim)\"></path><text x=\"628.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4 release</text><rect x=\"548\" y=\"38\" width=\"160\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"628.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">go build</text><text x=\"628.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-o pcount ./tools/pcount</text><text x=\"628.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">plain</text><text x=\"628.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what users run never</text><text x=\"628.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">carries the detector</text></svg>", "caption": "Where the detector runs: on every change, on the merged result, and in staging. The release build is the one place it does not."}
```

## The workflow

On GitHub Actions the job starts with the same two steps as lesson 6's format check, fetching the
code and installing the Go that `go.mod` names, and runs the detector's two commands after them. `.github/workflows/race.yml`:

```yaml
name: race
on:
  push:
    branches: [main]
  pull_request:
jobs:
  race:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - name: every test, with the race detector
        env:
          CGO_ENABLED: "1"
        run: go test -race -count=1 -cpu 1,4 ./...
      - name: pcount with the race detector, for the staging run
        env:
          CGO_ENABLED: "1"
        run: go build -race -o pcount-race ./tools/pcount
```

**This file was not run**: the lab has no GitHub. Its two `run:` lines were, with the same
environment, at the end of this section. The two actions are the ones lessons 6 and 9 use, at the same
versions. Each line of the file is there for a reason this lesson measured:

| line | why |
|---|---|
| `pull_request:` | a race found before the merge is a red check on one change; after the merge it is somebody else's flaky test |
| `push:` to `main` | the merged result, which no pull request tested exactly, gets one run of its own |
| `CGO_ENABLED: "1"` | section 04: a job that sets `CGO_ENABLED=0` for static release builds would otherwise refuse `-race` |
| `-count=1` | runs every test even when an identical run passed before, as the next transcript shows |
| `-cpu 1,4` | section 03: code that sizes itself from `GOMAXPROCS` takes its concurrent path whatever machine the job lands on |
| `go build -race` | the binary for the staging run, built by the same job that tested it |

The price of the step is the section 04 arithmetic: the whole test suite several times slower, plus
a second per package at exit, and `-cpu 1,4` runs every test twice. On a suite that takes a minute
plainly that is minutes, not seconds, which is a reason to give it a job of its own, running beside the
ordinary tests rather than after them. **What nobody should do is run it only nightly**:
a race found a day late arrives mixed with every change of that day.

## Why `-count=1`

`go test` caches the result of a package whose test binary and flags it has seen pass before. The
lab run below uses an empty build cache, so that the first command really runs:

```
ana@vm:~/race-hits$ go test -race ./...; go test -race ./...
ok  	example.com/hits	1.018s
ok  	example.com/hits/internal/tally	1.011s
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
ok  	example.com/hits	(cached)
ok  	example.com/hits/internal/tally	(cached)
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
```

The second command's lines say `(cached)`: nothing ran, and the old pass was printed again.
**`actions/setup-go` restores Go's build cache between runs by default**, its README says, and the
build cache is where these results live. Rerunning a job on a commit that already passed could then
answer from a run in which the race did not happen, which is a retry until green that nobody even
asked for. `go help test` calls `-count=1` "the idiomatic way to disable test caching explicitly".

## Four options for the runs that matter

The detector's run-time options come through `GORACE`, and `GORACE=help=1` makes a race-enabled
binary print all of them, with their current values, before it does its work. Ask `pcount-race`, the binary
built in section 02. **A binary does not change when its source does**, so this one still has the
race the fix removed:

```
ana@vm:~/race-hits$ GORACE=help=1 ./pcount-race < /dev/null 2>&1 | grep -A1 -E "^\s(halt_on_error|history_size|log_path|exitcode)$"
	halt_on_error
		- Exit after first reported error. (Current Value: false)
--
	history_size
		- Per-thread history size, controls how many extra previous memory accesses are remembered per thread. (Current Value: 0x0)
--
	log_path
		- Write logs to "log_path.pid". The special values are "stdout" and "stderr". If unspecified, defaults to "stderr". (Current Value: <null>)
--
	exitcode
		- Override the program exit status if the tool found an error (Current Value: 66)
```

Each answers a question a pipeline asks:

| option | default | what it is for |
|---|---|---|
| `halt_on_error` | off | stop at the first report: shorter output when you read it by hand, as section 02 did, and every later race in the same run hidden |
| `exitcode` | 66 | the status a run with a race exits with, so that a script can tell "a race" from "a failure" |
| `log_path` | standard error | write the reports to a file named `log_path.PID` instead, where a long-running process keeps them |
| `history_size` | 0 | how many extra earlier accesses each goroutine remembers, in the help text's words; leave it at 0 unless a long-running staging process needs a longer memory |

In a test run, keep `halt_on_error` off: a test binary that stops at the first report loses the
results of every test after it, and CI should show every race in one run. `exitcode` matters where
66 already means something else to a script. A test binary ignores it: one that finds a race fails
with status 1 even under `GORACE=exitcode=0`, because the `testing` package notices the report
itself and fails the test, with the `race detected during execution of test` line section 03 showed. The other two are for staging:

```
ana@vm:~/race-hits$ GORACE=exitcode=3 ./pcount-race < access.log > /dev/null 2>&1; echo $?
3
ana@vm:~/race-hits$ mkdir -p racelogs && GORACE=log_path=racelogs/race ./pcount-race < access.log; echo $?
20000 lines, 1h6m37.778s in total
66
ana@vm:~/race-hits$ ls racelogs && grep -c "WARNING: DATA RACE" racelogs/race.*
race.17789
4
```

`exitcode=3` replaced 66 with 3. With `log_path`, standard output still carried the program's
answer while the four reports went into `racelogs/race.17789`, named after the process's id, so
several processes can share one directory without overwriting each other. And the answer was right
this time, 20,000 lines and `1h6m37.778s`: **a run that happens to print the right number still had a
race, still wrote four reports and still exited 66.** The detector judges what happened in the run,
not whether the output came out correct.

## A staging run

A race-enabled build serving staging traffic sees what the tests could not: real inputs, real
concurrency, the code paths of section 03 that no test took. It runs several times slower and
with several times the memory, so it belongs on a staging machine or on a small share of
instances, never in the release. Here are the workflow's two `run:` lines on the fixed source, with
the job's `CGO_ENABLED`, and then the staging run of what they built:

```
ana@vm:~/race-hits$ CGO_ENABLED=1 go test -race -count=1 -cpu 1,4 ./...
ok  	example.com/hits	1.012s
ok  	example.com/hits/internal/tally	1.013s
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
ana@vm:~/race-hits$ CGO_ENABLED=1 go build -race -o pcount-race ./tools/pcount
ana@vm:~/race-hits$ mkdir -p racelogs && GORACE=log_path=racelogs/race ./pcount-race < access.log; echo $?; ls racelogs | wc -l
20000 lines, 1h6m37.778s in total
0
0
```

The tests ran twice each, once per value of `-cpu`, with nothing cached and nothing reported.
**A clean run is a run that leaves no file**: 20,000 lines, status 0, and `racelogs` empty. On a real
staging machine `log_path` would point at a directory the log shipper collects, and an alert on any
new file there is the whole monitoring a race build needs.

## What to do with a report

A report is not a guess. It is two accesses the detector watched happen, with their lines, and
nothing that ordered them. Three rules follow from that and from section 03.

**Never rerun the job until it goes green.** A green rerun is a run that did not take the racy path,
or did not take it with two goroutines, and section 03 showed how easily that happens; it says
nothing about the code. For the same reason the job should have no automatic retry.

Never mark the test as flaky and move on either. The test is the only thing in the pipeline that
made the goroutines meet, and disabling it removes the one witness.

**Fix it, or revert the change that brought it.** The report names both lines, as section 02 read
it, and `go-concurrency` lesson 16 has the four kinds of fix. Then the fixed code goes through the
same step, with `-count` and `-cpu`, and comes out clean.

A race in a dependency is still a race in your program, because it runs in your process. Upgrade
past it if a fix exists, report it upstream if not, and keep the test that found it.
