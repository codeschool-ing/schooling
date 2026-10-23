---
title: Asking the toolchain with `go doc` and `go list`
version: 1
---

Two questions come up all day: what does this function promise, and what is this package made of.
**The go command answers both from the source on your disk**, with no browser and no network:
`go doc` prints the documentation comments of any package it can find, yours included, and
`go list` prints any fact the go command knows about a package, in whatever shape you ask for.

## `go doc` on your own code

The comments lesson 1 wrote above each declaration of `tally` are the documentation. `go doc`
takes a package, a symbol, or a package and a symbol, and finds the package by its full import path,
a relative path, or any final part of the path that is unique:

```
ana@vm:~/daily$ go doc
Command hits summarises a web server's access log.
ana@vm:~/daily$ go doc ./internal/tally
package tally // import "example.com/hits/internal/tally"

Package tally reads the lines of an access log and counts them.

type Entry struct{ ... }
    func Parse(line string) (Entry, error)
type PathCount struct{ ... }
    func Top(s Summary, n int) []PathCount
type Summary struct{ ... }
    func Count(r io.Reader) (Summary, error)
ana@vm:~/daily$ go doc tally.Top
package tally // import "example.com/hits/internal/tally"

func Top(s Summary, n int) []PathCount
    Top returns the n paths with the most requests, the most first. Paths with
    the same count come in alphabetical order.

ana@vm:~/daily$ go doc tally.summary
package tally // import "example.com/hits/internal/tally"

type Summary struct {
	Lines    int
	ByStatus map[int]int
	ByPath   map[string]int
	Total    time.Duration
}
    Summary is what Count found.

func Count(r io.Reader) (Summary, error)
```

With no argument it documents the package in the current directory, and for a `main` package that
is the package comment and nothing more: `Command hits summarises a web server's access log.`
**For a library it prints the package comment and one line per exported declaration**, grouped the
way a reader looks for them. `Parse` sits under `Entry` and `Count` under `Summary` because each
returns that type, so the function that makes a value is listed with it. A lowercase symbol matches
either case, which is why `tally.summary` found `Summary`, its fields and its constructor.

That output is only as good as the comments, and the conventions it relies on are the ones `tally`
follows. **A doc comment is a full sentence that starts with the name it documents**: `Top returns
the n paths with the most requests`, `Summary is what Count found.` The package comment starts with `Package tally`, and
it is the sentence `go doc` puts at the top. An exported name with no comment still appears, and
`go doc` on it prints the declaration with nothing under it, which is the cue to write one.

Three flags change how much comes back:

```
ana@vm:~/daily$ go doc -short tally
type Entry struct{ ... }
    func Parse(line string) (Entry, error)
type PathCount struct{ ... }
    func Top(s Summary, n int) []PathCount
type Summary struct{ ... }
    func Count(r io.Reader) (Summary, error)
ana@vm:~/daily$ go doc -src tally.Top
package tally // import "example.com/hits/internal/tally"

// Top returns the n paths with the most requests, the most first. Paths
// with the same count come in alphabetical order.
func Top(s Summary, n int) []PathCount {
	rows := make([]PathCount, 0, len(s.ByPath))
	for p, h := range s.ByPath {
		rows = append(rows, PathCount{p, h})
	}
	slices.SortFunc(rows, func(a, b PathCount) int {
		return cmp.Or(cmp.Compare(b.Hits, a.Hits), cmp.Compare(a.Path, b.Path))
	})
	return rows[:min(n, len(rows))]
}
ana@vm:~/daily$ go doc -ex tally.Top
package tally // import "example.com/hits/internal/tally"

func Top(s Summary, n int) []PathCount
    Top returns the n paths with the most requests, the most first. Paths with
    the same count come in alphabetical order.

    func ExampleTop()
ana@vm:~/daily$ go doc -all tally | wc -l
41
```

`-short` keeps only the one-line declarations. **`-src` prints the source of the declaration,
body and all**, which is often the quickest way to answer "what does it do on a tie" without opening
an editor. `-ex` adds the examples attached to a symbol, and `ExampleTop` from section 04 is listed
under `Top` because of its name: `Example` followed by the symbol is how an example is attached.
`-all` prints the documentation of every exported declaration in the package at once, 41 lines for
`tally`, the form to pipe into `less` or `grep`.

## `go doc` on everything else

The same command reads the standard library, and a method is named as `type.Method`. `tally.Count`
reads lines with a `bufio.Scanner`, which makes this worth a look:

```
ana@vm:~/daily$ go doc bufio.Scanner.Buffer
package bufio // import "bufio"

func (s *Scanner) Buffer(buf []byte, max int)
    Buffer controls memory allocation by the Scanner. It sets the initial buffer
    to use when scanning and the maximum size of buffer that may be allocated
    during scanning. The contents of the buffer are ignored.

    The maximum token size must be less than the larger of max and cap(buf).
    If max <= cap(buf), Scanner.Scan will use this buffer only and do no
    allocation.

    By default, Scanner.Scan uses an internal buffer and sets the maximum token
    size to MaxScanTokenSize.

    Buffer panics if it is called after scanning has started.

ana@vm:~/daily$ go doc bufio.MaxScanTokenSize
package bufio // import "bufio"

const (
	// MaxScanTokenSize is the maximum size used to buffer a token
	// unless the user provides an explicit buffer with [Scanner.Buffer].
	// The actual maximum token size may be smaller as the buffer
	// may need to include, for instance, a newline.
	MaxScanTokenSize = 64 * 1024
)
ana@vm:~/daily$ head -c 70000 /dev/zero | tr "\0" a | ./bin/hits count; echo $?
hits: bufio.Scanner: token too long
1
```

**The documentation predicted a failure that no test of `hits` had found.** A `Scanner` refuses a
line longer than its maximum token size, 64 KiB unless `Buffer` raises it, and `Count` never calls
`Buffer`. A line of 70,000 bytes made from `head` and `tr` stops `hits` with
`bufio.Scanner: token too long` and exit status 1. No real access log line is that long, so `hits`
can live with it, but it is now a decision rather than a surprise.

## `go list`: the facts the go command uses

`go list` with a pattern prints import paths, one per line. With `-f` it runs a Go template over a
structure describing each package; `go help list` prints that structure field by field, and every
field is a question you can ask:

```
ana@vm:~/daily$ go list ./...
example.com/hits
example.com/hits/internal/tally
example.com/hits/tools/genlog
ana@vm:~/daily$ go list -f "{{.Name}}  {{.ImportPath}}  {{.GoFiles}} {{.TestGoFiles}} {{.XTestGoFiles}}" ./...
main  example.com/hits  [main.go] [main_test.go] []
tally  example.com/hits/internal/tally  [tally.go] [] [tally_test.go]
main  example.com/hits/tools/genlog  [main.go] [] []
ana@vm:~/daily$ go list -json=Dir,GoFiles,Imports ./internal/tally
{
	"Dir": "/home/ana/daily/internal/tally",
	"GoFiles": [
		"tally.go"
	],
	"Imports": [
		"bufio",
		"cmp",
		"fmt",
		"io",
		"slices",
		"strconv",
		"strings",
		"time"
	]
}
```

`.Name` is the package clause and `.ImportPath` the path other packages import it by, which is why
two packages here are both called `main`. **The test files are kept apart in two lists**:
`main_test.go` is in `TestGoFiles` because it says `package main`, and `tally_test.go` is in
`XTestGoFiles` because it says `package tally_test`. `-json` prints the whole structure, and with a
list of field names it prints only those, which is the form a script reads. `.Dir` is
where the package lives on disk, the answer to "which copy of this package is being built" when a
module cache or a `replace` is involved.

`-deps` widens the list from the packages named to everything they import, directly or not:

```
ana@vm:~/daily$ go list -deps . | wc -l
80
ana@vm:~/daily$ go list -deps -f "{{if not .Standard}}{{.ImportPath}}{{end}}" .
example.com/hits/internal/tally
example.com/hits
```

**80 packages go into `hits`, and 78 of them are the standard library.** That is one more than the
79 `go build -a -v` compiled in section 02. The extra one is `unsafe`, which the compiler provides
itself and never compiles. A template that prints nothing for a package leaves no line, so the
`if` reduces the list to this module's own two. The order is the order of the build: a package
always comes after everything it imports.

`-m` switches from packages to modules:

```
ana@vm:~/daily$ go list -m all
example.com/hits
ana@vm:~/daily$ go list -m -f "{{.Path}} {{.GoVersion}} {{.Dir}}"
example.com/hits 1.27.1 /home/ana/daily
```

`go list -m all` is the module graph the build uses, and for `hits` it is one line, because `hits`
requires nothing. Installing `stringer` in section 03 did not change that, which is the same fact
as `go.mod` staying untouched. On a module with requirements it prints one module and version per line,
the modules a tool like lesson 9's `govulncheck` has to know about.
