---
title: What a covered line does not tell you
version: 1
---

A line marked as covered ran at least once during the tests. That is all it says. It does not say
the result was checked, that the line is right for every input, or that two goroutines running it
at once agree. **High coverage is a sign that the tests go everywhere; it is never evidence that
the code is correct there.**

## Covered, and still wrong

`Top` is at 100%. Every one of its statements ran in `TestTop`'s table. One question about it,
asked in a throwaway file, saved as `negative_test.go`:

```go
package wordcount

import "testing"

func TestTopNegative(t *testing.T) {
	got := Top(map[string]int{"go": 1}, -1)
	t.Logf("Top(..., -1) = %v", got)
}
```

```
ana@vm:~/wordcount$ go test -run TestTopNegative
--- FAIL: TestTopNegative (0.00s)
panic: runtime error: slice bounds out of range [:-1] [recovered, repanicked]

goroutine 8 [running]:
testing.tRunner.func1.2({0xbd3a68, 0x16648526e168})
	/usr/local/go/src/testing/testing.go:2123 +0x232
testing.tRunner.func1()
	/usr/local/go/src/testing/testing.go:2126 +0x329
panic({0xbd3a68?, 0x16648526e168?})
	/usr/local/go/src/runtime/panic.go:859 +0x125
example.com/wordcount.Top(0x16648529d720, 0xffffffffffffffff)
	/home/ana/wordcount/top.go:28 +0x1df
example.com/wordcount.TestTopNegative(0x166485386488)
	/home/ana/wordcount/negative_test.go:6 +0xcd
testing.tRunner(0x166485386488, 0xbf1220)
	/usr/local/go/src/testing/testing.go:2193 +0xea
created by testing.(*T).Run in goroutine 1
	/usr/local/go/src/testing/testing.go:2258 +0x4d4
exit status 2
FAIL	example.com/wordcount	0.005s
```

**A panic, in a function with full coverage.** `entries[:min(n, len(entries))]` is a statement the
tests ran many times, with `n` of 0, 1, 4 and 9; with `-1` the same statement slices out of range.
Coverage counts statements reached, not the values they were reached with, and the table never had
a negative row. `Handler` refuses `n` below 1 before it calls `Top`, so the web path is safe; any
other caller of this exported function is not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The values of n that reached Top&#x27;s last statement. TestTop&#x27;s table tried 0, 1, 4 and 9, and the statement was marked as covered after the first of them. The value -1 was never tried, and with it the same statement panics. Coverage records that the statement ran, not which values it ran with.\"><rect x=\"200\" y=\"16\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">entries[:min(n, len(entries))]</text><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one statement, marked covered</text><path d=\"M80 140 H660\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-2</text><path d=\"M128.3 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"128.3\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-1</text><path d=\"M176.7 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"176.7\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M225.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"225.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M273.3 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"273.3\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M321.7 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"321.7\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M370.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"370.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M418.3 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"418.3\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M466.7 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"466.7\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M515.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"515.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><path d=\"M563.3 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"563.3\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M611.7 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"611.7\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><path d=\"M660.0 136 V144\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"680\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">n</text><circle cx=\"176.7\" cy=\"140\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M176.7 132 L360 76\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"225.0\" cy=\"140\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M225.0 132 L360 76\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"370.0\" cy=\"140\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M370.0 132 L360 76\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"611.7\" cy=\"140\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M611.7 132 L360 76\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"128.3\" cy=\"140\" r=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"128.3\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">never tried: panics</text><text x=\"490.8\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">tried by TestTop: covered</text></svg>", "caption": "Coverage marks a statement once it has run; the values it never met are invisible to it."}
```

The fix is a decision about what `Top` promises. A negative `n` asks for nothing, so it returns
nothing, the same as 0. `top.go` with that line, saved as `top.go`:

```go
package wordcount

import (
	"cmp"
	"slices"
	"strings"
)

// Entry is one word and how many times it appeared.
type Entry struct {
	Word  string
	Count int
}

// Top returns the n most frequent words in counts, most frequent first.
// Words with the same count come in alphabetical order. An n below 1
// returns no words.
func Top(counts map[string]int, n int) []Entry {
	entries := make([]Entry, 0, len(counts))
	for w, c := range counts {
		entries = append(entries, Entry{w, c})
	}
	slices.SortFunc(entries, func(a, b Entry) int {
		if c := cmp.Compare(b.Count, a.Count); c != 0 {
			return c
		}
		return strings.Compare(a.Word, b.Word)
	})
	return entries[:max(0, min(n, len(entries)))]
}
```

The throwaway test goes, and its question becomes a row of `TestTop`'s table in the file from
lesson 26: `{"negative", -1, []Entry{}}`, added after the `none` row.

```
ana@vm:~/wordcount$ rm negative_test.go
ana@vm:~/wordcount$ go test -run TestTop -v
=== RUN   TestTopOf
--- PASS: TestTopOf (0.00s)
=== RUN   TestTopOfOpenFails
--- PASS: TestTopOfOpenFails (0.00s)
=== RUN   TestTopOfClosesTheDocument
--- PASS: TestTopOfClosesTheDocument (0.00s)
=== RUN   TestTop
=== RUN   TestTop/first
=== RUN   TestTop/ties
=== RUN   TestTop/more_than_there_are
=== RUN   TestTop/none
=== RUN   TestTop/negative
--- PASS: TestTop (0.00s)
    --- PASS: TestTop/first (0.00s)
    --- PASS: TestTop/ties (0.00s)
    --- PASS: TestTop/more_than_there_are (0.00s)
    --- PASS: TestTop/none (0.00s)
    --- PASS: TestTop/negative (0.00s)
PASS
ok  	example.com/wordcount	0.003s
```

`-run TestTop` also ran the three `TestTopOf` tests, the unanchored pattern lesson 26 warned
about, and every one passed, the new row included. And the coverage of `Top`:

```
ana@vm:~/wordcount$ go test -coverprofile=c.out >/dev/null && go tool cover -func=c.out | grep Top
example.com/wordcount/source.go:16:	TopOf		100.0%
example.com/wordcount/top.go:18:	Top		100.0%
```

Before the fix, `Top` was at 100%; after it, `Top` is still at 100%. **The number never moved, and
the defect came and went underneath it.**

## Three more things a percentage cannot see

- **A check that is missing.** A test that calls a function and asserts nothing covers every line
  it reaches. A suite can have the coverage of a careful one and test almost nothing.
- **A race.** Lesson 1's `count.go` has no branch at all, so one run reaches every statement, and
  it printed the wrong total in four runs out of five. Only `-race` sees that, and
  `go test -race -cover` measures both at once.
- **A case that is not in the code at all.** Coverage measures the code that exists. When the
  defect is a missing `if`, there is no red line to find, because the line was never written. The
  table of lesson 26 and the question "what input have I not tried" find those; coverage does not.
