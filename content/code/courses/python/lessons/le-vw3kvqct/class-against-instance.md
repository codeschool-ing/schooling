---
title: One copy for everybody, and the trap in it
version: 1
---

```python
class Student:
    school = "codeschool"        # class attribute: one, shared

    def __init__(self, name):
        self.name = name         # instance attribute: one per student
```

`Student.school` exists once. Every instance sees it through the lookup, so `ada.school` works
without `ada` having one of its own.

## Assignment through an instance does not change the class

```python
ada.school = "another"       # creates an INSTANCE attribute that shadows it
Student.school               # still 'codeschool'
```

Reading goes instance first, then class. Writing always lands on the instance. That asymmetry is
the source of most confusion here, and it is the same shape as lesson 5's scope rules.

## The mutable class attribute

```python
class Student:
    grades = []              # ONE list, shared by every student ever made

    def add_grade(self, score):
        self.grades.append(score)     # appends to the shared one
```

This is lesson 5's mutable default in its other costume. `append` does not assign, so it never
creates an instance attribute — it changes the one on the class, and every student now has every
grade. **A mutable class attribute is almost always a bug**; put it in `__init__`.

A constant — a string, a number, a tuple — is the case where a class attribute is right.

## `@classmethod` and `@staticmethod`

```python
class Student:
    @classmethod
    def from_row(cls, row):
        return cls(row["name"])      # cls is the class

    @staticmethod
    def valid_score(n):
        return 0 <= n <= 100
```

A `classmethod` takes the CLASS as its first argument, and its common use is an alternative
constructor — `Student.from_row(row)` reads better than a module-level function that builds one.
Using `cls(...)` rather than `Student(...)` means a subclass gets its own type back.

A `staticmethod` takes neither. It is a plain function that happens to live in the class for
tidiness — and **if it does not touch the class at all, a module-level function was the honest
answer**.
