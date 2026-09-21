---
title: The block is as small as the thing that can fail
version: 1
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
