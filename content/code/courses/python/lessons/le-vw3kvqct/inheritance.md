---
title: Reusing a class, and what `super()` actually does
version: 1
---

```python
class Person:
    def __init__(self, name):
        self.name = name

    def greet(self):
        return f"hello, {self.name}"

class Student(Person):
    def __init__(self, name, course):
        super().__init__(name)      # run Person's __init__ too
        self.course = course

    def greet(self):
        return super().greet() + f", studying {self.course}"
```

`class Student(Person)` says a `Student` is a `Person`. It gets every method `Person` has, and
overriding one is simply defining it again.

## `super()`

`super().greet()` calls the version above this one in the chain. Without it, an override REPLACES
the parent's method entirely — which is sometimes what you want and is almost never what you want
in `__init__`, because the parent's attributes then never get set.

**Call `super().__init__(...)` first, before your own attributes.** Then the object is complete by
the time anything else touches it.

## The method resolution order

```python
Student.__mro__     # (Student, Person, object)
```

A lookup walks that list and takes the first class that has the name. Everything inherits from
`object`, which is where `__str__` and `__eq__` come from before you write your own.

With one parent this is a line. With several it is where the complexity of inheritance lives, and
this course does not go there: **if the answer needs an MRO diagram, composition was the
question.**

## `isinstance`, and when to ask

```python
isinstance(x, Person)      # True for a Student too
type(x) is Person          # False for a Student
```

`isinstance` respects the hierarchy and `type(...) is` does not. Reach for `isinstance` when you
must ask at all — and a chain of `isinstance` checks deciding behaviour is usually a method that
should have been overridden instead.

## When inheritance is right

When the subclass IS the parent in every place the parent is used, and only changes HOW something
is done. A `Student` is a `Person` — every method that takes a `Person` works with one.

**When the subclass has to refuse a parent method** — "a square is a rectangle, but setting its
width has to change its height" — the relationship was not what it looked like. The next section
but one is the alternative.
