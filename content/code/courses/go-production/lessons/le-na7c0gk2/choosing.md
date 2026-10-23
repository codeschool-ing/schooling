---
title: Choosing, with the numbers
version: 1
---

Three ways to add a reporter, and each was described with its cost. This section puts numbers on
the costs that can be measured, the speed of a call and what has to ship, and then sets the three
side by side. **The plugin's one real advantage is speed, and it is shared with the compiled-in
reporter**: both are an ordinary call through an interface, in the same process.

## The cost of a call

A benchmark of one call to the mean reporter, made the three ways. It loads `mean.so` and runs
`mean-exec` from the module's top directory, so both have to be built first, as they were in
sections 03 and 04. The file is `bench/bench_test.go`:

```go
// Package bench measures one call to the mean reporter, made three ways.
package bench

import (
	"bytes"
	"encoding/json"
	"io"
	"os/exec"
	"plugin"
	"testing"
	"time"

	"example.com/hits/internal/tally"
	"example.com/hits/report"
	"example.com/hits/reporters/mean"
)

var s = tally.Summary{
	Lines:    2,
	ByStatus: map[int]int{200: 1, 404: 1},
	ByPath:   map[string]int{"/": 1, "/login": 1},
	Total:    12 * time.Millisecond,
}

// A reporter compiled into the program, called through the interface.
func BenchmarkCompiledIn(b *testing.B) {
	var r report.Reporter = mean.Reporter{}
	for b.Loop() {
		r.Report(s, io.Discard)
	}
}

// The same reporter, loaded from mean.so.
func BenchmarkPlugin(b *testing.B) {
	p, err := plugin.Open("../mean.so")
	if err != nil {
		b.Fatal(err)
	}
	sym, err := p.Lookup("Reporter")
	if err != nil {
		b.Fatal(err)
	}
	r := sym.(func() report.Reporter)()
	for b.Loop() {
		r.Report(s, io.Discard)
	}
}

// The same reporter as a program: one process per call.
func BenchmarkProcess(b *testing.B) {
	in, err := json.Marshal(map[string]any{"protocol": 1, "summary": s})
	if err != nil {
		b.Fatal(err)
	}
	for b.Loop() {
		cmd := exec.Command("../mean-exec")
		cmd.Stdin = bytes.NewReader(in)
		cmd.Stdout = io.Discard
		if err := cmd.Run(); err != nil {
			b.Fatal(err)
		}
	}
}
```

```
ana@vm:~/plugins$ go test -bench . -benchmem ./bench
goos: linux
goarch: amd64
pkg: example.com/hits/bench
cpu: Intel(R) Xeon(R) Processor
BenchmarkCompiledIn-4   	 9036969	       132.0 ns/op	      16 B/op	       2 allocs/op
BenchmarkPlugin-4       	 8842059	       136.1 ns/op	      16 B/op	       2 allocs/op
BenchmarkProcess-4      	     710	   1581082 ns/op	    5633 B/op	      53 allocs/op
PASS
ok  	example.com/hits/bench	3.528s
```

**The plugin costs what the compiled-in reporter costs**: 136.1 nanoseconds against 132.0, a gap
of three per cent that another run can close or reverse. After `Lookup`, a plugin's `Report` is a
method call through an interface like any other. The process costs about **1.6 milliseconds per
call, roughly twelve thousand times as much**, and almost none of that is the reporter. It is
`fork` and `exec`, a Go runtime starting in a new process, and the JSON going through a pipe, with
53 allocations on the host's side alone. The rule that comes out of it is about how often a
reporter is called. `hits` calls one once per run, after counting 20,000 lines, and 1.6 ms is
nothing next to that. A reporter called once per log line would turn 20,000 lines into about 30
seconds of process starts, and there only an in-process call, or a child process kept running,
will do.

## What has to ship

```
ana@vm:~/plugins$ stat -c "%s bytes  %n" hits-static hits-plugin csv.so mean.so hits-exec mean-exec
2689276 bytes  hits-static
4901728 bytes  hits-plugin
3725312 bytes  csv.so
4678960 bytes  mean.so
4316716 bytes  hits-exec
3897476 bytes  mean-exec
ana@vm:~/plugins$ readelf -d hits-static | grep -c NEEDED
0
```

The compiled-in host, with both reporters inside it, is **2,689,276 bytes and needs nothing from
the system**. The plugin host is 4,901,728 bytes before a single reporter, plus 3.7 and 4.7 MB of
`.so` files that only work beside the exact host they were built with. And lesson 18 put `hits` in
`gcr.io/distroless/static-debian12`, an image with no C library, which is the image a static Go
binary is meant for:

```
ana@vm:~/plugins$ podman run --rm --network=none -v "$PWD":/w -w /w gcr.io/distroless/static-debian12:nonroot ./hits-plugin access.log csv.so; echo $?
exec ./hits-plugin: no such file or directory
255
ana@vm:~/plugins$ readelf -l hits-plugin | grep interpreter
      [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
ana@vm:~/plugins$ podman run --rm -i --network=none -v "$PWD":/w -w /w gcr.io/distroless/static-debian12:nonroot ./hits-static -r mean < access.log
20000 requests, mean 200ms
```

`no such file or directory` names a file that is there. What is missing is the program's
interpreter, `/lib64/ld-linux-x86-64.so.2`, the loader that a dynamically linked program asks the
kernel to run first, and the static image has none. **A host that loads plugins needs a base image
with a C library**, which is a bigger image, with more in it to patch. The static host ran in the
image lesson 18 chose, unchanged. The container ran with `--network=none` because this lab has
no network device for containers; none of these programs uses one.

## Side by side

| | Go plugin | separate program | compiled in |
|---|---|---|---|
| a call | about 130 ns, an interface call | about 1.6 ms, a process start | about 130 ns, an interface call |
| what ships | a dynamically linked host and a `.so` per reporter, from one build | the host, and each reporter as a program in any language | one static binary |
| a new reporter | rebuild the plugin with the host's exact toolchain, flags and shared packages | install the program; nothing is rebuilt | add an import and rebuild |
| a crash in a reporter | kills the host | costs one report and an exit code | kills the host |
| versioning | every shared package must match, checked at `Open` | the protocol number, checked by the reporter | the compiler checks it all, at build time |
| a new version while running | refused, `plugin already loaded` | the next call starts the new program | impossible; restart |
| platforms | 14 of 47, cgo required | every one `os/exec` runs on | every one Go builds for |

**Read the table by the requirement, not by the column.** If reporters come from strangers, are
written in other languages, or must be replaced while the host runs, only the separate program meets
the requirement, and the first row is its price. If the team that builds the host also builds the
reporters, the compiled-in column is as fast as the plugin and better on every other row. The plugin
column is best on no row. It is the only one that is fast, loaded at run time and written in Go at
once. That is a narrow case: one team, one build, one toolchain, and a reason to keep a reporter out
of the binary that survives section 03.

## The end of the course

`hits` began in lesson 1 as a standard-library CLI with two subcommands, two streams and an exit
code, and took three other command lines in lessons 2 to 4. Lessons 5 to 11 put the toolchain around
it: formatting, `vet`, linters, a vulnerability scan, generated code and build tags. In lessons 12
to 14 its `Parse` was profiled, read in a flame graph and seen in a trace, so that what was slow was
measured before anything was changed. Lessons 16 to 18 built it for other machines, made it smaller
and shipped it as a signed image. Lessons 19 to 24 went under the language: the memory it uses,
where its variables live, and the four escape hatches of reflection, `unsafe`, cgo and plugins, each
taught with the bill that comes with it.
