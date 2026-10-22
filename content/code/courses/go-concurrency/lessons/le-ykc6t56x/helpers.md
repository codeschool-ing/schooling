---
title: Helpers, temporary directories and cleanup
version: 1
---

The five subtests of section 03 repeat the same three lines five times: call `Count`, stop if it
returned an error, then check. Moving those lines into a function is ordinary Go. The one thing to
learn is what a failure inside that function reports, because by default it reports the wrong
line.

## `t.Helper`

A throwaway test shows it. The helper checks one count, and the test calls it twice, once with a
count that is right and once with one that is wrong, saved as `demo_test.go`:

```go
package wordcount

import "testing"

func wantCount(t *testing.T, counts map[string]int, word string, want int) {
	if counts[word] != want {
		t.Errorf("count of %q = %d, want %d", word, counts[word], want)
	}
}

func TestDemo(t *testing.T) {
	counts := map[string]int{"go": 2}
	wantCount(t, counts, "go", 2)
	wantCount(t, counts, "fun", 1)
}
```

```
ana@vm:~/wordcount$ go test -run TestDemo
--- FAIL: TestDemo (0.00s)
    demo_test.go:7: count of "fun" = 0, want 1
FAIL
exit status 1
FAIL	example.com/wordcount	0.006s
```

Line 7 is the `t.Errorf` inside the helper, which every call shares, so the report cannot say which
call failed. **`t.Helper()`, as the first line of the helper, tells the testing package to skip
this function when it names a line**, and to name its caller instead. The same file with that one
line added, saved as `demo_test.go`:

```go
package wordcount

import "testing"

func wantCount(t *testing.T, counts map[string]int, word string, want int) {
	t.Helper()
	if counts[word] != want {
		t.Errorf("count of %q = %d, want %d", word, counts[word], want)
	}
}

func TestDemo(t *testing.T) {
	counts := map[string]int{"go": 2}
	wantCount(t, counts, "go", 2)
	wantCount(t, counts, "fun", 1)
}
```

```
ana@vm:~/wordcount$ go test -run TestDemo
--- FAIL: TestDemo (0.00s)
    demo_test.go:15: count of "fun" = 0, want 1
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
ana@vm:~/wordcount$ rm demo_test.go
```

Line 15 is the second call, the one that asked about `fun`. The demonstration file is deleted
straight after, because it fails on purpose.

## A file the test needs, and who removes it

The package gains a second function, for the common case of counting a file on disk, saved as
`file.go`:

```go
package wordcount

import "os"

// CountFile counts the words in the named file.
func CountFile(name string) (map[string]int, error) {
	f, err := os.Open(name)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	return Count(f)
}
```

Testing it needs a real file. Writing it into the package's directory leaves litter after a crash,
and writing it to a fixed path in `/tmp` collides with a second run. **`t.TempDir()` returns a new,
empty directory that belongs to this one test, and removes it when the test ends**, pass or fail.
It does so through `t.Cleanup`, which registers a function to run after the test and its subtests
have finished; you can register your own the same way, for a server to stop or a variable to put
back.

The test file as this lesson leaves it, with both helpers, the `possessive` decision from section
03, and a test of `CountFile`, saved as `wordcount_test.go`:

```go
package wordcount

import (
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// count runs Count on text and stops the test if Count fails.
func count(t *testing.T, text string) map[string]int {
	t.Helper()
	got, err := Count(strings.NewReader(text))
	if err != nil {
		t.Fatalf("Count(%q) returned an error: %v", text, err)
	}
	return got
}

// wantCount reports a failure if word does not appear want times.
func wantCount(t *testing.T, counts map[string]int, word string, want int) {
	t.Helper()
	if counts[word] != want {
		t.Errorf("count of %q = %d, want %d", word, counts[word], want)
	}
}

func TestCount(t *testing.T) {
	t.Run("punctuation", func(t *testing.T) {
		got := count(t, "Go is fun. Go is fast, and go is simple.")
		wantCount(t, got, "fun", 1)
		wantCount(t, got, "fast", 1)
	})
	t.Run("case", func(t *testing.T) {
		wantCount(t, count(t, "Go GO go gO"), "go", 4)
	})
	t.Run("accents", func(t *testing.T) {
		wantCount(t, count(t, "Ação, ação e AÇÃO."), "ação", 3)
	})
	t.Run("possessive", func(t *testing.T) {
		got := count(t, "Go and Go's tools")
		wantCount(t, got, "go", 1)
		wantCount(t, got, "go's", 1)
	})
	t.Run("empty", func(t *testing.T) {
		if got := count(t, ""); len(got) != 0 {
			t.Errorf(`Count("") = %v, want an empty map`, got)
		}
	})
}

func TestCountFile(t *testing.T) {
	dir := t.TempDir()
	t.Logf("working in %s", dir)
	name := filepath.Join(dir, "note.txt")
	if err := os.WriteFile(name, []byte("one two two"), 0o644); err != nil {
		t.Fatal(err)
	}
	got, err := CountFile(name)
	if err != nil {
		t.Fatalf("CountFile: %v", err)
	}
	wantCount(t, got, "two", 2)

	_, err = CountFile(filepath.Join(dir, "missing.txt"))
	if !errors.Is(err, fs.ErrNotExist) {
		t.Errorf("CountFile of a missing file: err = %v, want fs.ErrNotExist", err)
	}
}
```

The missing-file check matters as much as the happy path. `CountFile` returns `os.Open`'s error
untouched, and the test pins that down: a caller may use `errors.Is` with `fs.ErrNotExist`, as
lesson 34 of `go` taught, and a later change that wrapped the error carelessly would fail here.
`t.Logf` writes a line that `go test` shows only with `-v` or when the test fails:

```
ana@vm:~/wordcount$ go test -v
=== RUN   TestCount
=== RUN   TestCount/punctuation
=== RUN   TestCount/case
=== RUN   TestCount/accents
=== RUN   TestCount/possessive
=== RUN   TestCount/empty
--- PASS: TestCount (0.00s)
    --- PASS: TestCount/punctuation (0.00s)
    --- PASS: TestCount/case (0.00s)
    --- PASS: TestCount/accents (0.00s)
    --- PASS: TestCount/possessive (0.00s)
    --- PASS: TestCount/empty (0.00s)
=== RUN   TestCountFile
    wordcount_test.go:56: working in /tmp/TestCountFile3474527985/001
--- PASS: TestCountFile (0.01s)
PASS
ok  	example.com/wordcount	0.010s
ana@vm:~/wordcount$ ls /tmp/TestCountFile3474527985
ls: cannot access '/tmp/TestCountFile3474527985': No such file or directory
```

The directory existed while the test ran and was gone when `go test` returned. Two more methods
on `*testing.T` belong beside these. `t.Setenv` sets an environment variable for one test and puts
it back afterwards. `t.Context` hands the test a context that is cancelled just before its
cleanups run, the thing to pass to code that takes a `ctx`, as lessons 10 and 11 asked.
