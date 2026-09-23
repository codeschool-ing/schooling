---
title: Assignment is a second name, and `copy` is shallow
version: 2
---

This is the section the lesson exists for.

```python
>>> a = [1, 2, 3]
>>> b = a
>>> b.append(4)
>>> a
[1, 2, 3, 4]
```

**`b = a` copied nothing.** One list, two names. This is true of every mutable value — lists,
dictionaries, sets, and the objects you write in lesson 6.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"A shallow copy makes a new outer list whose items still point at the same inner lists, so changing an inner list shows through both names. A deep copy makes new inner lists as well, and the two stop being connected.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"173\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">b = a[:] — a shallow copy</text> <text x=\"547\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">b = deepcopy(a) — a deep copy</text> <rect x=\"20\" y=\"54\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"43\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">a</text> <rect x=\"20\" y=\"138\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"43\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">b</text> <rect x=\"86\" y=\"54\" width=\"112\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"142\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[ . , . ]</text> <rect x=\"86\" y=\"138\" width=\"112\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"142\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[ . , . ]</text> <path d=\"M70 71 L82 71\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M70 155 L82 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"218\" y=\"96\" width=\"108\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"272\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[1, 2]</text> <path d=\"M202 78 L214 106\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M202 148 L214 120\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"394\" y=\"54\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"417\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">a</text> <rect x=\"394\" y=\"138\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"417\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">b</text> <rect x=\"460\" y=\"54\" width=\"112\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"516\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[ . , . ]</text> <rect x=\"460\" y=\"138\" width=\"112\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"516\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[ . , . ]</text> <path d=\"M444 71 L456 71\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M444 155 L456 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"592\" y=\"54\" width=\"108\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"646\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[1, 2]</text> <rect x=\"592\" y=\"138\" width=\"108\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"646\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[1, 2]</text> <path d=\"M576 71 L588 71\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M576 155 L588 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"173\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the SAME inner list</text> <text x=\"547\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">an inner list of its own</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Change a[0][0] after the left-hand copy and b[0][0] changes too.</text> <text x=\"360\" y=\"229\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">After the right-hand one it does not, and that is the only difference.</text> </svg>", "caption": "Every ordinary copy is shallow: the outer list is new and everything inside it is the same object."}
```

It is not a flaw. It is how you hand a million-row table to a function without duplicating it. It
is a surprise exactly once, and then it is a tool.

## Three ways to copy a list

```python
b = a[:]
b = list(a)
b = a.copy()
```

All three do the same thing. For a dictionary, `dict(a)` or `a.copy()`; for a set, `set(a)`.

## They are all shallow

```python
>>> a = [[1, 2], [3, 4]]
>>> b = a.copy()
>>> b[0].append(99)
>>> a
[[1, 2, 99], [3, 4]]
```

The outer list was copied. **The inner lists were not** — both outer lists point at the same two
inner ones. A shallow copy is one level deep, always.

```python
import copy
b = copy.deepcopy(a)
```

`deepcopy` follows the whole structure. It is slower, it handles cycles, and it is the right
answer when you genuinely need an independent tree.

## When it does not matter

**Numbers, strings and tuples cannot be changed**, so sharing one is invisible. That is why you
can pass a string around for a year without ever meeting this.

## How it actually bites

```python
def clean(rows):
    for row in rows:
        row["name"] = row["name"].strip()
    return rows
```

This looks like it returns cleaned rows and leaves the caller's alone. It does not: the
dictionaries are the caller's, and they have been edited. Either say so in the name — `clean_in_place`
— or copy first:

```python
def clean(rows):
    return [{**row, "name": row["name"].strip()} for row in rows]
```

**A function that changes its argument and also returns it** is the shape that hides this. Do one
or the other.
