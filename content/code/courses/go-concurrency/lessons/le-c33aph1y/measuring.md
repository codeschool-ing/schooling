---
title: Which lines the tests ran
version: 1
---

Five lessons of tests later, a fair question is what they leave out. **Coverage is the share of
the code's statements that ran at least once while the tests ran**, and `go test` measures it
with one flag. The compiler rewrites the package with a counter on every block of statements,
runs the tests, and reports which counters moved.

## The number, then the map

```
ana@vm:~/wordcount$ go test -cover
PASS
coverage: 93.4% of statements
ok  	example.com/wordcount	0.067s
```

One number for the whole package. It says how much, not where, and the where is what a person can
act on. `-coverprofile` writes the counters to a file, and `go tool cover` reads it, here one line
per function:

```
ana@vm:~/wordcount$ go test -coverprofile=c.out
PASS
coverage: 93.4% of statements
ok  	example.com/wordcount	0.062s
ana@vm:~/wordcount$ go tool cover -func=c.out
example.com/wordcount/file.go:6:	CountFile	100.0%
example.com/wordcount/fssource.go:14:	Open		100.0%
example.com/wordcount/handler.go:13:	Handler		86.7%
example.com/wordcount/httpsource.go:18:	Open		91.7%
example.com/wordcount/source.go:16:	TopOf		87.5%
example.com/wordcount/top.go:17:	Top		100.0%
example.com/wordcount/wordcount.go:13:	Count		100.0%
example.com/wordcount/wordcount.go:26:	notLetter	100.0%
total:					(statements)	93.4%
```

Five functions ran every statement. Three did not, and each missing statement is a branch nobody
asked about. `go tool cover -html=c.out -o cover.html` writes the same profile as a page, the source
of every file coloured green where it ran and red where it did not. Open it in a browser, and the
red lines are these three:

- `Handler`'s `500`: no test made `TopOf` fail with anything but a missing document.
- `TopOf`'s `count %s: %w`: no source handed over a document that failed while being read.
- `HTTPSource.Open`'s check after `http.NewRequestWithContext`: no test gave it a base URL so
  broken that a request could not even be built.

## Closing the gap that matters

The first two are one gap: a document that fails half way through. A disk can do that and so can a
network, and nothing has tested what the package says when it happens. The standard library has
the tool for it in `testing/iotest`, whose `ErrReader` returns an error on its first read. A
`Source` that hands one over, and a test through `Handler`, saved as `readfail_test.go`:

```go
package wordcount

import (
	"context"
	"errors"
	"io"
	"net/http/httptest"
	"testing"
	"testing/iotest"
)

// brokenSource hands over documents that fail on their first read.
type brokenSource struct{}

func (brokenSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	return io.NopCloser(iotest.ErrReader(errors.New("disk read failed"))), nil
}

func TestHandlerReadFails(t *testing.T) {
	rec := httptest.NewRecorder()
	Handler(brokenSource{}).ServeHTTP(rec, httptest.NewRequest("GET", "/top?doc=note&n=2", nil))
	if res := rec.Result(); res.StatusCode != 500 {
		t.Errorf("status %d, want 500", res.StatusCode)
	}
}
```

```
ana@vm:~/wordcount$ go test -coverprofile=c.out
PASS
coverage: 98.4% of statements
ok  	example.com/wordcount	0.061s
ana@vm:~/wordcount$ go tool cover -func=c.out
example.com/wordcount/file.go:6:	CountFile	100.0%
example.com/wordcount/fssource.go:14:	Open		100.0%
example.com/wordcount/handler.go:13:	Handler		100.0%
example.com/wordcount/httpsource.go:18:	Open		91.7%
example.com/wordcount/source.go:16:	TopOf		100.0%
example.com/wordcount/top.go:17:	Top		100.0%
example.com/wordcount/wordcount.go:13:	Count		100.0%
example.com/wordcount/wordcount.go:26:	notLetter	100.0%
total:					(statements)	98.4%
```

`Handler` and `TopOf` reached every statement, and the test asked something real: that a failure
in the middle of a document comes out as a 500 and not as a half-counted answer.

**The third gap stays open, on purpose.** Reaching it needs a base URL that `net/http` refuses to
parse, a configuration mistake that would fail on the first request anybody made, loudly. A test
for it would exercise `net/http`'s parser more than this package. The number stays below 100 and
the reason is written down here. That is the use coverage is for: **a map of what nobody has asked
about yet, read by a person who decides, not a target.** A team that sets a percentage as the
goal gets tests written to move the percentage, and the next section shows what those can miss.
