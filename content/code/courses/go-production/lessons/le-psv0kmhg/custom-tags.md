---
title: Tags of your own
version: 1
---

A build tag does not have to name a system. **Any word in a `//go:build` line that the build does
not set by itself is false, until a command line sets it with `-tags`.** That makes a constraint a
switch for whole files: code that exists in one build of the program and is absent from the other,
chosen when the program is built rather than when it runs.

Two uses are common enough to show. A debugging build that says more than the one you ship, and a
set of tests too slow or too demanding to run every time.

## A debugging build

Section 02's `main.go` calls `debugf` after each count, and `debugf` is a variable holding a
function that does nothing. A file built only with the tag `debug` replaces it. Save it as
`debug.go`:

```go
//go:build debug

package main

import (
	"fmt"
	"io"
)

func init() {
	debugf = func(w io.Writer, format string, a ...any) {
		fmt.Fprintf(w, "hits: debug: "+format+"\n", a...)
	}
}
```

**An `init` function runs before `main`**, so by the time `summarise` calls `debugf`, a debug build
holds the version that prints. Built both ways:

```
ana@vm:~/tags$ go build -o hits . && ./hits top -n 1 access.log
path    requests
/login  2576
ana@vm:~/tags$ go build -tags debug -o hits-debug . && ./hits-debug top -n 1 access.log
hits: debug: 20000 lines, 914867 bytes in 6.991181ms
path    requests
/login  2576
```

The ordinary build printed lesson 1's table and nothing else. The debug build printed one more line
on standard error first: the 20,000 lines, the 914,867 bytes of `access.log`, and the time
`tally.Count` took, a few milliseconds. The timing changes from run to run; the two counts do not.

**The tags are part of what a binary records about its build**, beside the `GOOS` and `GOARCH` that
lesson 16 reads back with the same command, so a debug binary that ends up somewhere it should not
can be recognised:

```
ana@vm:~/tags$ go version -m hits-debug | grep -- -tags
	build	-tags=debug
ana@vm:~/tags$ go list -f '{{.GoFiles}}' .; go list -tags debug -f '{{.GoFiles}}' .
[main.go progress.go progress_unix.go]
[debug.go main.go progress.go progress_unix.go]
ana@vm:~/tags$ strings hits | grep -c "hits: debug: "; strings hits-debug | grep -c "hits: debug: "
0
1
```

`go list -tags debug` adds `debug.go` to the files the package compiles. And the string the debug
line starts with is in one binary and not in the other: `strings` prints the readable text in a
file, and `grep -c` counts the matches. **Code behind a tag that was not given is not in the binary
at all**, which is the difference between a tag and a `-debug` flag read at run time.

The variable in `main.go` is one way to arrange it. The other common one is a pair of files,
`debug.go` with `//go:build debug` and `nodebug.go` with `//go:build !debug`, each defining the same
function or constant. The pair says more in the file names; the variable means only one file has to
exist and the ordinary build cannot be broken by a missing counterpart.

## Writing `-tags`

Every go command that builds or reads packages takes `-tags`: `build`, `run`, `test`, `vet`, `list`,
`install`. Several tags are one argument, **separated by commas**: `-tags debug,integration`. The
older form with spaces still works and `go help build` calls it deprecated. A tag that nothing in
the code mentions is accepted without a word, so a misspelt `-tags debgu` builds the ordinary binary
and says nothing. To give the same tags to every command in a shell, `GOFLAGS=-tags=debug` does it;
setting it and forgetting it is how a debug build gets released.

## Tests that wait to be asked

`main_test.go` from lesson 1 calls `run` with a buffer for each stream and finishes in
milliseconds. It never builds the program or starts a process. A test that does, builds `hits`,
writes a log with `genlog` and runs the binary on it the way a person would, catches a different
class of mistake and costs a build every time. **Such a test goes behind a tag**, so `go test` skips
it and a CI job that asks for it runs it. Save it as `integration_test.go`:

```go
//go:build integration

package main

import (
	"bytes"
	"os/exec"
	"path/filepath"
	"testing"
)

// TestBinary builds hits and runs the binary the way a person does, on a log
// that genlog writes. It needs the go command and a build of its own, so it
// runs only when somebody asks for it with -tags integration.
func TestBinary(t *testing.T) {
	bin := filepath.Join(t.TempDir(), "hits")
	if out, err := exec.Command("go", "build", "-o", bin, ".").CombinedOutput(); err != nil {
		t.Fatalf("go build: %v\n%s", err, out)
	}
	log, err := exec.Command("go", "run", "./tools/genlog", "-n", "20000").Output()
	if err != nil {
		t.Fatalf("genlog: %v", err)
	}

	cmd := exec.Command(bin, "top", "-n", "1")
	cmd.Stdin = bytes.NewReader(log)
	out, err := cmd.Output()
	if err != nil {
		t.Fatalf("hits top: %v", err)
	}
	if want := "path    requests\n/login  2576\n"; string(out) != want {
		t.Errorf("hits top printed %q, want %q", out, want)
	}

	var stderr bytes.Buffer
	cmd = exec.Command(bin)
	cmd.Stderr = &stderr
	if err := cmd.Run(); err == nil {
		t.Error("hits with no command succeeded")
	}
	if stderr.String() != usage {
		t.Errorf("hits with no command printed %q, want the usage", stderr.String())
	}
}
```

The last check compares what the binary prints with no command against `usage`, the constant in
`main.go`, so a change to the usage text cannot leave the binary behind. Without the tag and with
it:

```
ana@vm:~/tags$ go test -count=1 .
ok  	example.com/hits	0.002s
ana@vm:~/tags$ go test -count=1 -tags integration -run TestBinary -v .
=== RUN   TestBinary
--- PASS: TestBinary (0.32s)
PASS
ok  	example.com/hits	0.322s
ana@vm:~/tags$ go list -f '{{.TestGoFiles}} {{.IgnoredGoFiles}}' .
[main_test.go] [debug.go integration_test.go progress_darwin.go progress_other.go]
```

**The plain `go test` did not compile `integration_test.go`**; `go list` names it among the ignored
files, with `debug.go` and the two per-system files this machine does not use. With
`-tags integration` the test built `hits`, ran it, and passed in about a third of a second, more
than a hundred times the `0.002s` of the ordinary run. The `-run TestBinary` picked the one test out by
name, and `-count=1` kept both runs from being answered from the cache.

## What a tag costs

A file behind a tag is compiled only by a command that names the tag. **Every other command treats
it as if it did not exist**: `go build`, `go vet` and `go test` all read the package without it.
So a change elsewhere can break it, and nothing you normally run says so.

Here is that happening. `gofmt -r` rewrites Go code by a pattern, and `'usage -> usageText'` renames
the constant everywhere in `main.go`, the kind of tidy-up anybody might make:

```
ana@vm:~/tags$ gofmt -r 'usage -> usageText' -w main.go && go vet ./... && go test -count=1 ./... && echo green
ok  	example.com/hits	0.002s
?   	example.com/hits/internal/tally	[no test files]
?   	example.com/hits/tools/genlog	[no test files]
green
ana@vm:~/tags$ go vet -tags integration .
# example.com/hits
# [example.com/hits]
vet: ./integration_test.go:41:24: undefined: usage
ana@vm:~/tags$ gofmt -r 'usageText -> usage' -w main.go && go vet -tags integration . && echo clean
clean
```

After the rename, `go vet` was clean, every test passed, and the line said `green`. **The one file
that still says `usage` is the one none of those commands compiled**, and only `go vet -tags
integration` found it. In a project, that is a CI job that runs once a night, or a file nobody has
compiled since the person who wrote it left. The second `gofmt -r` put the name back.

The remedy is not to avoid tags, which do a job nothing else does. It is to make sure that **every
tag the code uses is named by at least one command that runs on every change**, which for most
projects means a vet run per tag in CI. Section 05 writes that run.
