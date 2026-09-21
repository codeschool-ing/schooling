---
title: `yield`, and the function that pauses
version: 1
---

```python
def countdown(n):
    while n > 0:
        yield n
        n -= 1

for i in countdown(3):
    print(i)          # 3, 2, 1
```

A function with a `yield` anywhere in it is a GENERATOR FUNCTION. Calling it runs none of the
body: it hands back a generator object. Each `next` runs the body until the next `yield`, hands
back that value, and **pauses there** — with `n` and every other local still alive.

## What it replaces

```python
class Countdown:                     # the same thing, by hand
    def __init__(self, n): self.n = n
    def __iter__(self): return self
    def __next__(self):
        if self.n <= 0: raise StopIteration
        self.n -= 1
        return self.n + 1
```

Eight lines against three, and the eight have a place to put a bug. **Anything you would write as
a class holding a position is a generator instead**, and the last section of this lesson writes
one both ways on purpose.

## `return` inside a generator

```python
def take_until_blank(lines):
    for line in lines:
        if not line.strip():
            return            # ends it — no value comes back
        yield line
```

A bare `return` stops the generator, which raises `StopIteration` for the caller. A `return
value` sets the exception's `value` attribute, which almost nothing reads — so treat `return` as
"stop" and yield everything you mean to hand over.

## Yielding from another generator

```python
def both(a, b):
    yield from a
    yield from b
```

`yield from` hands over to another iterable until it is exhausted. It is the same as a `for` loop
with a `yield` in it, and it is shorter and faster.

## The one to watch

```python
def loaded():
    rows = expensive()        # this does NOT run at call time
    for r in rows:
        yield r
```

Nothing in the body happens until the first `next`. That is the whole point, and it is a surprise
when the expensive line was there to fail early — a generator that is never iterated never runs,
and never raises.
