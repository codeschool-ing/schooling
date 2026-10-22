---
title: Subtests with `t.Run`
version: 1
---

One test function that checks one sentence says little about the edges: capital letters, accents,
an empty text. Writing a separate `TestCountCase`, `TestCountAccents` and so on works, and gives
each a name in the output, but the names are glued to the function and nothing groups them.
**`t.Run` starts a subtest: a named test inside a test, with its own `*testing.T`, its own pass or
fail, and its own line in the report.**

The test file, rewritten as five subtests of `TestCount`, saved as `wordcount_test.go`:

```go
package wordcount

import (
	"strings"
	"testing"
)

func TestCount(t *testing.T) {
	t.Run("punctuation", func(t *testing.T) {
		got, err := Count(strings.NewReader("Go is fun. Go is fast, and go is simple."))
		if err != nil {
			t.Fatalf("Count returned an error: %v", err)
		}
		if got["fun"] != 1 || got["fast"] != 1 {
			t.Errorf(`counts of "fun", "fast" = %d, %d, want 1, 1`, got["fun"], got["fast"])
		}
	})
	t.Run("case", func(t *testing.T) {
		got, err := Count(strings.NewReader("Go GO go gO"))
		if err != nil {
			t.Fatalf("Count returned an error: %v", err)
		}
		if got["go"] != 4 {
			t.Errorf(`count of "go" = %d, want 4`, got["go"])
		}
	})
	t.Run("accents", func(t *testing.T) {
		got, err := Count(strings.NewReader("Ação, ação e AÇÃO."))
		if err != nil {
			t.Fatalf("Count returned an error: %v", err)
		}
		if got["ação"] != 3 {
			t.Errorf(`count of "ação" = %d, want 3`, got["ação"])
		}
	})
	t.Run("possessive", func(t *testing.T) {
		got, err := Count(strings.NewReader("Go and Go's tools"))
		if err != nil {
			t.Fatalf("Count returned an error: %v", err)
		}
		if got["go"] != 2 {
			t.Errorf(`count of "go" = %d, want 2`, got["go"])
		}
	})
	t.Run("empty", func(t *testing.T) {
		got, err := Count(strings.NewReader(""))
		if err != nil || len(got) != 0 {
			t.Errorf(`Count("") = %v, %v; want an empty map and no error`, got, err)
		}
	})
}
```

Each subtest receives a fresh `t`, shadowing the outer one, and every check inside it uses that
one. That is what keeps a failure inside the subtest that found it:

```
ana@vm:~/wordcount$ go test -v
=== RUN   TestCount
=== RUN   TestCount/punctuation
=== RUN   TestCount/case
=== RUN   TestCount/accents
=== RUN   TestCount/possessive
    wordcount_test.go:42: count of "go" = 1, want 2
=== RUN   TestCount/empty
--- FAIL: TestCount (0.00s)
    --- PASS: TestCount/punctuation (0.00s)
    --- PASS: TestCount/case (0.00s)
    --- PASS: TestCount/accents (0.00s)
    --- FAIL: TestCount/possessive (0.00s)
    --- PASS: TestCount/empty (0.00s)
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
```

**A subtest's name is its parent's name, a slash, and the string given to `t.Run`.** Four passed and
one failed, and the parent failed because one of its children did. The failure did not stop
`empty` from running: a subtest that calls `t.Fatalf` ends that subtest and nothing else.

## Running one of them

`-run` takes a regular expression and runs only the tests whose names match it. With a slash in it,
each part is matched against one level of the name, so a single subtest can be run on its own while
you work on it:

```
ana@vm:~/wordcount$ go test -v -run 'TestCount/possessive'
=== RUN   TestCount
=== RUN   TestCount/possessive
    wordcount_test.go:42: count of "go" = 1, want 2
--- FAIL: TestCount (0.00s)
    --- FAIL: TestCount/possessive (0.00s)
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
ana@vm:~/wordcount$ go test -run 'Count/^(case|accents)$'
PASS
ok  	example.com/wordcount	0.009s
```

The second pattern ran two subtests by an expression rather than a full name. The `^` and `$` make
each match the whole name, so `case` does not also catch a future `lowercase`.

## A failure that is a question

The `possessive` subtest failed because `Go's` became the word `go's`: the apostrophe sits inside
the word, and `TrimFunc` only trims the ends. Whether that is a defect depends on what the package
is for, and **the code cannot decide that; somebody has to**. `don't` and `it's` are words in their
own right, and splitting at every apostrophe would turn them into `don` and `t`. This course keeps
the inner apostrophe and counts `go's` as its own word, so the expectation changes rather than the
code. Section 04 shows the test as it ends this lesson, with that decision written into it.
