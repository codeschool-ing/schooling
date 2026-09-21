---
title: The attribute that is computed, and the one that checks
version: 1
---

```python
class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height

    @property
    def area(self):
        return self.width * self.height

r = Rectangle(3, 4)
r.area          # 12 — no parentheses
```

`@property` makes a method look like an attribute. `r.area` runs the function and gives back its
value.

## Why not just a method

Because `area` is not something the rectangle DOES, it is something it IS. A caller should not
have to remember which of `r.width` and `r.area()` needs parentheses when both are just facts
about the rectangle.

**And it is a change you can make later.** An attribute that starts as plain data can become a
property without one call site changing — which is exactly why Python has no getters and setters
everywhere: you add them on the day you need them.

## The setter, which is where validation goes

```python
class Student:
    @property
    def score(self):
        return self._score

    @score.setter
    def score(self, value):
        if not 0 <= value <= 100:
            raise ValueError(f"score out of range: {value}")
        self._score = value
```

Now `student.score = 150` raises, at the moment the wrong value arrives rather than three
functions later. The real value lives in `self._score` — the underscore says "mine", and the
property is the door.

**The names must differ**, or the setter calls itself. That is the mistake everybody makes once,
and it appears as a `RecursionError`.

## What to keep out of one

A property should be cheap and should not surprise. Reading an attribute that opens a file, makes
a request or takes a second is a property that has lied about what it costs — **that is a method,
with parentheses, so the caller can see the work**.

And it should not change anything. `r.area` that also increments a counter is a fact that moves
when you look at it.
