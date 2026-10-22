---
title: Checking every platform from one machine
version: 1
---

`go build` on this machine compiles the files a Linux build on `amd64` selects, with no tags, and
**nothing else**. Every other combination of system, processor and tags is a different program,
made of a different set of files, and none of them is checked by building here. `hits` now has
three per-system files and a tagged one, so it is already several programs, and section 03's
`go list` can say exactly which.

## One build is one column

The same `go list` for four targets, and once more with the tag:

```
ana@vm:~/tags$ for t in linux/amd64 darwin/arm64 windows/amd64 freebsd/amd64; do echo "$t: $(GOOS=${t%/*} GOARCH=${t#*/} go list -f '{{.GoFiles}}' .)"; done
linux/amd64: [main.go progress.go progress_unix.go]
darwin/arm64: [main.go progress.go progress_darwin.go]
windows/amd64: [main.go progress.go progress_other.go]
freebsd/amd64: [main.go progress.go progress_unix.go]
ana@vm:~/tags$ GOOS=windows go list -tags debug -f '{{.GoFiles}}' .
[debug.go main.go progress.go progress_other.go]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 346\" role=\"img\" aria-label=\"A table of six files of package main against five builds. main.go and progress.go are compiled by every build. progress_unix.go is compiled for linux/amd64 and freebsd/amd64, progress_darwin.go only for darwin/arm64, and progress_other.go for windows/amd64, with and without the debug tag. debug.go is compiled only by the windows/amd64 build with -tags debug. Each build without tags compiles three files, and the tagged build four.\"><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">which files each build compiles, as go list reported them</text><text x=\"250.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">linux/amd64</text><text x=\"250.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no tags</text><text x=\"350.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">darwin/arm64</text><text x=\"350.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no tags</text><text x=\"450.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">windows/amd64</text><text x=\"450.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no tags</text><text x=\"550.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">freebsd/amd64</text><text x=\"550.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no tags</text><text x=\"650.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">windows/amd64</text><text x=\"650.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">-tags debug</text><path d=\"M600 36 V282\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\" fill=\"none\"></path><rect x=\"20\" y=\"92\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"92\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.go</text><rect x=\"228.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"328.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"428.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"528.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"628.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"122\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"122\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">progress.go</text><rect x=\"228.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"328.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"428.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"528.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"628.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"152\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"152\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">progress_unix.go</text><rect x=\"228.0\" y=\"157.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M342.0 165.0 H358.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M442.0 165.0 H458.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"528.0\" y=\"157.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M642.0 165.0 H658.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"182\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"182\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">progress_darwin.go</text><path d=\"M242.0 195.0 H258.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"328.0\" y=\"187.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M442.0 195.0 H458.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M542.0 195.0 H558.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M642.0 195.0 H658.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"212\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"212\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"225.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">progress_other.go</text><path d=\"M242.0 225.0 H258.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M342.0 225.0 H358.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"428.0\" y=\"217.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M542.0 225.0 H558.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"628.0\" y=\"217.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"242\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"242\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">debug.go</text><path d=\"M242.0 255.0 H258.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M342.0 255.0 H358.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M442.0 255.0 H458.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M542.0 255.0 H558.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"628.0\" y=\"247.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 files</text><text x=\"350.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 files</text><text x=\"450.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 files</text><text x=\"550.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 files</text><text x=\"650.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 files</text><rect x=\"32\" y=\"318\" width=\"30\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">compiled by that build</text><path d=\"M232 326 H248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"258\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">left out by a constraint</text></svg>", "caption": "One build is one column. The program as a whole is every row, and no single build compiles all of it."}
```

**No build compiles all six files.** Each of the four targets without tags compiled three of them,
and the tagged Windows build four. FreeBSD and Linux took the same files, through
`unix && !darwin`. A mistake in `progress_other.go` cannot appear in the first column, and one in
`debug.go` can appear only in the last, so a Linux developer who builds and tests with no tags has
checked one column of five.

`GOOS` and `GOARCH` set for one command make `go list`, `go vet` and `go build` work as they would
on that machine, without building anything that has to run here. That turns every column into a
command:

```
ana@vm:~/tags$ for t in linux/amd64 linux/arm64 darwin/arm64 windows/amd64 freebsd/amd64; do GOOS=${t%/*} GOARCH=${t#*/} go vet ./... && echo "ok  $t"; done
ok  linux/amd64
ok  linux/arm64
ok  darwin/arm64
ok  windows/amd64
ok  freebsd/amd64
```

Five targets, all clean. **`go vet` is the better tool for this than `go build`**: it type-checks
every package together with its test files, which `go build` skips, and runs vet's checks on them,
and it never has to link a binary. Section 02's Windows failure would have been caught by the
`windows/amd64` line of this loop.

## The loop that is not enough

The debug build of section 04 would be more useful if it also said how to ask for progress, which
depends on the system. The hint goes beside the signals it describes, so that the two cannot drift
apart. A first attempt changes `progress_unix.go`, this machine's file:

```go
//go:build unix && !darwin

package main

import (
	"os"
	"syscall"
)

// On Linux and the other Unix systems, kill -USR1 asks for progress.
var progressSignals = []os.Signal{syscall.SIGUSR1}

const progressHint = "kill -USR1 prints progress"
```

and makes `debug.go` print it at start-up, with the process number that `kill` needs:

```go
//go:build debug

package main

import (
	"fmt"
	"io"
	"os"
)

func init() {
	debugf = func(w io.Writer, format string, a ...any) {
		fmt.Fprintf(w, "hits: debug: "+format+"\n", a...)
	}
	debugf(os.Stderr, "pid %d: %s", os.Getpid(), progressHint)
}
```

On this machine, the debug build works:

```
ana@vm:~/tags$ go build -tags debug -o hits-debug . && ./hits-debug top -n 1 access.log
hits: debug: 20000 lines, 914867 bytes in 5.420602ms
path    requests
/login  2576
```

And the loop over targets, run again:

```
ana@vm:~/tags$ for t in linux/amd64 linux/arm64 darwin/arm64 windows/amd64 freebsd/amd64; do GOOS=${t%/*} GOARCH=${t#*/} go vet ./... && echo "ok  $t"; done
ok  linux/amd64
ok  linux/arm64
ok  darwin/arm64
ok  windows/amd64
ok  freebsd/amd64
```

**Five targets, all clean, and the code is broken on two of them.** `progressHint` exists only in
`progress_unix.go`, so a debug build for macOS or Windows cannot compile. The loop did not see it
because the only file that uses `progressHint` is `debug.go`, and the loop ran without the tag. It
checked five columns of a table that has fifteen.

## Every target with every tag

A loop over both, as a script that can sit in a repository and run in CI, `check.sh`:

```schooling-example
{
  "language": "sh",
  "file": "check.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# check.sh vets every package for each target, with each set of tags.\nset -u",
      "note": "A POSIX shell script, run with `sh check.sh`. **`set -u` stops it at a variable used without a value**; `set -e` is left out on purpose, because a failure here is something to report and carry on from, not a reason to stop."
    },
    {
      "code": "targets=\"linux/amd64 linux/arm64 darwin/arm64 windows/amd64 freebsd/amd64\"\nstatus=0",
      "note": "The targets, spelled as `go tool dist list` spells them. FreeBSD is there although nobody ships `hits` to it, because it is the one Unix that takes `progress_unix.go` without being Linux."
    },
    {
      "code": "for t in $targets; do\n\tfor tags in \"\" debug integration; do",
      "note": "**Every target with every set of tags**: none, `debug` and `integration`, the three ways this module gets built. `${t%/*}` and `${t#*/}` split `linux/amd64` into its two halves."
    },
    {
      "code": "\t\tif out=$(GOOS=${t%/*} GOARCH=${t#*/} go vet -tags \"$tags\" ./... 2>&1); then\n\t\t\techo \"ok    $t -tags '$tags'\"\n\t\telse\n\t\t\techo \"FAIL  $t -tags '$tags'\"\n\t\t\techo \"$out\" | sed 's/^/      /'\n\t\t\tstatus=1\n\t\tfi\n\tdone\ndone",
      "note": "`go vet` type-checks every package and its test files, which `go build` skips, and runs vet's checks on them; it never links a binary. Its output is kept in `out` and printed only on failure, indented under the line that names the target."
    },
    {
      "code": "exit $status",
      "note": "The exit status is 1 if any combination failed, so a CI step running `sh check.sh` fails with it."
    }
  ]
}
```

Run:

```
ana@vm:~/tags$ sh check.sh; echo $?
ok    linux/amd64 -tags ''
ok    linux/amd64 -tags 'debug'
ok    linux/amd64 -tags 'integration'
ok    linux/arm64 -tags ''
ok    linux/arm64 -tags 'debug'
ok    linux/arm64 -tags 'integration'
ok    darwin/arm64 -tags ''
FAIL  darwin/arm64 -tags 'debug'
      # example.com/hits
      # [example.com/hits]
      vet: ./debug.go:15:47: undefined: progressHint
ok    darwin/arm64 -tags 'integration'
ok    windows/amd64 -tags ''
FAIL  windows/amd64 -tags 'debug'
      # example.com/hits
      # [example.com/hits]
      vet: ./debug.go:15:47: undefined: progressHint
ok    windows/amd64 -tags 'integration'
ok    freebsd/amd64 -tags ''
ok    freebsd/amd64 -tags 'debug'
ok    freebsd/amd64 -tags 'integration'
1
```

**Thirteen combinations passed and two failed**, with vet's message under each: macOS and Windows,
with `-tags debug`. The exit status is 1. The fix is the line the other two per-system files are
missing. `progress_darwin.go`:

```go
package main

import (
	"os"
	"syscall"
)

// On macOS, Ctrl-T in the terminal sends SIGINFO, and kill -USR1 works too.
var progressSignals = []os.Signal{syscall.SIGINFO, syscall.SIGUSR1}

const progressHint = "Ctrl-T prints progress"
```

and `progress_other.go`:

```go
//go:build !unix

package main

import "os"

// Windows and the other systems have no signal for this.
var progressSignals []os.Signal

const progressHint = "no signal prints progress on this system"
```

```
ana@vm:~/tags$ sh check.sh > /dev/null && echo "all 15 passed"
all 15 passed
```

Fifteen runs is five targets times three ways of building. Tags that can be combined multiply the
count: two independent tags are four builds per target, three are eight. **In practice a project
checks each tag on its own, plus the combinations it actually ships.** It writes that list down in
a script like this one, because a list in a script is checked on every change and a list in
somebody's head is not.

## What vet cannot tell you

`check.sh` proves that every combination **compiles** and passes vet's checks. It does not prove that
any of them works. The macOS build has never run, here or anywhere in this course, and whether
Ctrl-T reaches `hits` on a Mac is a claim only a Mac can check. Lesson 16 runs the Linux `arm64`
build under an emulator and its tests with `go test -exec`; macOS and Windows need a machine of
their own, which for most projects means a CI runner per system. What the loop buys is that such a
runner never fails on the morning of a release because of a name that exists on one system only.
