---
title: Fixed, and therefore usable as a key
version: 2
---

```python
point = (3, 4)
```

Parentheses, and everything a list can hold. What it cannot do is change:

```python
>>> point[0] = 5
TypeError: 'tuple' object does not support item assignment
```

## The comma is what makes it

```python
>>> x = (5)
>>> type(x)
<class 'int'>
>>> x = (5,)
>>> type(x)
<class 'tuple'>
```

**The parentheses are grouping; the comma is the tuple.** `1, 2` is a tuple with no brackets at
all, which is why a function can `return a, b`.

That trailing comma catches everybody once, usually in a call like `f((x,))`.

## Unpacking

```python
>>> x, y = point
>>> a, b = b, a            # swap, with no temporary
>>> first, *rest = [1, 2, 3, 4]
>>> first, rest
(1, [2, 3, 4])
```

This is everywhere in Python. `for name, score in pairs:` is unpacking; so is
`for i, item in enumerate(items):`.

## Why it exists

**A tuple can be a dictionary key and a list cannot**, because a key has to be hashable and
hashable means it cannot change under the dictionary's feet:

```python
>>> grid = {(0, 0): "start", (1, 0): "wall"}
```

**And it says the shape is fixed.** A function returning `(name, score)` is returning two things
that go together; a list would suggest the caller might append a third.

`namedtuple` and `dataclass` in lessons 7 and 6 are the same idea with names on the fields, and
they are what you graduate to when the tuple has more than three.
