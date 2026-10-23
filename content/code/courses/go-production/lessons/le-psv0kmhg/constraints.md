---
title: The `//go:build` line
version: 1
---

When code has to differ between Windows and Linux, the first thing most people reach for is an
`if runtime.GOOS == "windows"`. **That works only while every branch compiles on every system.** A
branch that names `syscall.SIGUSR1` does not compile for Windows, whose `syscall` package has no such
name, and the compiler refuses the whole program before any branch gets the chance not to run. A
build constraint works one level up: it decides which files the compiler is given at all, so a file
that would not compile for Windows is simply not part of a Windows build.

This section adds a feature to `hits` that needs exactly that, writes it the naive way, watches it
fail, and then splits it into one file per kind of system.

## A feature that differs by system

Counting a big log takes a while, and a person waiting for it wants to know how far it has got.
**Unix has a convention for asking a running program that question: send it a signal.** GNU `dd`
prints its progress when it receives `SIGUSR1`, and on macOS and the BSDs pressing Ctrl-T sends
`SIGINFO`, which their own tools answer the same way. Windows has neither signal. The `os/signal`
package asks the Go runtime to deliver chosen signals on a channel instead of acting on them, and
that is all `hits` needs.

The work happens in a new directory, `~/tags`, which holds lesson 1's `hits`: the `tally` package,
`main_test.go` and `genlog`, with the module made by `go mod init example.com/hits` and the
20,000-line `access.log` that `go run ./tools/genlog -n 20000` writes. Two files are new. The first
counts what passes through it and reports the count when a signal arrives:

```schooling-example
{
  "language": "go",
  "file": "progress.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"os\"\n\t\"os/signal\"\n\t\"sync/atomic\"\n)\n",
      "note": "Nothing in this file names a system. **It compiles for every target as it stands**, and that is the reason it is one file: the part that differs is a single variable, `progressSignals`, which it uses and does not define."
    },
    {
      "code": "// progress counts the bytes read through it, so that a long count can say\n// how far it has got.\ntype progress struct {\n\tr io.Reader\n\tn atomic.Int64\n}\n\nfunc (p *progress) Read(b []byte) (int, error) {\n\tn, err := p.r.Read(b)\n\tp.n.Add(int64(n))\n\treturn n, err\n}\n",
      "note": "A reader that wraps another and counts what passes through, the kind of composition `go-concurrency` lesson 17 builds. `tally.Count` reads from it without knowing. The count is an `atomic.Int64` because the goroutine below reads it while `Count` is still adding to it."
    },
    {
      "code": "// watch prints the count on stderr each time one of progressSignals\n// arrives, until the function it returns is called.\nfunc (p *progress) watch(stderr io.Writer) (stop func()) {\n\tif len(progressSignals) == 0 {\n\t\treturn func() {}\n\t}\n\tc := make(chan os.Signal, 1)\n\tsignal.Notify(c, progressSignals...)\n\tdone := make(chan struct{})",
      "note": "**An empty list means no signal at all.** Without the check, `signal.Notify(c)` with nothing after it would relay every signal the process receives, which is the opposite of what a system with no progress signal wants."
    },
    {
      "code": "\tgo func() {\n\t\tfor {\n\t\t\tselect {\n\t\t\tcase <-c:\n\t\t\t\tfmt.Fprintf(stderr, \"hits: %d bytes read\\n\", p.n.Load())\n\t\t\tcase <-done:\n\t\t\t\treturn\n\t\t\t}\n\t\t}\n\t}()\n\treturn func() {\n\t\tsignal.Stop(c)\n\t\tclose(done)\n\t}\n}",
      "note": "The goroutine waits in a `select`, as in `go-concurrency` lesson 5, for a signal or for `stop`. **`stop` unregisters the channel and closes `done`**, so the goroutine ends when the count does instead of outliving it, which is `go-concurrency` lesson 6's subject."
    }
  ]
}
```

The second is `main.go`, which replaces lesson 1's. It changes in one function and gains one
variable; copy the whole file over the old one:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command hits summarises a web server's access log.\npackage main\n\nimport (\n\t\"encoding/json\"\n\t\"errors\"\n\t\"flag\"\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"os\"\n\t\"slices\"\n\t\"text/tabwriter\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "Lesson 1's `main.go` with one import more, `time`. **Everything above `summarise` is unchanged**, and so is everything below `debugf`."
    },
    {
      "code": "const usage = `usage: hits <command> [flags] [file]\n\ncommands:\n  count   requests per status code\n  top     the paths with the most requests\n\nWith no file, or with -, hits reads standard input.\n`\n\nfunc main() {\n\tos.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))\n}\n\nfunc run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tif len(args) == 0 {\n\t\tfmt.Fprint(stderr, usage)\n\t\treturn 2\n\t}\n\tswitch args[0] {\n\tcase \"count\":\n\t\treturn count(args[1:], stdin, stdout, stderr)\n\tcase \"top\":\n\t\treturn top(args[1:], stdin, stdout, stderr)\n\tcase \"help\", \"-h\", \"-help\", \"--help\":\n\t\tfmt.Fprint(stdout, usage)\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stderr, \"hits: unknown command %q\\n\\n%s\", args[0], usage)\n\treturn 2\n}\n\nfunc count(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"count\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, s.ByStatus)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"status\\trequests\")\n\tfor _, status := range slices.Sorted(maps.Keys(s.ByStatus)) {\n\t\tfmt.Fprintf(tw, \"%d\\t%d\\n\", status, s.ByStatus[status])\n\t}\n\treturn flush(tw, stderr)\n}\n\nfunc top(args []string, stdin io.Reader, stdout, stderr io.Writer) int {\n\tfs := flag.NewFlagSet(\"top\", flag.ContinueOnError)\n\tfs.SetOutput(stderr)\n\tn := fs.Int(\"n\", 3, \"how many paths to show\")\n\tasJSON := fs.Bool(\"json\", false, \"print JSON instead of a table\")\n\tif err := fs.Parse(args); err != nil {\n\t\treturn flagError(err)\n\t}\n\ts, code := summarise(fs.Args(), stdin, stderr)\n\tif code != 0 {\n\t\treturn code\n\t}\n\trows := tally.Top(s, *n)\n\tif *asJSON {\n\t\treturn encode(stdout, stderr, rows)\n\t}\n\ttw := tabwriter.NewWriter(stdout, 0, 0, 2, ' ', 0)\n\tfmt.Fprintln(tw, \"path\\trequests\")\n\tfor _, r := range rows {\n\t\tfmt.Fprintf(tw, \"%s\\t%d\\n\", r.Path, r.Hits)\n\t}\n\treturn flush(tw, stderr)\n}\n"
    },
    {
      "code": "// summarise counts the file named in args, or standard input.\nfunc summarise(args []string, stdin io.Reader, stderr io.Writer) (tally.Summary, int) {\n\tin := stdin\n\tswitch {\n\tcase len(args) > 1:\n\t\tfmt.Fprintf(stderr, \"hits: one file at most, got %d\\n\", len(args))\n\t\treturn tally.Summary{}, 2\n\tcase len(args) == 1 && args[0] != \"-\":\n\t\tf, err := os.Open(args[0])\n\t\tif err != nil {\n\t\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\t\treturn tally.Summary{}, 1\n\t\t}\n\t\tdefer f.Close()\n\t\tin = f\n\t}",
      "note": "`summarise` is lesson 1's down to the point where it has an input to read: a file, or standard input."
    },
    {
      "code": "\tp := &progress{r: in}\n\tstop := p.watch(stderr)\n\tstart := time.Now()\n\ts, err := tally.Count(p)\n\tstop()\n\tdebugf(stderr, \"%d lines, %d bytes in %v\", s.Lines, p.n.Load(), time.Since(start))\n\tif err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn s, 1\n\t}\n\treturn s, 0\n}\n",
      "note": "**The input is wrapped in a `progress` before `tally.Count` reads it**, and `watch` listens for the progress signals while it does. After the count comes one call to `debugf` with what a person chasing a slow run wants: lines, bytes and the time `Count` took."
    },
    {
      "code": "// debugf does nothing in an ordinary build. A file built only with\n// -tags debug replaces it with one that prints.\nvar debugf = func(w io.Writer, format string, a ...any) {}\n",
      "note": "**A function in a variable, which does nothing.** Section 04 adds a file, compiled only when somebody asks for it, that puts a function that prints in its place."
    },
    {
      "code": "// flush writes out a table, and encode a value as JSON. A write can fail,\n// on a full disk for one, and that is reported.\nfunc flush(tw *tabwriter.Writer, stderr io.Writer) int {\n\tif err := tw.Flush(); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\nfunc encode(stdout, stderr io.Writer, v any) int {\n\tif err := json.NewEncoder(stdout).Encode(v); err != nil {\n\t\tfmt.Fprintf(stderr, \"hits: %v\\n\", err)\n\t\treturn 1\n\t}\n\treturn 0\n}\n\n// flagError turns a failed parse into an exit code. The flag package has\n// already printed the message and the usage.\nfunc flagError(err error) int {\n\tif errors.Is(err, flag.ErrHelp) {\n\t\treturn 0\n\t}\n\treturn 2\n}"
    }
  ]
}
```

`progress.go` uses `progressSignals` without defining it. The first draft defines it the obvious
way, in a file of its own, `signals.go`:

```go
package main

import (
	"os"
	"syscall"
)

// progressSignals are the signals that make hits report its progress.
var progressSignals = []os.Signal{syscall.SIGUSR1}
```

## It works here and nowhere else

Built, and tried on a log long enough to watch. `genlog` writes twenty million lines into a pipe,
the shell starts the pipeline in the background with `&`, and `$!` is the process number of
`hits`, the last command in it. Two `kill -USR1` a second apart ask for progress twice:

```
ana@vm:~/tags$ go build -o hits . && go build -o genlog ./tools/genlog
ana@vm:~/tags$ ./genlog -n 20000000 | ./hits count > /dev/null & sleep 1; kill -USR1 $!; sleep 1; kill -USR1 $!; wait $!
hits: 142302665 bytes read
hits: 290270575 bytes read
```

Each signal produced a line on standard error, and **the second count is larger than the first**
because `hits` kept reading in between. The numbers depend on how fast the machine is; yours will
differ. `wait $!` holds the prompt until `hits` finishes, and its output went to `/dev/null` because
here only the progress lines matter.

Now the same program for Windows. `GOOS` names the system to build for, and lesson 16 is about it
in full. Here it is only the way to ask whether this code compiles for Windows at all:

```
ana@vm:~/tags$ GOOS=windows go build -o hits.exe .; echo $?
# example.com/hits
./signals.go:9:43: undefined: syscall.SIGUSR1
1
```

**`syscall.SIGUSR1` does not exist on Windows**, so `signals.go` does not compile there, and with it
neither does `hits`. Nothing about the Linux build warned of this. An `if runtime.GOOS` around the
line would not help either, since the name has to exist for the line to compile, whichever branch
would run.

## One file per kind of system

The fix is three small files that each define `progressSignals`, and a rule on each that says which
builds may see it. First the draft goes:

```
ana@vm:~/tags$ rm signals.go
```

For Linux and the rest of Unix, `progress_unix.go`:

```go
//go:build unix && !darwin

package main

import (
	"os"
	"syscall"
)

// On Linux and the other Unix systems, kill -USR1 asks for progress.
var progressSignals = []os.Signal{syscall.SIGUSR1}
```

For macOS, where Ctrl-T is the habit, `progress_darwin.go`:

```go
package main

import (
	"os"
	"syscall"
)

// On macOS, Ctrl-T in the terminal sends SIGINFO, and kill -USR1 works too.
var progressSignals = []os.Signal{syscall.SIGINFO, syscall.SIGUSR1}
```

For everything else, Windows included, `progress_other.go`:

```go
//go:build !unix

package main

import "os"

// Windows and the other systems have no signal for this.
var progressSignals []os.Signal
```

**The first line of two of them is a build constraint**: `//go:build`, then an expression that has
to be true for the file to be compiled. `unix && !darwin` holds on Linux, FreeBSD and the other
Unix systems except macOS, and `!unix` holds everywhere else. The macOS file has no such line, and
still is compiled only for macOS, because its name ends in `_darwin`; section 03 is about names.
Between them the three files cover every system exactly once, so every build finds one definition
of `progressSignals`, and on Windows that definition is an empty list, which `watch` treats as
"no signal".

Three systems, three builds:

```
ana@vm:~/tags$ go build -o hits . && GOOS=darwin go build -o hits-mac . && GOOS=windows go build -o hits.exe . && echo built
built
ana@vm:~/tags$ ./genlog -n 20000000 | ./hits count > /dev/null & sleep 1; kill -USR1 $!; wait $!
hits: 75326472 bytes read
ana@vm:~/tags$ file hits-mac hits.exe | cut -d, -f1,2
hits-mac: Mach-O 64-bit x86_64 executable, flags:<|DYLDLINK|PIE>
hits.exe: PE32+ executable (console) x86-64, for MS Windows
```

**All three built**, and `file` agrees that the second is a macOS executable and the third a Windows
one. Neither of those two can run on this machine, and lesson 16 is about what can be checked
without one; the Linux build answered the signal as before.

## The rules of the line

`go help buildconstraint` is the reference, and it is short. The rules that matter in practice:

- **The line goes before the package clause**, with only blank lines and other comments above it.
  `//go:build` is written with no space after the slashes, because it is a directive, the same
  family as `//go:embed` in `go-concurrency` lesson 24.
- **A blank line follows it**, so that it is not read as the start of the package's documentation.
  `gofmt` inserts one if it is missing.
- **Tags combine with `&&`, `||`, `!` and parentheses**, which mean what they mean in Go:
  `//go:build (linux && 386) || (darwin && !cgo)` is the example the help text gives.
- **One `//go:build` line per file.** A second one is an error, not a further condition.

The tags a build satisfies on its own are these. Anything else is false unless the command line
names it, which is section 04's subject.

| tag | true when |
|---|---|
| `linux`, `darwin`, `windows`, `freebsd`, … | it is the target system, `GOOS` |
| `amd64`, `arm64`, `386`, … | it is the target processor, `GOARCH` |
| `unix` | the target is a Unix-like system: Linux, macOS, the BSDs, Solaris and AIX among them |
| `cgo` | cgo is on, which lesson 16 shows is not the case in a cross build |
| `gc`, `gccgo` | that compiler is the one building |
| `go1.1` … `go1.27` | the Go release is at least that one; Go 1.27.1 satisfies all of them up to `go1.27` |
| `amd64.v3`, `arm64.v8.0`, … | the processor level chosen with `GOAMD64`, `GOARM64` and the rest |

Three systems count as another as well: a build for `android` also satisfies `linux`, one for
`ios` satisfies `darwin`, and one for `illumos` satisfies `solaris`. A file that must never be built,
like a script run by hand with `go run gen.go`, carries `//go:build ignore`: no build sets `ignore`,
and the word says why the line is there. A release tag does a second job too. In a module whose
`go.mod` says 1.21 or later, a file constrained by `go1.N` is compiled with the language of that
release. So a file marked `//go:build go1.21` may not `range` over an integer, which arrived in Go
1.22, even in a module that says `go 1.27.1`.

## Two mistakes that compile

A constraint that is written wrongly is often not an error at all. The most common slip is a space,
`// go:build`, which turns the directive into an ordinary comment. Here it is in `progress_other.go`,
put in with `sed` and taken out again:

```
ana@vm:~/tags$ sed -i 's#^//go:build !unix#// go:build !unix#' progress_other.go; go vet .
# example.com/hits
# [example.com/hits]
vet: ./progress_unix.go:11:5: progressSignals redeclared in this block
ana@vm:~/tags$ sed -i 's#^// go:build#//go:build#' progress_other.go; go vet . && echo clean
clean
```

With the space, the file was no longer constrained, so the Linux build compiled it beside
`progress_unix.go`, and **the report is a redeclaration two files away from the mistake**. Here the
mistake showed because both files define the same name. A file that defines nothing another file
also defines would have been compiled for every system, silently, with nothing to report.

A constraint below the package clause is the other slip, and that one the compiler refuses:

```
ana@vm:~/tags$ printf 'package main\n\n//go:build windows\n' > late.go; go build -o hits .; rm late.go
# example.com/hits
./late.go:3:3: misplaced compiler directive
```

## The old `// +build` form

Go 1.16 and earlier wrote constraints as `// +build` lines, with commas for "and" and spaces for
"or", and older code still carries them. **`gofmt` writes the `//go:build` equivalent above an old
line**, and `go fix` removes the old line from a file that has both:

```
ana@vm:~/tags$ mkdir old && printf '// +build linux,amd64\n\npackage old\n' > old/old.go
ana@vm:~/tags$ gofmt -d old/old.go
diff old/old.go.orig old/old.go
--- old/old.go.orig
+++ old/old.go
@@ -1,3 +1,4 @@
+//go:build linux && amd64
 // +build linux,amd64
 
 package old
ana@vm:~/tags$ gofmt -w old/old.go && go fix -diff ./old
--- /home/ana/tags/old/old.go (old)
+++ /home/ana/tags/old/old.go (new)
@@ -1,4 +1,3 @@
 //go:build linux && amd64
-// +build linux,amd64
 
 package old
```

The `go fix` in Go 1.27.1 runs a set of rewrites, and `plusbuild` is the one that deletes `// +build`
lines; `-diff` prints what it would change instead of changing it. `go vet` checks that the two
forms agree in a file that has both. For code you write now, there is one form, and it is the one
`progress_unix.go` uses.
