---
title: A real server for a client to call
version: 1
---

Lesson 27 promised a `Source` that fetches documents over HTTP, tested against the real thing. The
real thing does not have to be somebody's production server. **`httptest.NewServer` starts a real
HTTP server, on a free port of `127.0.0.1`, serving whatever handler you give it**, and hands back
its address. The client under test cannot tell it from any other server, because it is not
different from any other server.

## The client

`HTTPSource` turns `Open(ctx, "a.txt")` into `GET <BaseURL>/a.txt`, saved as `httpsource.go`:

```go
package wordcount

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"net/http"
)

// HTTPSource fetches documents from a server: Open(ctx, "a.txt") is
// GET BaseURL/a.txt.
type HTTPSource struct {
	BaseURL string
	Client  *http.Client
}

func (s HTTPSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, s.BaseURL+"/"+name, nil)
	if err != nil {
		return nil, err
	}
	resp, err := s.Client.Do(req)
	if err != nil {
		return nil, err
	}
	switch resp.StatusCode {
	case http.StatusOK:
		return resp.Body, nil
	case http.StatusNotFound:
		resp.Body.Close()
		return nil, fs.ErrNotExist
	default:
		resp.Body.Close()
		return nil, fmt.Errorf("GET %s: %s", req.URL, resp.Status)
	}
}
```

The body is the document, so a 200 hands it over unread and `TopOf`'s `defer` closes it. Every
other status closes the body here, because nobody else will. A 404 becomes `fs.ErrNotExist`, the
same error `FSSource` gives, so a caller handles a missing document the same way wherever it lives,
and `Handler` from section 02 turns it into a 404 of its own.

## The test

The server serves files from a `fstest.MapFS`, through `http.FileServerFS`, the standard library's
file server. A second test uses a handler that fails on every request. Saved as
`httpsource_test.go`:

```go
package wordcount

import (
	"errors"
	"io/fs"
	"net/http"
	"net/http/httptest"
	"slices"
	"strings"
	"testing"
	"testing/fstest"
)

func TestHTTPSource(t *testing.T) {
	srv := httptest.NewServer(http.FileServerFS(fstest.MapFS{
		"a.txt": {Data: []byte("go go stop")},
	}))
	defer srv.Close()
	t.Logf("serving on %s", srv.URL)
	src := HTTPSource{BaseURL: srv.URL, Client: srv.Client()}

	got, err := TopOf(t.Context(), src, "a.txt", 1)
	if err != nil {
		t.Fatalf("TopOf: %v", err)
	}
	if want := []Entry{{"go", 2}}; !slices.Equal(got, want) {
		t.Errorf("TopOf(a.txt, 1) = %v, want %v", got, want)
	}
	if _, err := TopOf(t.Context(), src, "b.txt", 1); !errors.Is(err, fs.ErrNotExist) {
		t.Errorf("missing document: err = %v, want fs.ErrNotExist", err)
	}
}

func TestHTTPSourceServerError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "out of order", http.StatusInternalServerError)
	}))
	defer srv.Close()
	src := HTTPSource{BaseURL: srv.URL, Client: srv.Client()}

	_, err := TopOf(t.Context(), src, "a.txt", 1)
	if err == nil || !strings.Contains(err.Error(), "500 Internal Server Error") {
		t.Errorf("err = %v, want one naming the 500", err)
	}
}
```

```
ana@vm:~/wordcount$ go test -v -run HTTPSource
=== RUN   TestHTTPSource
    httpsource_test.go:19: serving on http://127.0.0.1:40299
--- PASS: TestHTTPSource (0.01s)
=== RUN   TestHTTPSourceServerError
--- PASS: TestHTTPSourceServerError (0.00s)
PASS
ok  	example.com/wordcount	0.015s
```

A real port on the loopback interface, a real request and a real response, in a few milliseconds.
`defer srv.Close()` shuts the server down when the test returns. `srv.Client()` is a client set up
for that server; for a plain `NewServer` it is an ordinary client, and for `NewTLSServer`, the
HTTPS variant, it is one that trusts the test server's certificate.

## Where each tool fits

The recorder of section 02 and the server here answer different questions, and **the side of the
conversation you are testing decides which**:

| you are testing | use | because |
|---|---|---|
| a handler: what it answers | `httptest.NewRecorder` | no port, no goroutine, the response is a value to inspect |
| a client: what it does with answers | `httptest.NewServer` | the client needs a real address to connect to |
| both together, end to end | `httptest.NewServer(Handler(...))` | routing, headers and the wire all in play |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two tests, one for each side of an HTTP conversation. Testing the handler: the test builds a request with httptest.NewRequest, calls ServeHTTP directly, and reads the response from a recorder; no network is involved. Testing the client: the test starts httptest.NewServer on 127.0.0.1, and HTTPSource sends a real request over the loopback network and reads a real response.\"><defs><marker id=\"l28two-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l28two-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">testing the handler</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">testing the client</text><rect x=\"40\" y=\"64\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the test</text><rect x=\"200\" y=\"64\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Handler(src)</text><path d=\"M160 81 H198\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-amber)\"></path><text x=\"180\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">ServeHTTP(rec, req)</text><rect x=\"40\" y=\"170\" width=\"290\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">httptest.NewRecorder → Result()</text><path d=\"M265 98 V168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-phosphor)\"></path><path d=\"M100 168 V100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-phosphor)\"></path><text x=\"185\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a method call, no network</text><rect x=\"390\" y=\"64\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">HTTPSource</text><rect x=\"550\" y=\"64\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">httptest.NewServer</text><rect x=\"550\" y=\"170\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">127.0.0.1:port</text><path d=\"M455 98 C 455 160, 500 187, 548 187\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-phosphor)\"></path><text x=\"510\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">GET /a.txt</text><path d=\"M625 168 V100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-phosphor)\"></path><path d=\"M548 72 H522\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-amber)\"></path><text x=\"536\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">200</text><text x=\"535\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a real connection on the loopback</text></svg>", "caption": "The side you test decides the tool: a handler is called directly; a client needs somebody to connect to."}
```

Neither replaces a test against the real service in some later, slower stage. What they give is a
fast test of your own half of the conversation, run on every change.
