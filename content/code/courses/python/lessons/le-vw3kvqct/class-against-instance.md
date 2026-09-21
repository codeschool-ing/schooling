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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Reading an attribute looks at the instance first and then at the class, so an instance with no school of its own finds the class attribute. Writing always lands on the instance: it creates one that shadows the class, and the class attribute never moves.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"177\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">reading ada.school</text> <rect x=\"20\" y=\"36\" width=\"314\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"177\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Student: school = &quot;codeschool&quot;</text> <rect x=\"50\" y=\"136\" width=\"254\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"177\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">ada: name</text> <path d=\"M177 130 L177 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"187\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">not on the instance, so the lookup goes up</text> <text x=\"543\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">after ada.school = &quot;another&quot;</text> <rect x=\"386\" y=\"36\" width=\"314\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"543\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Student: school = &quot;codeschool&quot;</text> <rect x=\"416\" y=\"136\" width=\"254\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"543\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">ada: name, school = &quot;another&quot;</text> <text x=\"543\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">found on the instance, so the lookup stops here</text> <text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and Student.school is still &quot;codeschool&quot;</text> </svg>", "caption": "Reading goes instance first, then class. Writing always lands on the instance — and that asymmetry is where the confusion lives."}
```

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
