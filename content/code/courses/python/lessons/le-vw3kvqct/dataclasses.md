---
title: The class that was a name and three fields
version: 1
---

```python
from dataclasses import dataclass

@dataclass
class Student:
    name: str
    city: str
    year: int = 1
```

That writes `__init__`, `__repr__` and `__eq__`. All three, correctly, from the annotations —
and the annotations are the documentation the class needed anyway.

```python
ada = Student("Ada", "Porto")
ada                      # Student(name='Ada', city='Porto', year=1)
ada == Student("Ada", "Porto")     # True
```

Compare that with the twenty lines it replaces, three of which are the ones people get wrong.

## The mutable default, again

```python
from dataclasses import field

@dataclass
class Student:
    name: str
    grades: list = field(default_factory=list)
```

`grades: list = []` is refused outright — the dataclass machinery raises rather than letting
lesson 5's shared-default bug through. `default_factory` is called once per instance, which is
what you wanted.

**This is the one place in Python where that trap is caught for you**, and it is worth noticing
why: the class body is read once, so the mistake is visible to the decorator.

## `frozen=True`

```python
@dataclass(frozen=True)
class Point:
    x: int
    y: int
```

Assignment to a field then raises, and the class gets a `__hash__` — so it can be a dictionary
key and a set member. For a value that should not change after it is made, this is the whole
declaration.

## The annotations are not checked

`name: str` is documentation at runtime — nothing stops `Student(3, 4)`. A type checker reads it
and complains, which is lesson 17. The dataclass only uses the annotation to know that the field
EXISTS.

## When not to

A class with real behaviour, where the fields are an implementation detail, is not a dataclass —
it is a class, and `__init__` written by hand says so. The dataclass is for the case where the
data IS the point, which is most of the time.
