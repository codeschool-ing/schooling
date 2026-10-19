---
title: A test is a Go function the go command calls
version: 1
---

Lessons 1 to 24 checked their programs by running them and reading what they printed. That works
once, while you are looking, and it stops working the day somebody else changes the code. **A test
is a function that runs the code and checks the answer itself**, so the check can be repeated by
anybody, on any machine, in a second. Go needs no framework for it: the `testing` package and the
`go test` command are part of the toolchain the `go` course installed.

Lessons 25 to 30 grow one small package, `example.com/wordcount`, in `~/wordcount`, made by
`go mod init example.com/wordcount`, and test it a little more each lesson. It starts with one
function that reads a text and counts its words, saved as `wordcount.go`:

```go
// Package wordcount counts the words in a text.
package wordcount

import (
	"bufio"
	"io"
	"strings"
)

// Count reads r to the end and returns how many times each word appears,
// compared in lower case.
func Count(r io.Reader) (map[string]int, error) {
	counts := make(map[string]int)
	sc := bufio.NewScanner(r)
	sc.Split(bufio.ScanWords)
	for sc.Scan() {
		counts[strings.ToLower(sc.Text())]++
	}
	return counts, sc.Err()
}
```

It takes an `io.Reader`, the interface of lesson 17, so a file, a network response and a string
can all be counted by the same code. A `bufio.Scanner`, from lesson 18, split by
`bufio.ScanWords` instead of by lines, hands over one word at a time.

## The first test

A test lives in a file whose name ends in `_test.go`, in the same directory and the same package.
`go build` ignores those files and `go test` compiles them in. **A test is any function whose name
starts with `Test`, followed by a capital letter, and whose one parameter is a `*testing.T`.** The
first one counts a sentence whose answer anybody can check by eye, saved as `wordcount_test.go`:

```go
package wordcount

import (
	"strings"
	"testing"
)

func TestCount(t *testing.T) {
	got, err := Count(strings.NewReader("Go is fun. Go is fast, and go is simple."))
	if err != nil {
		t.Fatalf("Count returned an error: %v", err)
	}
	if got["go"] != 3 {
		t.Errorf(`count of "go" = %d, want 3`, got["go"])
	}
	if got["fun"] != 1 {
		t.Errorf(`count of "fun" = %d, want 1`, got["fun"])
	}
	if got["fast"] != 1 {
		t.Errorf(`count of "fast" = %d, want 1`, got["fast"])
	}
}
```

There is no `assert`. A check is an ordinary `if`, and `t.Errorf` records a failure with a message
you write yourself. `strings.NewReader` turns the sentence into a reader, so the test needs no
file. Run from the package's directory, `go test` builds a test binary, runs every `Test` function
in it and reports:

```
ana@vm:~/wordcount$ go test
--- FAIL: TestCount (0.00s)
    wordcount_test.go:17: count of "fun" = 0, want 1
    wordcount_test.go:20: count of "fast" = 0, want 1
FAIL
exit status 1
FAIL	example.com/wordcount	0.003s
```

**The first test found a defect in a function that looked finished.** The sentence says `fun.` and
`fast,`, and `ScanWords` splits on spaces only, so the punctuation stayed on the words and the map
counted `fun.` and `fast,` instead. `go` passed, because none of its three copies touched a full
stop or a comma. Each failure names the file and the line of the `t.Errorf` that reported it, and
the last line says which package failed. `go test` exited with status 1, which is what a script or
a CI job checks.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"What go build and go test each compile. go build takes wordcount.go and leaves wordcount_test.go out. go test takes both, adds a main function the testing package generates, builds a test binary, runs every Test function in it, and turns the results into a report and an exit status.\"><defs><marker id=\"l25gotest-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l25gotest-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"200\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the package directory</text><rect x=\"40\" y=\"62\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">wordcount.go</text><rect x=\"40\" y=\"104\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">wordcount_test.go</text><text x=\"300\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go build</text><path d=\"M200 70 C 250 50, 300 45, 380 45\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25gotest-phosphor)\"></path><rect x=\"380\" y=\"30\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">compiled, result discarded</text><text x=\"300\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">left out</text><path d=\"M205 119 H260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"262\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">go test</text><path d=\"M220 140 C 280 150, 330 185, 378 192\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25gotest-amber)\"></path><rect x=\"20\" y=\"180\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"120\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a generated main</text><path d=\"M220 195 C 280 200, 330 205, 378 205\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25gotest-amber)\"></path><rect x=\"380\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">test binary</text><path d=\"M520 200 H555\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25gotest-amber)\"></path><rect x=\"557\" y=\"160\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">calls every TestXxx</text><rect x=\"557\" y=\"204\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PASS or FAIL, exit 0 or 1</text><path d=\"M632 194 V204\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "go build never sees a _test.go file; go test compiles the package with its tests into a program of its own and runs it."}
```

## Fixing the code, not the test

The test asks the right question, so the code changes. Each word is trimmed of anything that is not
a letter or a digit before it is counted. The whole file again, as `wordcount.go`:

```go
// Package wordcount counts the words in a text.
package wordcount

import (
	"bufio"
	"io"
	"strings"
	"unicode"
)

// Count reads r to the end and returns how many times each word appears.
// Words are compared in lower case, with the punctuation around them removed.
func Count(r io.Reader) (map[string]int, error) {
	counts := make(map[string]int)
	sc := bufio.NewScanner(r)
	sc.Split(bufio.ScanWords)
	for sc.Scan() {
		w := strings.ToLower(strings.TrimFunc(sc.Text(), notLetter))
		if w != "" {
			counts[w]++
		}
	}
	return counts, sc.Err()
}

func notLetter(r rune) bool { return !unicode.IsLetter(r) && !unicode.IsDigit(r) }
```

`strings.TrimFunc` removes runes from both ends while the function says yes, and leaves the inside
alone. The `if w != ""` keeps a lone dash or a stray quote from being counted as an empty word.

```
ana@vm:~/wordcount$ go test
PASS
ok  	example.com/wordcount	0.002s
ana@vm:~/wordcount$ go test -v
=== RUN   TestCount
--- PASS: TestCount (0.00s)
PASS
ok  	example.com/wordcount	0.003s
```

A passing package prints one line. `-v` prints a line as each test starts and another as it ends,
which is worth having when a run is slow and you want to see where it is.

## `Errorf` or `Fatalf`

Both mark the test as failed. **`t.Errorf` lets the function carry on; `t.Fatalf` stops it there.**
The test above uses both on purpose. If `Count` returned an error, the map beside it is not worth
checking, and three more failures about it would only bury the one that matters, so that check is
`Fatalf`. The three counts are independent, and seeing all of them at once is what made the failure
above easy to read: two wrong, one right, so the problem was something `go` did not have.
