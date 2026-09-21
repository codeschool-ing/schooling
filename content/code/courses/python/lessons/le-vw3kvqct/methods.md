---
title: Functions that take the instance
version: 1
---

```python
class Student:
    def __init__(self, name):
        self.name = name
        self.grades = []

    def add_grade(self, score):
        self.grades.append(score)

    def average(self):
        if not self.grades:
            return 0
        return sum(self.grades) / len(self.grades)
```

A method is a function defined in the class body whose first parameter is the instance. Beyond
that it is an ordinary function: defaults, `*args`, early return, everything from lesson 5.

## Calling one from another

```python
    def report(self):
        return f"{self.name}: {self.average():.1f}"
```

`self.average()` — through the instance, never by bare name. Writing `average()` inside `report`
looks for a module-level function and raises a `NameError`, which is lesson 5's scope rules
answering exactly as they should.

## Returning a new object rather than changing this one

```python
    def with_city(self, city):
        return Student(self.name, city)      # a new student
```

Two shapes, and the choice is worth making deliberately: a method that CHANGES the instance
returns `None` by convention, and a method that returns a NEW object leaves the original alone.
`list.sort` and `sorted` are that pair in the standard library, and lesson 3 met them.

**Mixing the two in one class is what confuses people** — a class where some methods mutate and
some return copies needs the names to say which is which.

## A method is a function on the class

```python
Student.average            # a plain function
ada.average                # a bound method: the function, with ada attached
```

`ada.average` is the function with `self` already filled in. That is why it can be passed around
like any other value — `sorted(students, key=Student.average)` works, and so does
`map(ada.add_grade, scores)`.
