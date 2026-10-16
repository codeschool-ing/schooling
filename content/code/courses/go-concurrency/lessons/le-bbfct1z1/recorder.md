---
title: A handler, tested without a server
version: 1
---

An HTTP handler is a value with one method, `ServeHTTP(w, r)`. **A test can call that method
directly, with a request it built and a writer that records everything written to it**, and no
port, no network and no goroutine are involved. `net/http/httptest` provides both halves:
`NewRequest` builds the request and `NewRecorder` is the writer.

## A handler for the package

`wordcount` gains a handler that answers `GET /top?doc=NAME&n=N` with the document's most frequent
words as JSON, taking its documents from any `Source`, saved as `handler.go`:

```go
package wordcount

import (
	"encoding/json"
	"errors"
	"io/fs"
	"net/http"
	"strconv"
)

// Handler serves GET /top?doc=NAME&n=N: the n most frequent words of the
// named document in src, as JSON.
func Handler(src Source) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		name := r.URL.Query().Get("doc")
		n, err := strconv.Atoi(r.URL.Query().Get("n"))
		if name == "" || err != nil || n < 1 {
			http.Error(w, "want ?doc=NAME&n=N with N at least 1", http.StatusBadRequest)
			return
		}
		top, err := TopOf(r.Context(), src, name, n)
		if errors.Is(err, fs.ErrNotExist) {
			http.Error(w, "no such document", http.StatusNotFound)
			return
		}
		if err != nil {
			http.Error(w, "could not count the document", http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(top)
		w.Header().Set("Content-Type", "application/json")
	})
}
```

The request's own context goes to `TopOf`, as lesson 12 asked, so a client that goes away stops the
work. A missing document is a 404 because `TopOf` wraps the source's error with `%w`, and
`errors.Is` still finds `fs.ErrNotExist` inside it.

## The test

A table again, one row per kind of answer, using the `mapSource` fake from lesson 27, which lives
in the same package's tests. Saved as `handler_test.go`:

```go
package wordcount

import (
	"net/http/httptest"
	"testing"
)

func TestHandler(t *testing.T) {
	h := Handler(mapSource{"note": "to be or not to be"})
	tests := []struct {
		name     string
		target   string
		wantCode int
		wantType string
		wantBody string
	}{
		{"top two", "/top?doc=note&n=2", 200, "application/json",
			`[{"Word":"be","Count":2},{"Word":"to","Count":2}]` + "\n"},
		{"missing doc", "/top?doc=other&n=2", 404, "text/plain; charset=utf-8",
			"no such document\n"},
		{"bad n", "/top?doc=note&n=zero", 400, "text/plain; charset=utf-8",
			"want ?doc=NAME&n=N with N at least 1\n"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", tc.target, nil)
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, req)
			res := rec.Result()
			if got := res.Header.Get("Content-Type"); res.StatusCode != tc.wantCode || got != tc.wantType {
				t.Errorf("GET %s: %d %q, want %d %q", tc.target, res.StatusCode, got, tc.wantCode, tc.wantType)
			}
			if rec.Body.String() != tc.wantBody {
				t.Errorf("GET %s: body %q, want %q", tc.target, rec.Body.String(), tc.wantBody)
			}
		})
	}
}
```

`httptest.NewRequest` takes a path with no host, which is what a handler sees, and panics on
nonsense rather than returning an error, because in a test a bad request is the test's own
mistake. After `ServeHTTP` returns, the recorder holds the body in `Body`, and `Result()` returns
the response as a client would have received it, status and headers included. **Check the headers
on `Result()`, not on `rec.Header()`**: the second is the live map the handler writes into, and it
shows a header set too late as if it had been sent.

```
ana@vm:~/wordcount$ go test -v -run TestHandler
=== RUN   TestHandler
=== RUN   TestHandler/top_two
    handler_test.go:31: GET /top?doc=note&n=2: 200 "text/plain; charset=utf-8", want 200 "application/json"
=== RUN   TestHandler/missing_doc
=== RUN   TestHandler/bad_n
--- FAIL: TestHandler (0.00s)
    --- FAIL: TestHandler/top_two (0.00s)
    --- PASS: TestHandler/missing_doc (0.00s)
    --- PASS: TestHandler/bad_n (0.00s)
FAIL
exit status 1
FAIL	example.com/wordcount	0.003s
```

**The body was right and the content type was wrong.** The handler calls `Header().Set` after
`Encode`, and the first write to a `ResponseWriter` sends the status and the headers as they stand
at that moment. Anything set afterwards is set on a map nobody reads again, so the response went
out labelled with the type `net/http` sniffed from the body. The two error rows passed because
`http.Error` sets its own header before writing.

The fix is to set the header before the body. The handler's last two lines swap places, and the
whole file is saved as `handler.go`:

```go
package wordcount

import (
	"encoding/json"
	"errors"
	"io/fs"
	"net/http"
	"strconv"
)

// Handler serves GET /top?doc=NAME&n=N: the n most frequent words of the
// named document in src, as JSON.
func Handler(src Source) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		name := r.URL.Query().Get("doc")
		n, err := strconv.Atoi(r.URL.Query().Get("n"))
		if name == "" || err != nil || n < 1 {
			http.Error(w, "want ?doc=NAME&n=N with N at least 1", http.StatusBadRequest)
			return
		}
		top, err := TopOf(r.Context(), src, name, n)
		if errors.Is(err, fs.ErrNotExist) {
			http.Error(w, "no such document", http.StatusNotFound)
			return
		}
		if err != nil {
			http.Error(w, "could not count the document", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(top)
	})
}
```

```
ana@vm:~/wordcount$ go test -run TestHandler
PASS
ok  	example.com/wordcount	0.003s
```

A recorder is the right tool for a handler's logic: what it answers to which request. It is not a
server, so it does not exercise routing, timeouts, or what happens on the wire. Section 03 starts a
real one.
