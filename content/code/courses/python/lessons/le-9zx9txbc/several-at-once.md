---
title: Two in one `with`, and the number you do not know
version: 2
---

```python
with open(src, encoding="utf-8") as a, open(dst, "w", encoding="utf-8") as b:
    b.write(a.read())
```

Commas. Both are entered left to right, both are exited right to left, and the second one is not
entered if the first one raises.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Two context managers on one line are entered left to right and exited right to left, around the body in the middle. If the first one raises on the way in, the second is never entered and never has to be closed.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <rect x=\"150\" y=\"34\" width=\"420\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">enter a</text> <rect x=\"190\" y=\"74\" width=\"340\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">enter b</text> <rect x=\"230\" y=\"114\" width=\"260\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the body</text> <rect x=\"190\" y=\"154\" width=\"340\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">exit b</text> <rect x=\"150\" y=\"194\" width=\"420\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">exit a</text> <text x=\"130\" y=\"66\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">on the way in</text> <text x=\"130\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">on the way out</text> <path d=\"M112 78 L112 156\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">if the first one raises on the way in, the second is never entered at all</text> </svg>", "caption": "In from the left, out from the right — which is the only order that lets the second one use what the first one opened."}
```

## The parenthesised form

```python
with (
    open(src, encoding="utf-8") as a,
    open(dst, "w", encoding="utf-8") as b,
):
    ...
```

Since Python 3.10, which makes a long line readable without a backslash.

## Nesting is the same thing with more indentation

```python
with open(src) as a:
    with open(dst, "w") as b:
```

Identical behaviour. Use the comma form; keep the nesting for when something between the two
lines has to happen.

## `ExitStack`, for the number you do not know

```python
from contextlib import ExitStack

with ExitStack() as stack:
    files = [stack.enter_context(open(p, encoding="utf-8")) for p in paths]
    merge(files)
```

Every file is closed on the way out, in reverse order, however the block ends. This is the answer
when the count comes from the data rather than from the code — and writing it with a `try`/
`finally` and a list is the version that leaks the ones opened before the failure.

`stack.callback(func, arg)` registers an arbitrary undoing, for a thing that has no manager of
its own.

## The order matters

Exits run in reverse, which is what you want: the thing opened last is torn down first, and a
manager can rely on the ones outside it still being alive while it cleans up.
