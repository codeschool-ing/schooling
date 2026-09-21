---
title: Two clauses, and one job each
version: 1
---

```python
try:
    f = open(path)
except FileNotFoundError:
    print(f"no such file: {path}")
else:
    process(f)          # only if the open succeeded
finally:
    print("done")       # either way
```

## `else`

The `else` runs when the `try` did NOT raise. Its job is to keep code out of the `try` that was
never meant to be protected:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"A table of the four clauses against three outcomes. The try body always starts; the except runs only for the class it names; the else runs only when nothing was raised; and the finally runs in all three, including on the way out of the one nobody caught.\"> <text x=\"259\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">nothing raises</text> <text x=\"435\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">a ValueError</text> <text x=\"611\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">a KeyError</text> <rect x=\"21\" y=\"32\" width=\"678\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"31\" y=\"47\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">try:</text> <text x=\"259\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs to the end</text> <text x=\"435\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs to that line</text> <text x=\"611\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs to that line</text> <rect x=\"21\" y=\"68\" width=\"678\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"31\" y=\"83\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">except ValueError:</text> <text x=\"259\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">skipped</text> <text x=\"435\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs</text> <text x=\"611\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">skipped</text> <rect x=\"21\" y=\"104\" width=\"678\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"31\" y=\"119\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">else:</text> <text x=\"259\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs</text> <text x=\"435\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">skipped</text> <text x=\"611\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">skipped</text> <rect x=\"21\" y=\"140\" width=\"678\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"31\" y=\"155\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">finally:</text> <text x=\"259\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs</text> <text x=\"435\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs</text> <text x=\"611\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs</text> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">In the last column the KeyError carries on up after the finally has run.</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">That is the case the finally was written for, and the only one it is needed in.</text> </svg>", "caption": "The finally is the only row with no gap in it — which is the whole reason it exists."}
```

```python
try:
    value = int(raw)
except ValueError:
    ...
else:
    save(value)         # a KeyError in save() is NOT caught above
```

Written inside the `try`, `save(value)` sits in the net — and the day it raises the same class,
the handler answers for the wrong failure. **The `else` is how the `try` stays one line long.**

## `finally`

`finally` runs on every path out of the block: success, a handled exception, an unhandled one,
and even a `return`. It is for cleanup that must happen regardless — closing a file, releasing a
lock, deleting a temporary.

```python
f = open(path)
try:
    process(f)
finally:
    f.close()           # happens even if process() raises
```

**A `try`/`finally` with no `except` is a perfectly ordinary thing to write.** It says: I am not
handling this, and I am still tidying up.

## And `with` writes it for you

```python
with open(path) as f:
    process(f)
```

That is the same guarantee in one line — lesson 9's subject. Anything with a `close`, a lock, a
connection or a transaction has a `with` form, and it exists precisely because everybody forgot
the `finally`.

## The one trap

```python
try:
    return compute()
finally:
    return fallback()        # this return WINS
```

A `return` in the `finally` replaces the one that was on its way out, exception included. It is
legal, it is confusing, and the rule is simple: **never return from a `finally`.**
