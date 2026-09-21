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
