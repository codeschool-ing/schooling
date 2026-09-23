---
title: The block is as small as the thing that can fail
version: 2
---

```python
try:
    port = int(raw)
except ValueError:
    port = 5432
```

`try` holds the thing that can fail. `except` names the class and says what to do. That is the
whole construct.

## Keep the `try` small

```python
try:                              # NO
    rows = load(path)
    total = sum(r["amount"] for r in rows)
    report(total)
except KeyError:
    ...
```

Three things in the net and one of them is what you meant. The `KeyError` you were expecting was
from `r["amount"]`; the one you just caught might be from inside `report`, three files away — and
you will never know, because the handler is the same.

**Put the `try` around the line that fails**, and nothing else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A try around three lines catches a KeyError from any of them, and the handler cannot tell which. A try around the one line that can fail catches only that one, and the other two are left to fail loudly.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"185\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">the try around everything</text> <rect x=\"20\" y=\"36\" width=\"330\" height=\"90\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-dasharray=\"4 3\"></rect> <text x=\"34\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rows = load(path)</text> <text x=\"34\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total = sum(r[&quot;amount&quot;] for r in rows)</text> <text x=\"34\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">report(total)</text> <path d=\"M110 134 L160 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M260 134 L210 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"20\" y=\"160\" width=\"330\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"185\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">except KeyError:</text> <text x=\"185\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">two failures land here and read identically</text> <text x=\"535\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">the try around the line that fails</text> <rect x=\"370\" y=\"66\" width=\"330\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-dasharray=\"4 3\"></rect> <text x=\"384\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rows = load(path)</text> <text x=\"384\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total = sum(r[&quot;amount&quot;] for r in rows)</text> <text x=\"384\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">report(total)</text> <path d=\"M535 104 L535 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"370\" y=\"160\" width=\"330\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"535\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">except KeyError:</text> <text x=\"535\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">one failure lands here, and it is the one you meant</text> </svg>", "caption": "The handler is the same either way. What differs is how many different failures it answers for."}
```

## Several kinds

```python
except FileNotFoundError:
    ...
except PermissionError:
    ...
except OSError as e:          # anything else from the filesystem
    ...
```

Clauses are tried in order and the FIRST match wins, so the specific ones go first. A base class
above a subclass means the subclass clause is dead code, and Python will not warn you.

## `as e`, and what to do with it

```python
except ValueError as e:
    raise ValueError(f"{path}: port must be a number, not {raw!r}") from e
```

Catching a failure to say something better about it is one of the two good reasons to catch at
all. The other is having an alternative — a default, a second server, a row to skip.

**"Because it might fail" is not a reason.** If the handler does not know what to do, the code
above might, and the traceback certainly does.

## The handler that hides the bug

```python
except Exception:
    pass          # the most expensive two lines in this course
```

`pass` in a handler means: something went wrong, and I have decided nobody needs to know. If a
failure really is safe to ignore, the handler says so in a comment and names the class — and
that comment is what a reader needs six months later.
