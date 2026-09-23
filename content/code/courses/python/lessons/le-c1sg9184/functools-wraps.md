---
title: The name the wrapper ate
version: 2
---

```python
@timed
def load_rows(path):
    """Read the rows from a CSV."""

load_rows.__name__      # 'wrapper'
load_rows.__doc__       # None
help(load_rows)         # describes the wrapper
```

The name `load_rows` now refers to the wrapper, and the wrapper's own identity is what everything
sees. **That is not cosmetic** — it is every log line, every traceback frame, and every piece of
documentation, for every function you decorated.

## The fix

```python
import functools

def timed(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        ...
    return wrapper
```

One line. It copies `__name__`, `__doc__`, `__module__`, `__qualname__` and `__dict__` from the
wrapped function onto the wrapper, and sets `__wrapped__` so the original is still reachable.

## What still breaks without it

- a log line that says `wrapper` nine times and does not say which
- `help()` and an editor's tooltip describing the machinery
- `doctest` in lesson 16 finding no docstrings at all
- a test framework that collects by name finding nine functions called `wrapper`
- `pickle` failing on the decorated function, which is a strange afternoon

## What `wraps` does NOT fix

The signature, for anything that inspects it deeply. `inspect.signature` follows `__wrapped__`
and gets it right; some older tools do not, and see `(*args, **kwargs)`.

**That is the honest limit**, and it is rarely the thing that bites. The name and the docstring
are what bite.

## Write it every time

There is no case where a decorator is better without it. Put `@functools.wraps(func)` on the
inner function as you type it, before the body, and it is never the thing you are debugging.
