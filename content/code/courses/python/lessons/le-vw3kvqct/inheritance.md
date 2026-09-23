---
title: Reusing a class, and what `super()` actually does
version: 2
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"A call to a student greeting runs the subclass method, which calls super and runs the parent method first. The parent returns hello Ada, the subclass adds studying python, and the whole string comes back to the caller.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"34\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ada.greet()</text> <rect x=\"294\" y=\"34\" width=\"226\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"407\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Student.greet</text> <rect x=\"294\" y=\"140\" width=\"226\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"407\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Person.greet</text> <path d=\"M226 46 L288 46\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M288 64 L226 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <path d=\"M340 80 L340 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"328\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">super().greet() runs the one above</text> <path d=\"M474 134 L474 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"486\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">&quot;hello, Ada&quot;</text> <text x=\"120\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and hands its answer back</text> <text x=\"120\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&quot;hello, Ada, studying python&quot;</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Leave super() out of __init__ and the parent attributes are never set,</text> <text x=\"360\" y=\"221\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">so the object is incomplete before your own first line runs.</text> </svg>", "caption": "An override replaces the parent unless it calls it. super() is how the chain stays a chain."}
```

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
