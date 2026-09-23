---
title: Two decorators, and two different orders
version: 2
---

```python
@timed
@retry(times=3)
def fetch(url):
    ...
```

is

```python
fetch = timed(retry(times=3)(fetch))
```

**They APPLY from the bottom up**: the one nearest the `def` wraps first, and the one above wraps
that.

**They RUN from the top down**: a call goes into `timed`'s wrapper, which calls `retry`'s
wrapper, which calls `fetch`.

Those are two different orders, and they are both correct at the same time — the outermost
wrapper is the last one applied and the first one entered.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Stacked decorators apply from the bottom up, so the one nearest the def wraps first and ends up innermost. A call then runs from the top down, entering the outermost wrapper first. The last one applied is the first one entered.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <text x=\"182\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">applied, from the bottom up</text> <rect x=\"20\" y=\"36\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">fetch</text> <rect x=\"20\" y=\"94\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">retry(times=3)</text> <path d=\"M182 76 L182 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"20\" y=\"152\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">timed</text> <path d=\"M182 134 L182 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"558\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">entered, from the top down</text> <rect x=\"396\" y=\"36\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">timed</text> <rect x=\"396\" y=\"94\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">retry(times=3)</text> <path d=\"M558 76 L558 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"396\" y=\"152\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">fetch</text> <path d=\"M558 134 L558 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"360\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">With timed on top it measures all three attempts; with retry on top it measures one.</text> <text x=\"360\" y=\"239\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Same two lines, swapped, and the number on the dashboard means something else.</text> </svg>", "caption": "Two orders, both true at once — which is why swapping the two lines changes what the timer measures."}
```

## Which is why the order matters

```python
@timed
@retry(times=3)      # timing measures all three attempts

@retry(times=3)
@timed               # timing measures each attempt separately
```

Same two decorators, different meaning. Neither is wrong; they answer different questions, and
the stack is where the answer is decided.

## The one that is always wrong

```python
@app.route("/rows")
@login_required
def rows(): ...
```

against

```python
@login_required
@app.route("/rows")     # the framework registered the UNPROTECTED function
def rows(): ...
```

A decorator that REGISTERS the function must be outermost, because it registers whatever it is
given — and what it is given is whatever is below it. The second version protects a function
nobody calls and serves one that is not protected.

**This is a real bug shape in web code**, and it is silent.

## And the advice

Two is a stack somebody can read. Three is a stack somebody will get wrong. If the order matters
and is not obvious, a comment beside it costs one line — and a single decorator that does both
things is often the honest answer.
