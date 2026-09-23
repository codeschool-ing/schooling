---
title: Two methods, and what `for` is doing
version: 2
---

```python
it = iter([1, 2, 3])
next(it)      # 1
next(it)      # 2
next(it)      # 3
next(it)      # StopIteration
```

`iter(x)` asks `x` for an iterator by calling its `__iter__`. `next(it)` calls the iterator's
`__next__`. When there is nothing left, `__next__` raises `StopIteration`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"A list is asked for an iterator, and the iterator is what holds the position. Each next moves it forward one place; when there is nothing left it raises StopIteration. The list is unchanged and can be asked for another iterator at any time.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"34\" width=\"190\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"115\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">[1, 2, 3]</text> <path d=\"M216 54 L268 54\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"274\" y=\"34\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"424\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">iter(...)  the position lives here</text> <text x=\"274\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">next(it)</text> <path d=\"M380 96 L430 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"442\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">1</text> <text x=\"274\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">next(it)</text> <path d=\"M380 130 L430 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"442\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">2</text> <text x=\"274\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">next(it)</text> <path d=\"M380 164 L430 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"442\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">3</text> <text x=\"274\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">next(it)</text> <path d=\"M380 198 L430 198\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"442\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">StopIteration</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Ask the list for another iterator and you start again from the front.</text> <text x=\"360\" y=\"253\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Ask a spent iterator for anything and it raises, for ever.</text> </svg>", "caption": "The iterable is the thing; the iterator is the finger on it. Only one of the two moves, and it only moves forward."}
```

## What a `for` loop is

```python
for item in items:
    body(item)
```

is, near enough:

```python
it = iter(items)
while True:
    try:
        item = next(it)
    except StopIteration:
        break
    body(item)
```

**Every surprise in this lesson follows from that.** The loop asks once for an iterator and then
pulls values until the exception — so a second loop over the same ITERATOR gets nothing, and a
second loop over the same LIST gets a fresh iterator and works.

## `StopIteration` is a signal, not an error

It is an exception used for control flow, and the `for` loop swallows it. You will almost never
catch it yourself; `next(it, default)` is the version that returns a default instead of raising,
and it is what you want when asking for one value.

```python
first = next(it, None)
```

## Everything you already use

`range`, `zip`, `enumerate`, `map`, `filter`, a file object, a dictionary's `.items()`, every
generator expression. Some of those are iterators and some produce a fresh one each time — the
next section is that distinction, and it is the one that matters in practice.

## Why the protocol exists

Because `for` then works with anything that implements two methods. A list, a file, a database
cursor, a stream of rows from an API — the loop does not know the difference, and you can write
something new that it also does not know the difference about.
