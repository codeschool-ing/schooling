---
title: The same thing, written twice
version: 2
---

The generator, from earlier:

```python
def countdown(n):
    while n > 0:
        yield n
        n -= 1
```

The same thing as a class:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "class Countdown:\n    def __init__(self, n):\n        self.n = n",
      "note": "**`self.n` is the state.** The generator keeps the same number in its local variable `n`."
    },
    {
      "code": "    def __iter__(self):\n        return self",
      "note": "`return self` is what lets a `for` loop use the object, and it is also why the object, like every iterator, is spent after one pass."
    },
    {
      "code": "    def __next__(self):\n        if self.n <= 0:\n            raise StopIteration",
      "note": "**The end has to be announced.** The generator stops by leaving its `while`; the class raises `StopIteration` itself."
    },
    {
      "code": "        self.n -= 1\n        return self.n + 1",
      "note": "**Step down first, then hand back the value from before the step.** That is the `+ 1` the generator never needed."
    }
  ]
}
```

## What the class shows

**Everything the class spells out, the generator gets for free.** Its frame — its locals, its
position in the body — is kept alive between calls, and `__next__` is generated for you.

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
