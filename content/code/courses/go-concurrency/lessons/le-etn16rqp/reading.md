---
title: Reading the numbers, and what to do with them
version: 1
---

One line of the report from section 02, taken apart:

| column | value | what it is |
|---|---|---|
| name | `BenchmarkCount-4` | the benchmark, and the `GOMAXPROCS` it ran with |
| rounds | `10363` | how many times the loop body ran in the measured run |
| time | `113733 ns/op` | nanoseconds per round, the headline number |
| throughput | `81.03 MB/s` | from `b.SetBytes`: bytes per round over time per round |
| memory | `16104 B/op` | bytes allocated per round |
| allocations | `2311 allocs/op` | separate allocations per round |

**The two memory columns are often more stable and more telling than the time.** Time depends on
the processor, its temperature and what else the machine is doing. Allocations depend only on the
code, and every allocation is work for the garbage collector later.

## One run is not a measurement

The same benchmark, five times in a row, with `-count 5`:

```
ana@vm:~/wordcount$ go test -run '^$' -bench Count -benchmem -count 5
goos: linux
goarch: amd64
pkg: example.com/wordcount
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	   12162	     98755 ns/op	  93.32 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkCount-4   	   10000	    101442 ns/op	  90.85 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkCount-4   	   10000	    101035 ns/op	  91.22 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkCount-4   	   10000	    101532 ns/op	  90.77 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkCount-4   	   10000	    101079 ns/op	  91.18 MB/s	   16104 B/op	    2311 allocs/op
PASS
ok  	example.com/wordcount	5.259s
```

The allocations do not move at all. The five times sit between 98,755 and 101,532 nanoseconds,
and the single run of section 02, a minute earlier, said 113,733: more than ten percent slower than
any of these, with nothing changed in between. That spread is the noise floor, and **a change
smaller than the spread between identical runs has not been measured**, however tidy the new number
looks.

## A candidate, measured

2311 allocations for about 9 KB of text is a lot. The sample is 16 words repeated 128 times, 2048
words, so roughly one allocation per word plus a few. Some of them are avoidable on paper: every
`The` and `Go` is lowered by `strings.ToLower`, which builds a new string. A version that lowers
plain ASCII in place and leaves the rest to `strings.ToLower`, saved as `wordcount.go`:

```go
// Package wordcount counts the words in a text.
package wordcount

import (
	"bufio"
	"bytes"
	"io"
	"strings"
	"unicode"
	"unicode/utf8"
)

// Count reads r to the end and returns how many times each word appears.
// Words are compared in lower case, with the punctuation around them removed.
func Count(r io.Reader) (map[string]int, error) {
	counts := make(map[string]int)
	sc := bufio.NewScanner(r)
	sc.Split(bufio.ScanWords)
	for sc.Scan() {
		w := bytes.TrimFunc(sc.Bytes(), notLetter)
		if len(w) == 0 {
			continue
		}
		if lowerASCII(w) {
			counts[string(w)]++
		} else {
			counts[strings.ToLower(string(w))]++
		}
	}
	return counts, sc.Err()
}

func notLetter(r rune) bool { return !unicode.IsLetter(r) && !unicode.IsDigit(r) }

// lowerASCII lowers w in place and reports whether that was enough: at the
// first byte outside ASCII it stops and returns false, and the caller hands
// the word to strings.ToLower instead.
func lowerASCII(w []byte) bool {
	for i, c := range w {
		switch {
		case c >= utf8.RuneSelf:
			return false
		case 'A' <= c && c <= 'Z':
			w[i] = c + 'a' - 'A'
		}
	}
	return true
}
```

**The tests come first**, because a faster wrong answer is worth nothing, and the table of lesson
26 already covers capitals, accents and punctuation. Then the same five runs:

```
ana@vm:~/wordcount$ go test . -count=1
ok  	example.com/wordcount	0.068s
ana@vm:~/wordcount$ go test -run '^$' -bench Count -benchmem -count 5
goos: linux
goarch: amd64
pkg: example.com/wordcount
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	   13570	     88953 ns/op	 103.61 MB/s	   13032 B/op	    2055 allocs/op
BenchmarkCount-4   	   13957	     87509 ns/op	 105.31 MB/s	   13032 B/op	    2055 allocs/op
BenchmarkCount-4   	   12561	     93811 ns/op	  98.24 MB/s	   13032 B/op	    2055 allocs/op
BenchmarkCount-4   	   13279	     89436 ns/op	 103.05 MB/s	   13032 B/op	    2055 allocs/op
BenchmarkCount-4   	   13435	     88568 ns/op	 104.06 MB/s	   13032 B/op	    2055 allocs/op
PASS
ok  	example.com/wordcount	5.992s
```

The allocations fell from 2311 to 2055, by exactly 256: two capitalised words per repetition, 128
repetitions, each of which no longer needs its own lower-case copy. The other 2048 or so are still
there, one per word, because a map key is a string and every word still becomes one. The time fell
too: the new runs sit between 87,509 and 93,811 nanoseconds, the old ones between 98,755 and
101,532. **The two ranges do not overlap, so this difference was measured**, at about a tenth.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Every timing of BenchmarkCount in this lesson on one axis of nanoseconds per round, from 85,000 to 115,000. The candidate&#x27;s five runs sit between 87,509 and 93,811. The original&#x27;s five runs sit between 98,755 and 101,532. The single run of section 02 stands apart at 113,733. The two groups of five do not overlap.\"><text x=\"180\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">candidate, five runs</text><rect x=\"227.8\" y=\"30\" width=\"113.09999999999997\" height=\"20\" rx=\"10\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><circle cx=\"255.9\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"231.8\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"336.9\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"263.9\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"249.5\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"180\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">original, five runs</text><rect x=\"415.2\" y=\"80\" width=\"54.30000000000001\" height=\"20\" rx=\"10\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><circle cx=\"419.2\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"464.0\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"457.2\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"465.5\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"458.0\" cy=\"90\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"180\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one run, section 02</text><circle cx=\"668.9\" cy=\"140\" r=\"4\" fill=\"var(--paper-dim)\"></circle><path d=\"M190 185 H690\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M190.0 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"190.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">85,000</text><path d=\"M273.3 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"273.3\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">90,000</text><path d=\"M356.7 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"356.7\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">95,000</text><path d=\"M440.0 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100,000</text><path d=\"M523.3 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"523.3\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">105,000</text><path d=\"M606.7 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"606.7\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">110,000</text><path d=\"M690.0 181 V189\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"690.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">115,000</text><text x=\"690\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ns/op</text></svg>", "caption": "Each dot is one run. The spread inside a group is the noise; a difference counts when the groups do not overlap."}
```

Measured is not the same as worth keeping. The candidate costs twenty more lines, a second path for
words outside ASCII, and an in-place write into the scanner's buffer that the next reader has to
trust. A tenth off a function that counts 9 KB in a tenth of a millisecond buys nothing until
something shows that counting is where a program spends its time, and nothing here does. So this
course puts it back: `wordcount.go` returns to the version lesson 25 ended with, in its section 02,
and the tests pass on it as before. **The benchmark's job was to turn "this looks faster" into a
number**; deciding what the number is worth is yours, and keeping a measurement while throwing away
the code it judged is an ordinary outcome.
