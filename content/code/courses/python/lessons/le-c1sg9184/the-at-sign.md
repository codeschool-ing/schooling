---
title: `@d` is `f = d(f)`, written above instead of below
version: 1
---

```python
@timed
def load_rows(path):
    ...
```

means exactly:

```python
def load_rows(path):
    ...
load_rows = timed(load_rows)
```

**That is the whole of the `@` symbol.** It is two characters that save one line and put the
information at the top where a reader sees it before the body.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"The at sign does one thing: it rebinds the name. After the decorator runs, the name points at whatever the decorator returned, and the original function is still there — held by the wrapper, and reachable by nothing else.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">@timed</text> <text x=\"360\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">load_rows = timed(load_rows)</text> <text x=\"182\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">before</text> <rect x=\"20\" y=\"88\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">load_rows</text> <path d=\"M182 128 L182 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"20\" y=\"164\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the function you wrote</text> <text x=\"558\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">after</text> <rect x=\"396\" y=\"88\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"558\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">load_rows</text> <path d=\"M558 128 L558 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"396\" y=\"164\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"558\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">what timed() returned</text> <path d=\"M558 204 L558 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"396\" y=\"236\" width=\"324\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"558\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the function you wrote</text> <text x=\"558\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">still there, held by the wrapper</text> </svg>", "caption": "Two characters that save one line and put the information above the body, where a reader meets it first."}
```

## Both forms, side by side

```python
@timed                          # the name `load_rows` now refers to
def load_rows(path): ...        # whatever `timed` returned

load_rows = timed(load_rows)    # the same rebinding, said out loud
```

The name is rebound. The original function still exists — the wrapper is holding it — but
nothing else can reach it by that name.

## When a decorator confuses you

Write it the second way. `@retry(times=3)` becomes `f = retry(times=3)(f)`, and the two sets of
parentheses stop being mysterious: `retry(times=3)` is called first, and whatever it returns is
called with `f`.

**This is the single most useful trick in this lesson**, and it is why the section exists before
the harder ones.

## It works on classes and methods too

```python
@dataclass
class Student: ...

class Rectangle:
    @property
    def area(self): ...
```

`@dataclass` is `Student = dataclass(Student)`; lesson 6's `@property` is
`area = property(area)` inside the class body. Nothing new is happening — the same rebinding, on
a different kind of object.

## And it is applied at definition

The decorator runs when the `def` runs, not when the function is called. A decorator that prints
something prints it at import, once, which is occasionally a surprise and is usually how a
registry gets filled.
