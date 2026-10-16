---
title: Fakes, stubs and spies, written by hand
version: 1
---

The things a test puts in place of a real dependency have names, and the names are worth having
because they say what the double is for. **A stub returns a canned answer. A fake is a working,
simplified implementation. A spy records how it was used, so the test can ask afterwards.** A mock,
in the sense mocking frameworks use, is a spy that was told in advance what calls to expect and
checks them itself. With a one-method interface Go code rarely needs that last kind, and the three
others are a few lines each.

## One of each

The test file for `TopOf`, saved as `source_test.go`:

```schooling-example
{"language": "go", "file": "source_test.go", "parts": [{"code": "package wordcount\n\nimport (\n\t\"context\"\n\t\"errors\"\n\t\"io\"\n\t\"io/fs\"\n\t\"slices\"\n\t\"strings\"\n\t\"testing\"\n)\n\n", "note": "Standard library only. There is no mocking package to import, because each double below is an ordinary type."}, {"code": "// mapSource is a fake: documents held in memory, by name.\ntype mapSource map[string]string\n\nfunc (m mapSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {\n\ttext, ok := m[name]\n\tif !ok {\n\t\treturn nil, fs.ErrNotExist\n\t}\n\treturn io.NopCloser(strings.NewReader(text)), nil\n}\n\n", "note": "**The fake behaves like a real source, just smaller**: a known name gives its text, an unknown one gives `fs.ErrNotExist`, the error a missing file gives. `io.NopCloser` adds a `Close` that does nothing to a plain reader."}, {"code": "// failingSource is a stub: every Open fails with the same error.\ntype failingSource struct{ err error }\n\nfunc (s failingSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {\n\treturn nil, s.err\n}\n\n", "note": "The stub has one canned answer. It exists to drive `TopOf` down its error path on demand, which no real source does reliably."}, {"code": "// spySource records the names it was asked for and every document it\n// handed out, so a test can ask afterwards what happened to them.\ntype spySource struct {\n\tasked []string\n\tdocs  []*spyDoc\n}\n\ntype spyDoc struct {\n\tio.Reader\n\tclosed bool\n}\n\nfunc (d *spyDoc) Close() error { d.closed = true; return nil }\n\nfunc (s *spySource) Open(ctx context.Context, name string) (io.ReadCloser, error) {\n\ts.asked = append(s.asked, name)\n\tdoc := &spyDoc{Reader: strings.NewReader(\"a b a\")}\n\ts.docs = append(s.docs, doc)\n\treturn doc, nil\n}\n\n", "note": "**The spy answers like a fake and also takes notes.** It keeps every document it hands out, and each document remembers whether its `Close` was called, so the test can ask afterwards whether `TopOf` closed what it opened. `spyDoc` embeds the reader and adds that `Close`."}, {"code": "func TestTopOf(t *testing.T) {\n\tctx := t.Context()\n\tsrc := mapSource{\"note\": \"to be or not to be\"}\n\tgot, err := TopOf(ctx, src, \"note\", 2)\n\tif err != nil {\n\t\tt.Fatalf(\"TopOf: %v\", err)\n\t}\n\tif want := []Entry{{\"be\", 2}, {\"to\", 2}}; !slices.Equal(got, want) {\n\t\tt.Errorf(\"TopOf(note, 2) = %v, want %v\", got, want)\n\t}\n}\n\n", "note": "The fake serves the ordinary case. The context is `t.Context()`, from lesson 25, cancelled when the test ends."}, {"code": "func TestTopOfOpenFails(t *testing.T) {\n\tboom := errors.New(\"disk on fire\")\n\t_, err := TopOf(t.Context(), failingSource{boom}, \"note\", 2)\n\tif !errors.Is(err, boom) {\n\t\tt.Errorf(\"TopOf with a failing source: err = %v, want it to wrap %v\", err, boom)\n\t}\n\tif err != nil && !strings.Contains(err.Error(), \"note\") {\n\t\tt.Errorf(\"error %q does not name the document\", err)\n\t}\n}\n\n", "note": "The stub drives the error path. The test asks two things: that the original error survives the wrapping, for `errors.Is`, and that the message names the document."}, {"code": "func TestTopOfClosesTheDocument(t *testing.T) {\n\tspy := &spySource{}\n\tif _, err := TopOf(t.Context(), spy, \"note\", 1); err != nil {\n\t\tt.Fatalf(\"TopOf: %v\", err)\n\t}\n\tif !slices.Equal(spy.asked, []string{\"note\"}) {\n\t\tt.Fatalf(\"opened %v, want [note]\", spy.asked)\n\t}\n\tif !spy.docs[0].closed {\n\t\tt.Error(\"the document was not closed\")\n\t}\n}\n", "note": "**The spy asks about how `TopOf` behaved, not what it returned**: which name it opened, and whether it closed it."}]}
```

```
ana@vm:~/wordcount$ go test -v -run TopOf
=== RUN   TestTopOf
--- PASS: TestTopOf (0.00s)
=== RUN   TestTopOfOpenFails
--- PASS: TestTopOfOpenFails (0.00s)
=== RUN   TestTopOfClosesTheDocument
    source_test.go:84: the document was not closed
--- FAIL: TestTopOfClosesTheDocument (0.00s)
FAIL
exit status 1
FAIL	example.com/wordcount	0.003s
```

**The spy found what nothing else could.** The fake and the stub passed, and the third test says
the document was not closed. Look back at `source.go` in section 02: it opens `rc` and never closes
it. On a file that leaks a descriptor; on an HTTP response it keeps a connection from being reused.
No return value shows it, which is why only a test that watches the call finds it.

The fix is one line, `defer rc.Close()`, straight after the error check. `source.go` with it,
saved as `source.go`:

```go
package wordcount

import (
	"context"
	"fmt"
	"io"
)

// A Source hands over the text of a document, by name.
type Source interface {
	Open(ctx context.Context, name string) (io.ReadCloser, error)
}

// TopOf counts the words of the named document in src and returns its n
// most frequent.
func TopOf(ctx context.Context, src Source, name string, n int) ([]Entry, error) {
	rc, err := src.Open(ctx, name)
	if err != nil {
		return nil, fmt.Errorf("open %s: %w", name, err)
	}
	defer rc.Close()
	counts, err := Count(rc)
	if err != nil {
		return nil, fmt.Errorf("count %s: %w", name, err)
	}
	return Top(counts, n), nil
}
```

```
ana@vm:~/wordcount$ go test -run TopOf
PASS
ok  	example.com/wordcount	0.002s
```

## When a spy is the wrong tool

A spy asserts how something was done, and that is a commitment. **Check the calls that are part of
the contract and leave the rest alone.** Closing what you open is a promise every caller relies on.
How many times `Count` reads from the document, or in what size of chunks, is not; a spy that
counted reads would break the day somebody wrapped the reader in a `bufio.Reader`, with nothing
wrong in the code. When a test fails after a change that broke nothing, it has stopped testing
behaviour and started describing the implementation, and its failures teach people to ignore it.
