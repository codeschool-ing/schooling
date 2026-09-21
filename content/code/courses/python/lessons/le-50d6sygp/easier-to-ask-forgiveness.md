---
title: Try it, rather than checking first
version: 1
---

Two ways to write the same thing:

```python
# look before you leap
if os.path.exists(path):
    text = open(path).read()

# easier to ask forgiveness than permission
try:
    text = open(path).read()
except FileNotFoundError:
    text = ""
```

The second is the Pythonic one, and the reason is not taste.

## The check has a race in it

Between `exists(path)` and `open(path)` the file can be deleted, renamed or replaced. The check
answered truthfully about a moment that has passed, and the `open` fails anyway — so you needed
the `except` regardless, and the check bought nothing but a second question.

**Anything outside your program — a file, a network, another process — can change between the
check and the use.** The try is the only thing that tests the state at the instant you use it.

## It is also usually faster

The check costs a lookup on every call, and the exception costs only when it happens. For the
common case where it usually works, the try wins — and where it usually fails, the difference
rarely matters.

## Where a check IS better

```python
if not rows:            # asking about your own data
    return 0
```

When the thing you are asking about is yours, in memory, and cannot change under you, an `if` is
clearer. Nobody writes `try: rows[0] except IndexError` to find out whether a list is empty.

The line is: **ask about your own values; try the ones that belong to the world.**

## The one to watch

```python
try:
    value = config["port"]
except KeyError:
    value = 5432
```

Correct, and `config.get("port", 5432)` says it in one line. When the standard library already
has the forgiving version — `.get`, `.pop` with a default, `next(it, None)` — that is the one to
use. Handling the exception is for when there is no such method.
