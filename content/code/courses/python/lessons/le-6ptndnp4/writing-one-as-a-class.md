---
title: The same thing, written twice
version: 1
---

The generator, from earlier:

```python
def countdown(n):
    while n > 0:
        yield n
        n -= 1
```

The same thing as a class:

```python
class Countdown:
    def __init__(self, n):
        self.n = n

    def __iter__(self):
        return self

    def __next__(self):
        if self.n <= 0:
            raise StopIteration
        self.n -= 1
        return self.n + 1
```

## What the class shows

**`self.n` is the state, and the `yield` version keeps the same state in a local variable.** That
is the whole of what a generator does: the function's frame — its locals, its position in the
body — is kept alive between calls, and `__next__` is generated for you.

The `return self` in `__iter__` is what makes the object usable in a `for` loop, and it is also
why this object, like every iterator, is spent after one pass.

## Why the `yield` version wins

- three lines against nine
- the state is where you would look for it, in the body
- the loop is written as a loop rather than turned inside out into a state machine
- there is no `+ 1` to get wrong, which there is above

The class version has a bug shape the generator cannot have: `__next__` has to reconstruct, on
every call, where it was — and the moment there are two loops or a condition in the middle, that
reconstruction is the hard part.

## When a class IS right

```python
class Rows:
    def __init__(self, path): self.path = path
    def __iter__(self):
        with open(self.path, encoding="utf-8") as f:
            yield from f
```

An ITERABLE — `__iter__` fresh each time, so it can be walked twice — with a generator inside it.
That is the shape for something reusable backed by a source you can reopen, and it is the one
place the two ideas are better together than apart.

**Note what it is not: there is no `__next__` here.** `__iter__` is a generator function, so each
call hands back a new generator, and the object itself is never exhausted.
