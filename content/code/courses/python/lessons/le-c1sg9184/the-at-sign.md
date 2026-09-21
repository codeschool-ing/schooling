---
title: `@d` is `f = d(f)`, written above instead of below
version: 1
---

```python
@timed
def load_rows(path):
    ...
```

means exactly:

```python
def load_rows(path):
    ...
load_rows = timed(load_rows)
```

**That is the whole of the `@` symbol.** It is two characters that save one line and put the
information at the top where a reader sees it before the body.

## Both forms, side by side

```python
@timed                          # the name `load_rows` now refers to
def load_rows(path): ...        # whatever `timed` returned

load_rows = timed(load_rows)    # the same rebinding, said out loud
```

The name is rebound. The original function still exists — the wrapper is holding it — but
nothing else can reach it by that name.

## When a decorator confuses you

Write it the second way. `@retry(times=3)` becomes `f = retry(times=3)(f)`, and the two sets of
parentheses stop being mysterious: `retry(times=3)` is called first, and whatever it returns is
called with `f`.

**This is the single most useful trick in this lesson**, and it is why the section exists before
the harder ones.

## It works on classes and methods too

```python
@dataclass
class Student: ...

class Rectangle:
    @property
    def area(self): ...
```

`@dataclass` is `Student = dataclass(Student)`; lesson 6's `@property` is
`area = property(area)` inside the class body. Nothing new is happening — the same rebinding, on
a different kind of object.

## And it is applied at definition

The decorator runs when the `def` runs, not when the function is called. A decorator that prints
something prints it at import, once, which is occasionally a surprise and is usually how a
registry gets filled.
