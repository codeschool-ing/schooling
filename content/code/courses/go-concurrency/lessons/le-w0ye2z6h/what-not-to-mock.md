---
title: What not to replace
version: 1
---

Section 03 replaced the `Source` because the real ones are slow, need the network or are not
written yet. That is the test for every double: **replace a dependency when the real thing is
slow, flaky, expensive or out of your control, and use the real thing everywhere else.** A double
is code too. It can be wrong, and a test that passes against a wrong double is a test of the
double.

## Real things that are cheap

Most of what a Go function depends on has an implementation in the standard library that costs
nothing to use in a test.

- **A reader is a `strings.Reader`.** Nobody writes a fake `io.Reader`; lessons 25 and 26 counted
  sentences through the real one, and `TopOf`'s fake is a `strings.Reader` with a `Close` added.
- **A writer is a `bytes.Buffer`** or a `strings.Builder`, and the test reads back what was
  written.
- **A file system is an `fs.FS`**, and `testing/fstest.MapFS` is one held in a map, with files,
  directories and modes, that behaves like the one on disk for everything `fs.FS` promises.
- **An HTTP server is an `httptest.Server`**, a real server on a local port, which lesson 28 uses.

The third item on that list deserves a source of its own. Most documents worth counting are
files, and `fs.FS` is the standard library's interface for a tree of them, saved as
`fssource.go`:

```go
package wordcount

import (
	"context"
	"io"
	"io/fs"
)

// FSSource reads documents from a file system, such as os.DirFS("notes").
type FSSource struct{ FS fs.FS }

// Open opens the named file. The context is not used: fs.FS has no way to
// cancel an open.
func (s FSSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	f, err := s.FS.Open(name)
	if err != nil {
		return nil, err
	}
	return f, nil
}
```

An `fs.File` has `Read` and `Close`, so it is already an `io.ReadCloser`. The `if err != nil` is
not ceremony. Returning `s.FS.Open(name)` directly would turn a `nil` `fs.File` into a non-`nil`
`io.ReadCloser` holding a `nil` value, the trap lesson 28 of `go` showed for interfaces, and a
caller checking `rc != nil` would be fooled.

Its test uses no double at all, saved as `fssource_test.go`:

```go
package wordcount

import (
	"errors"
	"io/fs"
	"slices"
	"testing"
	"testing/fstest"
)

func TestFSSource(t *testing.T) {
	src := FSSource{fstest.MapFS{
		"notes/a.txt": {Data: []byte("go go stop")},
	}}
	got, err := TopOf(t.Context(), src, "notes/a.txt", 1)
	if err != nil {
		t.Fatalf("TopOf: %v", err)
	}
	if want := []Entry{{"go", 2}}; !slices.Equal(got, want) {
		t.Errorf("TopOf(notes/a.txt, 1) = %v, want %v", got, want)
	}
	if _, err := TopOf(t.Context(), src, "notes/b.txt", 1); !errors.Is(err, fs.ErrNotExist) {
		t.Errorf("missing file: err = %v, want fs.ErrNotExist", err)
	}
}
```

```
ana@vm:~/wordcount$ go test -v -run FSSource
=== RUN   TestFSSource
--- PASS: TestFSSource (0.00s)
PASS
ok  	example.com/wordcount	0.002s
```

`fstest.MapFS` is not a mock of a file system; it is a file system, kept in memory, and the same
`FSSource` code runs against it in the test and against `os.DirFS` in production. The missing file
gives the same `fs.ErrNotExist` a disk would give, wrapped by `TopOf` with the document's name.

## The rule underneath

Replace what you own the interface of, and only at the edge of your code. `Source` is this
package's interface, so a test may hand it anything. `http.Client`, `os.File` and `sql.DB` are not;
faking them means guessing at behaviour somebody else wrote, and the guess is wrong exactly where
it matters, in the errors and the edge cases. **Put a small interface of your own between your code
and theirs, test your code against doubles of it, and test the real implementation of it against
the real thing**, the way this section did with a file system and lesson 28 does with a server.

```
ana@vm:~/wordcount$ go test
PASS
ok  	example.com/wordcount	0.004s
```
