---
title: One directory, one package
version: 1
---

Every program in this course so far has been one directory with one `package main` in it. Bigger
programs are split, and the habit people bring from other languages is to split by file: a class per
file, a module per file, an `import` naming a file. **In Go the unit is the directory.** Every `.go`
file in a directory belongs to the same package, every name declared in one of them is visible in
the others, and the file names mean nothing to the compiler.

Here is a small module, `example.com/wordy`, with two programs that share a library:

```
ana@vm:~/pkgs$ find . -type f | sort
./cmd/wordcount/main.go
./cmd/wordtop/main.go
./go.mod
./internal/fold/fold.go
./notes.txt
./text/count.go
./text/top.go
ana@vm:~/pkgs$ go run ./cmd/wordcount notes.txt
13 different words
ana@vm:~/pkgs$ go run ./cmd/wordtop notes.txt
go     3
is     3
simple 2
```

Four directories hold Go code, so there are four packages: `cmd/wordcount` and `cmd/wordtop` are
each a `package main`, `text` counts words, and `internal/fold` puts a word into the form `text`
compares. `go run` took a directory, not a file, which is what lesson 4 meant by `go run .`.

## The import path is the module path and the directory

`go list` names the packages of a module, and with a template it says more about each:

```
ana@vm:~/pkgs$ go list ./...
example.com/wordy/cmd/wordcount
example.com/wordy/cmd/wordtop
example.com/wordy/internal/fold
example.com/wordy/text
ana@vm:~/pkgs$ go list -f "{{.ImportPath}}  {{.Name}}  {{.Dir}}" ./text
example.com/wordy/text  text  /home/ana/pkgs/text
```

`./...` means this directory and every one below it. Each **import path is the module path from
`go.mod` followed by the directory**, which is the promise lesson 38 made: rename the module and
every one of these changes. The second command shows the three things a package has, and they are
not the same thing. The import path is what an `import` line writes. The name is what the `package`
clause says, and it is what code writes in front of a dot: `text.Count`. The directory is where the
files are.

The name is usually the last element of the path, and nothing forces it to be:

```
ana@vm:~/pkgs$ go list -f "{{.ImportPath}}  {{.Name}}" math/rand/v2 encoding/json
math/rand/v2  rand
encoding/json  json
```

`math/rand/v2` is the second major version of `math/rand`, with the `/v2` suffix lesson 38 met in
Docker's version, and its files still say `package rand`. A file that imports it writes `rand.N`.

## Two files, one package

`text` is two files. `count.go` declares the type `Counts` and the function `Count`:

```go
// Package text counts the words in a piece of prose.
package text

import (
	"strings"

	"example.com/wordy/internal/fold"
)

// Counts maps each word to the number of times it appears.
type Counts map[string]int

// Count splits s into words and counts each one, ignoring case.
func Count(s string) Counts {
	c := Counts{}
	for _, w := range strings.Fields(s) {
		if w = fold.Word(w); w != "" {
			c[w]++
		}
	}
	return c
}
```

And `top.go` uses `Counts` without importing anything to get it, because it is in the same package:

```go
package text

import (
	"cmp"
	"slices"
)

// Entry is one word and how often it appeared.
type Entry struct {
	Word  string
	Count int
}

// Top returns the n most frequent words, most frequent first.
func (c Counts) Top(n int) []Entry {
	list := c.entries()
	slices.SortFunc(list, byCount)
	return list[:min(n, len(list))]
}

func (c Counts) entries() []Entry {
	list := make([]Entry, 0, len(c))
	for w, n := range c {
		list = append(list, Entry{w, n})
	}
	return list
}

func byCount(a, b Entry) int {
	if d := cmp.Compare(b.Count, a.Count); d != 0 {
		return d
	}
	return cmp.Compare(a.Word, b.Word)
}
```

The method `Top` is declared in a different file from its type, which lesson 25's rule allows: a
method has to be declared in the type's package, and the package is the whole directory. **Imports,
on the other hand, belong to the file.** `top.go` imports `cmp` and `slices` for itself, and
`count.go`'s import of `strings` does nothing for it. The package comment, the one above the package
clause in `count.go`, is written once; `go doc` reads it from whichever file has it.

Since the directory is the package, a second package name in it is refused before anything compiles.
In a copy of the module, `text/words.go` says `package words`:

```
ana@vm:~/pkgs-twonames$ go build ./...
cmd/wordcount/main.go:8:2: found packages text (count.go) and words (words.go) in /home/ana/pkgs-twonames/text
```

The one exception is for test files, which `go help test` describes and the `go-concurrency` course
uses.

## cmd, internal and the graph between them

The layout is a convention, and the Go toolchain's own source follows it. **Each program gets a
directory under `cmd/`, named after the binary it builds**, so one command builds them all, here
into a `bin` directory of the module's own by setting `GOBIN` for the one run:

```
ana@vm:~/pkgs$ GOBIN=~/pkgs/bin go install ./cmd/... && ls bin
wordcount
wordtop
ana@vm:~/pkgs$ ls -d /usr/local/go/src/cmd/go /usr/local/go/src/cmd/gofmt /usr/local/go/src/cmd/vet
/usr/local/go/src/cmd/go
/usr/local/go/src/cmd/gofmt
/usr/local/go/src/cmd/vet
```

The go command you have been typing since lesson 3 was built from `cmd/go`, the same shape. The
packages the programs share sit beside `cmd`, here `text`. And `internal/` holds packages that are
nobody else's business, which section 04 shows the go command enforcing.

`go list` can print what each package imports, and those lines are the whole of the module's
structure:

```
ana@vm:~/pkgs$ go list -f "{{.ImportPath}}: {{join .Imports \" \"}}" ./...
example.com/wordy/cmd/wordcount: example.com/wordy/text fmt os
example.com/wordy/cmd/wordtop: example.com/wordy/text fmt os
example.com/wordy/internal/fold: strings unicode
example.com/wordy/text: cmp example.com/wordy/internal/fold slices strings
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The import graph of the module example.com/wordy, as go list printed it. Two main packages, cmd/wordcount and cmd/wordtop, each import text, and fmt and os from the standard library. text imports internal/fold, and cmp, slices and strings. internal/fold imports strings and unicode and nothing of the module&#x27;s. Every arrow points down, so there is no cycle, and internal/fold can be imported only from inside example.com/wordy.\"><defs><marker id=\"ig-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"468\" height=\"292\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">example.com/wordy</text><text x=\"160\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the module</text><rect x=\"50.0\" y=\"72\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cmd/wordcount</text><text x=\"135\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ fmt os</text><rect x=\"280.0\" y=\"72\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cmd/wordtop</text><text x=\"365\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ fmt os</text><rect x=\"150.0\" y=\"162\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">text</text><text x=\"250\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ cmp slices strings</text><rect x=\"150.0\" y=\"247\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"250\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">internal/fold</text><text x=\"250\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ strings unicode</text><path d=\"M135 108 L215 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ig-phosphor)\"></path><path d=\"M365 108 L285 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ig-phosphor)\"></path><path d=\"M250 198 L250 245\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ig-phosphor)\"></path><path d=\"M484 90 L500 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"508\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">programs: package main</text><path d=\"M484 180 L500 180\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"508\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the library the programs share</text><path d=\"M484 265 L500 265\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"508\" y=\"265\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">only for code inside the module</text><text x=\"508\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">an arrow is an import</text><text x=\"508\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+ ...</text><text x=\"540\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from the standard library</text><text x=\"508\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every arrow points down:</text><text x=\"508\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no cycle</text></svg>", "caption": "The module's four packages and what each imports. An import path is the module path and a directory; the arrows are the lines go list printed."}
```

Drawn out, it is a graph with every arrow pointing one way: programs at the top, `fold` at the
bottom, importing only the standard library. That direction is not tidiness. Section 04 shows that
the go command refuses an arrow pointing back up.
