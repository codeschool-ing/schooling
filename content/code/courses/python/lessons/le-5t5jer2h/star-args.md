---
title: `*args`, `**kwargs`, and unpacking in both directions
version: 1
---

```python
def total(*prices):
    return sum(prices)

total(10, 20, 30)       # prices is the tuple (10, 20, 30)
```

`*args` collects the positional arguments nobody named into a tuple. `**kwargs` collects the
keyword arguments nobody declared into a dictionary:

```python
def log(message, **fields):
    print(message, fields)

log("saved", rows=12, source="csv")     # fields is {'rows': 12, 'source': 'csv'}
```

The names are convention, not syntax — `*a` works. **Use the conventional names**, because a
reader recognises them at a glance.

## The same stars at the call site

```python
args = [10, 20, 30]
total(*args)                    # three arguments, not one list

options = {"port": 6543, "timeout": 30}
connect("db.example.tld", **options)
```

One star unpacks a sequence into positional arguments; two stars unpack a dictionary into keyword
arguments. **The star means "spread this out" in both places**, which is the one idea worth
carrying — a function collects with it, a call scatters with it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"A star in a definition collects loose positional arguments into one tuple. The same star at a call site scatters one sequence back into loose arguments. It means spread this out in both places.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">def total(*prices) — the function collects</text> <rect x=\"20\" y=\"32\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"49\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">10</text> <rect x=\"90\" y=\"32\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"119\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">20</text> <rect x=\"160\" y=\"32\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"189\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">30</text> <path d=\"M236 49 L300 49\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"306\" y=\"32\" width=\"226\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"419\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">prices = (10, 20, 30)</text> <text x=\"20\" y=\"118\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">total(*args) — the call scatters</text> <rect x=\"20\" y=\"128\" width=\"216\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">args = [10, 20, 30]</text> <path d=\"M242 145 L300 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"306\" y=\"128\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"335\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">10</text> <rect x=\"376\" y=\"128\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"405\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">20</text> <rect x=\"446\" y=\"128\" width=\"58\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"475\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">30</text> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Two stars do the same for names: **fields collects them into a dictionary,</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and connect(**options) scatters a dictionary back into keyword arguments.</text> </svg>", "caption": "One star, two directions: a definition collects with it and a call scatters with it."}
```

## The bare `*`

```python
def charge(account, cents, *, refundable=False, dry_run=False):
    ...

charge(account, 1200, refundable=True)      # fine
charge(account, 1200, True)                 # TypeError
```

Everything after the bare `*` can only be given by name. It is how you make the unreadable call
site impossible rather than merely discouraged, and it is worth reaching for on any function with
two or more booleans.

## When to use them at all

Rarely, and for two shapes:

- a genuine variable number of the same thing — `sum`, `max`, a `join`
- a wrapper that passes its arguments straight through to something else, which is lesson 12's
  decorator

**`def f(*args, **kwargs)` on a function that then reads `args[0]`** is a signature that has
stopped saying what the function takes. The parameters were the documentation, and they have
been replaced with a shrug.
