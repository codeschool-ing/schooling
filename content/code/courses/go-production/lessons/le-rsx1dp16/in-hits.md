---
title: Escape analysis on hits
version: 1
---

Lesson 13 left `tally` making **one allocation per line** of the log, down from two, and the profile
named the remaining one without saying why it was there. The compiler's report says why. Ana sets up
`~/escape-hits` with lesson 1's `tools/genlog/main.go` and `main.go`, lesson 13's
`internal/tally/tally.go` and `internal/tally/split.go`, the module `example.com/hits`, and lesson 12's
log of 100,000 lines in `internal/tally/testdata/access.log`.

## The report for `tally`

`hits` is a program, and section 02's warning applies: the package named on the command line is
`main`, and the code that matters is in a package it imports.

```
ana@vm:~/escape-hits$ go build -gcflags=-m . 2>&1 | grep -c tally/
0
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m' . 2>&1 | grep -c tally/
40
ana@vm:~/escape-hits$ go build -gcflags=all=-m . 2>&1 | wc -l
44067
```

**Nothing about `tally` without a pattern, 40 lines with one, and 44,067 with `all`**, nearly all of
them from the standard library. So the module's pattern, with the inlining lines filtered out:

```
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m' . 2>&1 | grep tally/ | grep -v inlin
internal/tally/split.go:7:13: leaking param: line to result f level=0
internal/tally/tally.go:26:12: leaking param: line
internal/tally/tally.go:31:30: ... argument does not escape
internal/tally/tally.go:31:59: len(all) escapes to heap
internal/tally/tally.go:31:30: &errors.errorString{...} escapes to heap
internal/tally/tally.go:41:29: ... argument does not escape
internal/tally/tally.go:41:29: &errors.errorString{...} escapes to heap
internal/tally/tally.go:60:12: leaking param: r
internal/tally/tally.go:61:36: map[int]int{} escapes to heap
internal/tally/tally.go:61:62: map[string]int{} escapes to heap
internal/tally/tally.go:62:24: &bufio.Scanner{...} does not escape
internal/tally/tally.go:64:26: string(bufio.s.token) escapes to heap
internal/tally/tally.go:66:24: ... argument does not escape
internal/tally/tally.go:66:40: n escapes to heap
internal/tally/tally.go:66:24: &errors.errorString{...} escapes to heap
internal/tally/tally.go:89:29: a does not escape
internal/tally/tally.go:89:32: b does not escape
internal/tally/tally.go:90:16: ... argument does not escape
internal/tally/tally.go:84:10: s does not escape
internal/tally/tally.go:85:14: make([]PathCount, 0, len(s.ByPath)) escapes to heap
internal/tally/tally.go:87:16: append escapes to heap
internal/tally/tally.go:89:24: func literal does not escape
```

Grouped by what they cost:

| lines | verdict | cost |
|---|---|---|
| `split.go:7` | `leaking param: line to result f` | none: lesson 13's array of five strings points into `line` and is a value in `Parse`'s frame |
| `tally.go:31`, `41`, `66` | arguments and errors escape | only on a line that fails to parse, once |
| `tally.go:60` | `leaking param: r` | none per line: `Scan` reads `r` through the `io.Reader` interface, so the compiler cannot see which `Read` runs |
| `tally.go:61` | both maps escape | two per count: they are returned inside the `Summary` |
| `tally.go:62` | `&bufio.Scanner{...} does not escape` | none: `NewScanner` was inlined and the `Scanner` lives in `Count`'s frame |
| `tally.go:64` | `string(bufio.s.token) escapes to heap` | **one per line** |
| `tally.go:85`, `87` | `Top`'s slice escapes | once per `Top`: it is returned |

Line 64 is `e, err := Parse(sc.Text())`. `Scanner.Text` was inlined, so its one statement, the
conversion of the scanner's bytes to a string, is judged in `Count`, and the string escapes. **That is
the allocation per line.** The next question is why.

## Following the reason

```
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A6 'tally.go:64:26: string.* in Count'
internal/tally/tally.go:64:26: string(bufio.s.token) escapes to heap in Count:
internal/tally/tally.go:64:26:   flow: ~r0 ← &{storage for string(bufio.s.token)}:
internal/tally/tally.go:64:26:     from string(bufio.s.token) (spill) at internal/tally/tally.go:64:26
internal/tally/tally.go:64:26:     from ~r0 = string(bufio.s.token) (assign-pair) at internal/tally/tally.go:64:26
internal/tally/tally.go:64:26:   flow: {heap} ← ~r0:
internal/tally/tally.go:64:26:     from Parse(~r0) (call parameter) at internal/tally/tally.go:64:18
internal/tally/tally.go:66:40: n escapes to heap in Count:
```

The string escapes because it is passed to `Parse` and `Parse`'s summary for `line` says the heap,
which is line 26 of the report above: plain `leaking param: line`. So the question moves into
`Parse`:

```
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A2 'line leaks to {heap}'
internal/tally/tally.go:26:12: parameter line leaks to {heap} for Parse with derefs=0:
internal/tally/tally.go:26:12:   flow: {heap} ← line:
internal/tally/tally.go:26:12:     from strings.Fields(line) (call parameter) at internal/tally/tally.go:29:24
```

**`strings.Fields(line)`, on line 29, is the fallback lesson 13 kept for the lines `split5` declines.**
`genlog` writes none of those, and the fallback ran on none of the 100,000 lines. It does not matter:
**escape analysis is about every path the code could take**, decided before any line is read, and
one path that leaks is enough to give every caller's string to the heap.

## Removing a reason shows the next

The obvious experiment is to make the fallback leak nothing: hand `strings.Fields` a copy of the line,
`strings.Clone(line)`, which costs an allocation only on the path that never runs. Ana tries it on a
copy of the file:

```
ana@vm:~/escape-hits$ cp internal/tally/tally.go tally.go.bak
ana@vm:~/escape-hits$ sed -i "s/strings.Fields(line)/strings.Fields(strings.Clone(line))/" internal/tally/tally.go
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A8 'line leaks to {heap}' | grep from
internal/tally/tally.go:26:12:     from split5(line) (call parameter) at internal/tally/tally.go:27:17
internal/tally/tally.go:26:12:     from f, ok := ([5]string)(.autotmp_5), .autotmp_6 (assign-pair) at internal/tally/tally.go:27:8
internal/tally/tally.go:26:12:     from f[4] (fixed-array-index-of) at internal/tally/tally.go:43:32
internal/tally/tally.go:26:12:     from time.ParseDuration(f[4]) (call parameter) at internal/tally/tally.go:43:30
```

`line` still leaks to the heap, by another route: through `split5` into the array `f`, and from
`f[4]` into `time.ParseDuration`, whose summary leaks its argument. **`-m=2` prints one route for each
verdict, the first it finds**, so a second route stays hidden until the first is gone. Cloning that
argument too:

```
ana@vm:~/escape-hits$ sed -i "s/ParseDuration(f\[4\])/ParseDuration(strings.Clone(f[4]))/" internal/tally/tally.go
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep 'leaking param: line'
internal/tally/split.go:7:13: leaking param: line to result f level=0
internal/tally/tally.go:26:12: leaking param: line to result ~r0 level=0
ana@vm:~/escape-hits$ go build -gcflags='example.com/hits/...=-m=2' . 2>&1 | grep -A12 'tally.go:64:26: string.* in Count' | grep from
internal/tally/tally.go:64:26:     from string(bufio.s.token) (spill) at internal/tally/tally.go:64:26
internal/tally/tally.go:64:26:     from ~r0 = string(bufio.s.token) (assign-pair) at internal/tally/tally.go:64:26
internal/tally/tally.go:64:26:     from Parse(~r0) (call parameter) at internal/tally/tally.go:64:18
internal/tally/tally.go:64:26:     from e, err := Entry(.autotmp_8), .autotmp_9 (assign-pair) at internal/tally/tally.go:64:10
internal/tally/tally.go:64:26:     from e.Path (dot) at internal/tally/tally.go:70:13
internal/tally/tally.go:64:26:     from s.ByPath[e.Path] (key of map put) at internal/tally/tally.go:70:11
```

**`Parse` itself is now clean**: `line` leaks only to its result, the `Entry`. And the string in
`Count` escapes anyway, by the third route, the one section 03's `words.go` showed in two lines:
`Parse` returns `Path` as a piece of `line`, and line 70 stores it as a key in `s.ByPath`. **A map keeps
its keys, so the string has to outlive the loop iteration.** The backup goes back:

```
ana@vm:~/escape-hits$ mv tally.go.bak internal/tally/tally.go
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 314\" role=\"img\" aria-label=\"Three routes take each line&#x27;s string from Count to the heap. Count converts the scanner&#x27;s token to a string on line 64 and passes it to Parse. Inside Parse, the fallback strings.Fields on line 29 leaks it, and the compiler reports that route first. Once the fallback clones the line, it reports time.ParseDuration on line 43. Once that is cloned too, it reports the third: Parse returns the path inside the Entry, and Count stores it as a map key on line 70. Even with no route at all, each line is 34 to 51 bytes and a string kept on the stack gets 32.\"><defs><marker id=\"er-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"er-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"er-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"122\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">string(token)</text><text x=\"95\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Count, line 64</text><rect x=\"205\" y=\"122\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Parse(line)</text><text x=\"265\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">line 26</text><rect x=\"370\" y=\"24\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"485\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">strings.Fields(line)</text><text x=\"485\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the fallback, line 29</text><text x=\"485\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reported first</text><path d=\"M325 150 H345 V52 H366\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-phosphor)\"></path><path d=\"M600 52 H615 V150 H626\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-amber)\"></path><rect x=\"370\" y=\"122\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"485\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">time.ParseDuration(f[4])</text><text x=\"485\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the duration, line 43</text><text x=\"485\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reported once 1 is cloned</text><path d=\"M325 150 H345 V150 H366\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-phosphor)\"></path><path d=\"M600 150 H615 V150 H626\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-amber)\"></path><rect x=\"370\" y=\"220\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"485\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">s.ByPath[e.Path]++</text><text x=\"485\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">key of map put, line 70</text><text x=\"485\" y=\"267\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reported once 1 and 2 are cloned</text><path d=\"M325 150 H345 V248 H366\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-phosphor)\"></path><path d=\"M600 248 H615 V150 H626\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-amber)\"></path><rect x=\"630\" y=\"122\" width=\"70\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"665\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{heap}</text><path d=\"M170 150 H201\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#er-phosphor)\"></path><text x=\"20\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">And with no route at all: every line is 34 to 51 bytes, and a string kept on the stack gets 32.</text></svg>", "caption": "Removing one route only shows the next. -m=2 prints the first route it finds, not all of them."}
```

And even with no route left, the allocation would stay:

```
ana@vm:~/escape-hits$ awk '{ print length }' internal/tally/testdata/access.log | sort -n | sed -n '1p;$p'
34
51
```

**Every line of the log is between 34 and 51 bytes.** A string conversion that does not escape gets a
32-byte buffer in the frame, `tmpStringBufSize` in `runtime/string.go`, and anything longer is
allocated on the heap regardless: the same rule as `Sized`, for strings.

## The count, and the verdict

A test measures `Parse` on one line it is handed as a string, and `Count` on the first 1,000 lines
and on all 100,000. `internal/tally/allocs_test.go`:

```go
package tally

import (
	"os"
	"strings"
	"testing"
)

func TestAllocs(t *testing.T) {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		t.Fatal(err)
	}
	text := string(data)
	line, _, _ := strings.Cut(text, "\n")
	short := strings.Join(strings.SplitAfter(text, "\n")[:1000], "")

	t.Logf("Parse, one line:      %v allocs", testing.AllocsPerRun(1000, func() {
		Parse(line)
	}))
	t.Logf("Count, 1,000 lines:   %v allocs", testing.AllocsPerRun(10, func() {
		Count(strings.NewReader(short))
	}))
	t.Logf("Count, 100,000 lines: %v allocs", testing.AllocsPerRun(10, func() {
		Count(strings.NewReader(text))
	}))
}
```

```
ana@vm:~/escape-hits$ go test -run Allocs -v ./internal/tally
=== RUN   TestAllocs
    allocs_test.go:18: Parse, one line:      0 allocs
    allocs_test.go:21: Count, 1,000 lines:   1009 allocs
    allocs_test.go:24: Count, 100,000 lines: 100009 allocs
--- PASS: TestAllocs (0.20s)
PASS
ok  	example.com/hits/internal/tally	0.204s
```

**`Parse` allocates nothing**: lesson 13's `split5`, the time, the status and the duration are all
parsed without touching the heap. `Count` makes 1,009 allocations for 1,000 lines and 100,009 for
100,000, which is one per line plus nine that do not grow with the input, the two maps of line 61
among them. The one per line is the string `Text` makes.

**This is the honest finding: that allocation is necessary for `tally` as it is designed.** `Parse`
takes a string and returns strings that point into it, and `Count` keeps one of those as a map key,
so the line has to be a string on the heap. The ways out change the design. `Count` could read
`sc.Bytes()`, which is the scanner's own buffer and costs nothing, parse the bytes, and copy a path
into a new string only the first time it is seen, eight times in `genlog`'s log. That is a new
`Parse`, a new set of tests and a new fuzz target, to save one small allocation per line. Whether it
is worth it is a question for lesson 13's profile, which measures time, and not for `-m`, which only
explains where the memory comes from.
