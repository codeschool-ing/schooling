---
title: `try`/`finally`, with a name
version: 2
---

```python
with open(path, encoding="utf-8") as f:
    process(f)
```

Three things happen, in order: the SETUP (the file is opened), the BODY, and the TEARDOWN (the
file is closed). The third happens however the second ends.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"Three stages in order: the setup, the body, and the teardown. The body may reach its end, return, break or raise, and every one of those four routes goes through the teardown. An exception then carries on up afterwards.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"180\" y=\"26\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the setup — the file is opened</text> <path d=\"M360 66 L360 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"180\" y=\"88\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the body</text> <rect x=\"24\" y=\"144\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"100\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">it reaches the end</text> <path d=\"M360 128 L100 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <path d=\"M100 180 L360 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"200\" y=\"144\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"276\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">it returns</text> <path d=\"M360 128 L276 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <path d=\"M276 180 L360 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"376\" y=\"144\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"452\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">it breaks</text> <path d=\"M360 128 L452 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <path d=\"M452 180 L360 196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"552\" y=\"144\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"628\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">it raises</text> <path d=\"M360 128 L628 140\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M628 180 L360 196\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"180\" y=\"200\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the teardown — the file is closed</text> <text x=\"700\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the exception carries on up</text> <text x=\"360\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Written out, this is lesson 8: a try with a finally under it.</text> <text x=\"360\" y=\"271\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">What with adds is that nobody has to remember to write the finally.</text> </svg>", "caption": "The teardown is not at the bottom of whoever remembered. It lives beside the setup, in the thing being used."}
```

## The same thing, written out

```python
f = open(path, encoding="utf-8")
try:
    process(f)
finally:
    f.close()
```

That is what `with` does, and lesson 8 wrote it. What the `with` adds is that the teardown lives
beside the setup, in the thing being used, rather than at the bottom of whoever remembered.

## "However the body ends"

- it reaches the end
- it `return`s
- it `break`s or `continue`s out of a loop
- it raises

**In all five the teardown runs.** The exception then carries on upwards, unchanged — the manager
tidied up and did not interfere.

## What that buys, in one sentence

The person USING it cannot forget. `open` without `with` is a `close` somebody has to remember
on every path out of every function, forever; `with` is one line and the problem does not exist.

## Where you have already seen it

```python
with open(path) as f: ...            # lesson 9
with lock: ...                       # a threading lock
with conn: ...                       # a database transaction
with tempfile.TemporaryDirectory() as d: ...
```

Each is the same shape with a different undoing: close, release, commit or roll back, delete.

## And the sentence to carry

**If something has to be undone, the undoing belongs in the thing that did it** — not in a
comment, not in the caller, and not in a `finally` somebody will forget.
