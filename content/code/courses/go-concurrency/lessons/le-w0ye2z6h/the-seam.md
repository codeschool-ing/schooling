---
title: The seam is a small interface
version: 1
---

So far every function in `wordcount` takes its input whole: a reader, a map. Real code rarely
does. It opens a file, asks a server, reads a bucket in somebody's cloud, and a test that does the
same is slow, needs the network and fails for reasons that have nothing to do with the code. The
usual answer in other languages is a mocking framework. **In Go the answer is a small interface,
declared by the code that needs it**, and a test that hands over its own implementation.

## A function that depends on something

The package gains a function that takes a document by name, counts it and returns its most
frequent words. Where the document comes from is not its business, so it asks for something that
can open one, saved as `source.go`:

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
	counts, err := Count(rc)
	if err != nil {
		return nil, fmt.Errorf("count %s: %w", name, err)
	}
	return Top(counts, n), nil
}
```

**`Source` has one method, and that is a design decision rather than an accident.** A test can
satisfy one method in four lines. An interface copied from a real client, with its twenty methods,
would make every test implement nineteen it never calls. The interface is also declared here, in
the package that uses it, not beside any implementation: Go interfaces are satisfied implicitly,
as lesson 27 of `go` showed, so an HTTP client, a directory on disk and a map in a test can all be
a `Source` without importing this package or knowing it exists.

`ctx` comes first, as lesson 11 asked of every call that may wait. `TopOf` passes it on and never
looks at it; the source that talks to a network will.

## What the seam buys

Everything `TopOf` does besides opening is already tested: `Count` by the table of lesson 26, `Top`
by `TestTop`. What is left is the glue, and the glue has exactly three things that can go wrong. It
can fail to pass the right name, mishandle an error from `Open`, or mishandle the document it was
handed. A test that controls the `Source` controls all three, and section 03 writes one for each.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"TopOf depends on the one-method interface Source, declared in the wordcount package. Three things satisfy it without importing anything from TopOf: the test doubles of section 03, FSSource over a file system in section 04, and an HTTP source in lesson 28.\"><defs><marker id=\"l27seam-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l27seam-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">TopOf(ctx, src, name, n)</text><path d=\"M230 55 H300\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l27seam-amber)\"></path><text x=\"265\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calls</text><rect x=\"302\" y=\"20\" width=\"390\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"497\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">Source: Open(ctx, name) (io.ReadCloser, error)</text><text x=\"497\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one method, declared by the code that needs it</text><rect x=\"30\" y=\"170\" width=\"220\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in the tests: fake, stub, spy</text><text x=\"140\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.8\" fill=\"var(--paper-dim)\">mapSource · failingSource · spySource</text><path d=\"M140 168 L437 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l27seam-phosphor)\"></path><rect x=\"260\" y=\"170\" width=\"220\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a file system, section 04</text><text x=\"370\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.8\" fill=\"var(--paper-dim)\">FSSource{fstest.MapFS / os.DirFS}</text><path d=\"M370 168 L497 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l27seam-phosphor)\"></path><rect x=\"490\" y=\"170\" width=\"220\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a server over HTTP, lesson 28</text><text x=\"600\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.8\" fill=\"var(--paper-dim)\">HTTPSource</text><path d=\"M600 168 L557 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l27seam-phosphor)\"></path><text x=\"360\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each satisfies Source implicitly</text></svg>", "caption": "The seam: TopOf knows a behaviour, not a thing, so a test can hand it anything that behaves."}
```

The reading of this section's code in one sentence: **`TopOf` depends on a behaviour, not on a
thing**, and the behaviour is small enough that a test can provide it. Lesson 28 provides the
other side, a `Source` that fetches over HTTP, and tests it against a real server.
