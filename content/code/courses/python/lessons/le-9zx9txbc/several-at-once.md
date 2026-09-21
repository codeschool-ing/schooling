---
title: Two in one `with`, and the number you do not know
version: 1
---

```python
with open(src, encoding="utf-8") as a, open(dst, "w", encoding="utf-8") as b:
    b.write(a.read())
```

Commas. Both are entered left to right, both are exited right to left, and the second one is not
entered if the first one raises.

## The parenthesised form

```python
with (
    open(src, encoding="utf-8") as a,
    open(dst, "w", encoding="utf-8") as b,
):
    ...
```

Since Python 3.10, which makes a long line readable without a backslash.

## Nesting is the same thing with more indentation

```python
with open(src) as a:
    with open(dst, "w") as b:
```

Identical behaviour. Use the comma form; keep the nesting for when something between the two
lines has to happen.

## `ExitStack`, for the number you do not know

```python
from contextlib import ExitStack

with ExitStack() as stack:
    files = [stack.enter_context(open(p, encoding="utf-8")) for p in paths]
    merge(files)
```

Every file is closed on the way out, in reverse order, however the block ends. This is the answer
when the count comes from the data rather than from the code — and writing it with a `try`/
`finally` and a list is the version that leaks the ones opened before the failure.

`stack.callback(func, arg)` registers an arbitrary undoing, for a thing that has no manager of
its own.

## The order matters

Exits run in reverse, which is what you want: the thing opened last is torn down first, and a
manager can rely on the ones outside it still being alive while it cleans up.
