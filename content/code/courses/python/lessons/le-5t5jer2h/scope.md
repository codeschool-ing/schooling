---
title: Four places, in a fixed order
version: 1
---

A name is resolved by looking in four places, always in this order:

**L**ocal → **E**nclosing → **G**lobal → **B**uilt-in.

```python
total = 0                 # global (module level)

def outer():
    count = 1             # enclosing, from inner's point of view
    def inner():
        n = 2             # local
        print(n, count, total, len)     # one from each
    inner()
```

The first place that has the name wins, and Python never asks which one you meant.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Four nested boxes. The innermost is the function being run and holds n; around it the enclosing function holds count; around that the module holds total; and outside everything are the built-in names. A name is looked for from the inside out and the first box that has it wins.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"26\" width=\"680\" height=\"164\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"34\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">built-in — len, print, sum</text> <rect x=\"44\" y=\"54\" width=\"632\" height=\"122\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"58\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">global — the module, where total lives</text> <rect x=\"68\" y=\"82\" width=\"584\" height=\"80\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\"></rect> <text x=\"82\" y=\"99\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">enclosing — outer(), where count lives</text> <rect x=\"92\" y=\"110\" width=\"536\" height=\"38\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\"></rect> <text x=\"106\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">local — inner(), where n lives</text> <path d=\"M334 200 L334 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"348\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a name is looked for this way</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">And an assignment ANYWHERE in a function makes that name local for the whole of it,</text> <text x=\"360\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">decided by reading the body before a line of it runs.</text> </svg>", "caption": "Four boxes, always looked in from the inside out. The first one that has the name wins, and nothing asks which one you meant."}
```

## Assignment is what makes a name local

```python
total = 0

def bump():
    total = total + 1     # UnboundLocalError
```

The error is on the read, and the read looks correct. **Python decides that `total` is local by
scanning the function body for an assignment — before running a line of it.** There is one, so
`total` is local everywhere in that body, including on the right of the line that assigns it. The
module's `total` is not consulted.

Reading a global without assigning to it works fine, which is what makes this confusing: the
function was correct until a line was added at the bottom.

## Shadowing a built-in

```python
list = [1, 2, 3]      # now `list(...)` is broken in this scope
```

No error, and nothing says anything. `list`, `dict`, `id`, `type`, `sum`, `input` and `str` are
the ones people take by accident. Add an underscore — `list_` — or pick a better name, which is
usually what the collision was telling you.

## The loop variable is not a scope

```python
for row in rows:
    ...
print(row)        # still here
```

Lesson 4's last mistake, seen from here: a `for`, an `if` and a `while` do not make a scope in
Python. Only a function does — and a module, and a class.
