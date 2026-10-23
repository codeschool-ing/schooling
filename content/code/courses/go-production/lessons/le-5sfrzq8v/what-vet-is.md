---
title: What vet is, and what it promises
version: 1
---

The compiler answers one question: is this a Go program? **`go vet` answers the next one: is it a
Go program that does what its author obviously meant?** It reads the same source the compiler reads,
with the same type information, and looks for code that is legal and almost certainly wrong. A
`Printf` whose verbs do not match its arguments compiles. So does a mutex copied by value, and a
struct tag with a space in the wrong place. Each of them ships, and each of them shows up in
production as a wrong line, a crash or a quiet leak.

Start with something that should be clean. Lesson 1's `hits`, placed in a directory of its own,
`~/vet-hits`, with the four files lesson 1 prints:

```
ana@vm:~/vet-hits$ go vet ./...; echo $?
0
```

**Silence and exit status 0 are what a clean run looks like.** `./...` means every package in the
module, so that covered `main`, `internal/tally` and `tools/genlog`, test files included. Vet prints
nothing when it has nothing to say, which is what lets a script or a CI step run it and read only the
exit code.

## One bug, two answers

The rest of this lesson works in a module of its own, `~/vetted`, made with
`go mod init example.com/vetted`, where each directory holds one small program with one bug in it.
The first is a line any report prints. Save it as `report/main.go`:

```go
// Command report prints one line about a log: how many requests were slow.
package main

import "fmt"

func main() {
	total, slow := 20000, 1873
	share := 100 * float64(slow) / float64(total)
	fmt.Printf("%d of %d requests were slow (%d%%)\n", slow, total, share)
}
```

The compiler accepts it and the program runs. Vet does not accept it:

```
ana@vm:~/vetted$ go run ./report
1873 of 20000 requests were slow (%!d(float64=9.365)%)
ana@vm:~/vetted$ go vet ./report; echo $?
report/main.go:9:43: fmt.Printf format %d has arg share of wrong type float64
1
```

`%!d(float64=9.365)` is `fmt` saying, at run time, that it was handed a `float64` for a verb that
wants an integer. **The compiler cannot see this, because to the compiler the format is just a
string**, and `Printf` takes `...any`, so any argument of any type is legal. Vet knows what `fmt`
does with that string: it parses the format, counts the verbs, and checks each argument's type
against its verb. The message names the file, the line and the column, and the exit status is 1, so
a script that runs `go vet` stops here. The fix is `%.1f%%`, and the place to find it was before the
report reached anybody.

## A set of analyzers, and the bar they clear

Vet is not one check. **It is a driver that runs a suite of independent analyzers over each
package**, each one looking for one class of mistake, and `go tool vet help` lists them. On Go 1.27.1
there are 35:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 318\" role=\"img\" aria-label=\"The 35 analyzers go vet runs on Go 1.27.1, in alphabetical order. Twelve of them are also run by go test before any test: atomic, bools, buildtag, directive, errorsas, ifaceassert, nilfunc, printf, slog, stdversion, stringintconv and tests. The other 23, among them copylocks, lostcancel, structtag, unusedresult, shift, assign and unreachable, run only when go vet is asked for, or under go test -vet=all.\"><rect x=\"20\" y=\"16\" width=\"22\" height=\"16\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"50\" y=\"25\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">also run by go test, before any test: 12</text><rect x=\"370\" y=\"16\" width=\"22\" height=\"16\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"25\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">run only by go vet, or go test -vet=all: 23</text><rect x=\"20\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">appends</text><rect x=\"20\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">asmdecl</text><rect x=\"20\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">assign</text><rect x=\"20\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"82\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">atomic</text><rect x=\"20\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"82\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">bools</text><rect x=\"20\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"82\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">buildtag</text><rect x=\"20\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">cgocall</text><rect x=\"154\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">composites</text><rect x=\"154\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">copylocks</text><rect x=\"154\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">defers</text><rect x=\"154\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"216\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">directive</text><rect x=\"154\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"216\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">errorsas</text><rect x=\"154\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">framepointer</text><rect x=\"154\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">hostport</text><rect x=\"288\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">httpresponse</text><rect x=\"288\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"350\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">ifaceassert</text><rect x=\"288\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">loopclosure</text><rect x=\"288\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">lostcancel</text><rect x=\"288\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"350\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">nilfunc</text><rect x=\"288\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"350\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">printf</text><rect x=\"288\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">shift</text><rect x=\"422\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">sigchanyzer</text><rect x=\"422\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"484\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">slog</text><rect x=\"422\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">stdmethods</text><rect x=\"422\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"484\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">stdversion</text><rect x=\"422\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"484\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">stringintconv</text><rect x=\"422\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">structtag</text><rect x=\"422\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">testinggoroutine</text><rect x=\"556\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"618\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">tests</text><rect x=\"556\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">timeformat</text><rect x=\"556\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">unmarshal</text><rect x=\"556\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">unreachable</text><rect x=\"556\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">unsafeptr</text><rect x=\"556\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">unusedresult</text><rect x=\"556\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">waitgroup</text></svg>", "caption": "The 35 analyzers of go vet on Go 1.27.1. The twelve drawn bold and outlined are the ones go test runs first; seven of the eight bugs in section 03 are found only by the other 23."}
```

Every one of them has cleared the same three-part bar, which the toolchain's own `cmd/vet/README`
writes down, and it is what makes vet different from the linters of lesson 8:

| criterion | what it asks of a check |
|---|---|
| **correctness** | it finds real or potential bugs, never style or a different correct way to write the same thing |
| **frequency** | the mistake is common enough to be worth running on every build everybody does |
| **precision** | false alarms and misses are both rare, so everything it reports is worth reading |

**The third criterion is the reason you can make vet a gate.** A tool that cries wolf gets switched
off; a tool whose every line is worth reading can fail a build. The README is explicit about the
price: many checks have been proposed and rejected, including real bugs that were too rare to be
worth everybody's build time. Lesson 8 is where the tools that make the other trade live.

## An analyzer reads the `go` line

The bar has a consequence that is easy to miss: **an analyzer knows which version of Go a file is
written for**, from the `go` line in `go.mod`, and a check whose bug the language has fixed goes quiet.
`loopclosure` is the clearest case. Before Go 1.22, every iteration of a `for` loop shared one
variable, and a goroutine started in the loop saw whatever value it held when the goroutine got round
to reading it. A module of its own, `~/oldloop`, made with `go mod init example.com/oldloop`, with one
file, `main.go`:

```go
// Command oldloop prints three paths from three goroutines.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	for _, p := range []string{"/", "/login", "/health"} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			fmt.Println(p)
		}()
	}
	wg.Wait()
}
```

`go mod edit -go=1.21` rewrites the `go` line, which tells the compiler to give the file the old loop
semantics, and then the same file again under 1.27.1. The output goes through `sort` because three
goroutines print in whatever order they run:

```
ana@vm:~/oldloop$ go mod edit -go=1.21 && go vet .
main.go:15:16: loop variable p captured by func literal
ana@vm:~/oldloop$ go run . | sort
/health
/health
/health
ana@vm:~/oldloop$ go mod edit -go=1.27.1 && go vet . && go run . | sort
/
/health
/login
```

Under `go 1.21` the three goroutines all printed the last path, and vet had said so before the program
ran. Under `go 1.27.1` each iteration has its own `p`, the program is correct, and **vet says nothing,
because there is nothing left to say**. `loopclosure` is still in the list, still runs, and reports
only in files that declare a Go older than 1.22. The `%w` check in section 03 goes the other way: it
applies only to files that declare at least 1.27.
