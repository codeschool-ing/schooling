---
title: A failure message somebody can act on
version: 1
---

A failing test is read by somebody who did not write it, often months later, often in a CI log
with no editor open. **The message has to say what was called, with what, what came back and what
was expected**, in that order. The Go convention is the shape the tables above already use:

```go
t.Errorf("Count(%q) = %v, want %v", tc.text, got, tc.want)
```

The call as it was made, then `=`, then what it returned, then `want` and the expectation. It is
built to be read cold: no line of the test is needed to understand it.

## A second function, and a test that fails sometimes

The package gains the function its name promises, the most frequent words, saved as `top.go`:

```go
package wordcount

import (
	"cmp"
	"slices"
)

// Entry is one word and how many times it appeared.
type Entry struct {
	Word  string
	Count int
}

// Top returns the n most frequent words in counts, most frequent first.
// Words with the same count come in alphabetical order.
func Top(counts map[string]int, n int) []Entry {
	entries := make([]Entry, 0, len(counts))
	for w, c := range counts {
		entries = append(entries, Entry{w, c})
	}
	slices.SortFunc(entries, func(a, b Entry) int { return cmp.Compare(b.Count, a.Count) })
	return entries[:min(n, len(entries))]
}
```

`cmp.Compare(b.Count, a.Count)` puts larger counts first, and the slice is cut to `n`, or to what
there is if there is less. Its test is a table over one set of counts, saved as `top_test.go`:

```go
package wordcount

import (
	"slices"
	"testing"
)

func TestTop(t *testing.T) {
	counts := map[string]int{"go": 3, "is": 3, "fun": 1, "fast": 1, "and": 1}
	tests := []struct {
		name string
		n    int
		want []Entry
	}{
		{"first", 1, []Entry{{"go", 3}}},
		{"ties", 4, []Entry{{"go", 3}, {"is", 3}, {"and", 1}, {"fast", 1}}},
		{"more than there are", 9, []Entry{{"go", 3}, {"is", 3}, {"and", 1}, {"fast", 1}, {"fun", 1}}},
		{"none", 0, []Entry{}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := Top(counts, tc.n)
			if !slices.Equal(got, tc.want) {
				t.Errorf("Top(counts, %d) = %v, want %v", tc.n, got, tc.want)
			}
		})
	}
}
```

```
ana@vm:~/wordcount$ go test -run TestTop
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{is 3} {go 3} {fun 1} {fast 1}], want [{go 3} {is 3} {and 1} {fast 1}]
    --- FAIL: TestTop/more_than_there_are (0.00s)
        top_test.go:24: Top(counts, 9) = [{go 3} {is 3} {fun 1} {fast 1} {and 1}], want [{go 3} {is 3} {and 1} {fast 1} {fun 1}]
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
```

Two of the four rows failed, and each message is the convention at work. Without opening the test,
it says `Top` was asked for 4 entries and for 9, which entries came back and which were expected,
and the eye finds the problem at once: `is` before `go`, `fun` before `and`, words with the same
count in an order nobody chose.

Run twenty times, with `-count=20`, and the failures counted by name, the rows behave differently
from each other:

```
ana@vm:~/wordcount$ go test -run TestTop -count=20 | grep -- '--- FAIL' | sort | uniq -c
      4     --- FAIL: TestTop/first (0.00s)
     20     --- FAIL: TestTop/more_than_there_are (0.00s)
     20     --- FAIL: TestTop/ties (0.00s)
     20 --- FAIL: TestTop (0.00s)
```

`ties` and `more than there are` failed in all twenty runs. **`first` failed in only 4 of the 20**:
a suite holding only that row would have passed most days and failed on the others, with nobody
having changed anything. A test whose result moves between identical runs is telling you the
result depends on something the test does not control. Here it is the order in which `range`
walks a map, which Go randomises on purpose so that nobody comes to rely on it. The documentation
promises alphabetical order for ties and the comparison never looks at the word, so two words with
the same count come out in whatever order the map produced them. Five runs of the `ties` row
alone show the order changing from run to run:

```
ana@vm:~/wordcount$ go test -run 'TestTop/ties' -count=5
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {fast 1} {and 1}], want [{go 3} {is 3} {and 1} {fast 1}]
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {fast 1} {and 1}], want [{go 3} {is 3} {and 1} {fast 1}]
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {fun 1} {fast 1}], want [{go 3} {is 3} {and 1} {fast 1}]
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {fun 1} {fast 1}], want [{go 3} {is 3} {and 1} {fast 1}]
--- FAIL: TestTop (0.00s)
    --- FAIL: TestTop/ties (0.00s)
        top_test.go:24: Top(counts, 4) = [{go 3} {is 3} {and 1} {fun 1}], want [{go 3} {is 3} {and 1} {fast 1}]
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
```

## The fix, and a check that it holds

The comparison breaks ties by the word, as the comment said all along. The whole file again, saved
as `top.go`:

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
// Words with the same count come in alphabetical order.
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
	return entries[:min(n, len(entries))]
}
```

```
ana@vm:~/wordcount$ go test -run TestTop -count=100
PASS
ok  	example.com/wordcount	0.008s
ana@vm:~/wordcount$ go test .
ok  	example.com/wordcount	0.003s
ana@vm:~/wordcount$ go test .
ok  	example.com/wordcount	(cached)
```

A hundred runs, no failure. The last two commands are worth knowing too. Given a package to test,
`.` here, rather than nothing at all, **`go test` caches a passing result and replays it while
neither the code nor the test has changed**, which is why the second run printed `(cached)` and ran
nothing. With no package named it tests the current directory and never caches. Passing `-count` turns the cache off, which is why
`-count=1` is the usual way to force a real run, and the habit to reach for when a test depends on
anything outside the package, a file, a clock, a server.

Two more comparisons sit beside `maps.Equal` and `slices.Equal`. `reflect.DeepEqual` compares any
two values, nested ones included, at the price of the compiler no longer checking that the two
have the same type. For a struct, `==` works when every field is comparable, which is why
`slices.Equal` could compare the `Entry` values directly.
