---
title: The two shapes that were something else
version: 1
---

Most of this course is not classes. Knowing when not to reach for one is the half of this lesson
that saves the most work.

## The class with one method

```python
class ReportGenerator:
    def __init__(self, rows):
        self.rows = rows

    def generate(self):
        return "\n".join(format_row(r) for r in self.rows)

ReportGenerator(rows).generate()
```

Two lines of ceremony around one function call. `generate_report(rows)` says the same thing, takes
the same argument, and can be tested without constructing anything.

**The tell is a class whose `__init__` takes exactly what its one method needs**, used once and
thrown away. That is a function with extra steps.

## The class with no state

```python
class MathUtils:
    @staticmethod
    def mean(xs): ...
    @staticmethod
    def median(xs): ...
```

A namespace pretending to be a type. In Python the namespace already exists and it is the module:
put the functions in `stats.py` and call `stats.mean(xs)`. **Nothing here is ever instantiated,
which is the giveaway.**

## The class that was a dataclass

Twenty lines of `__init__` assigning six parameters to six attributes of the same name, and no
methods. That is `@dataclass` and six annotations, and the annotations say more than the
assignments did.

## The class that was a dictionary

A class built once, from a file, holding arbitrary keys nobody enumerated. If the fields are not
known at the time you write the code, the shape is a dictionary and lesson 3 already covers it.

## So when IS it a class?

When there is **state** and **operations on that state**, and the two belong together: a
connection you open, use and close; a parser holding a position; an account that can be debited.
The test is whether any method would be worse as a function taking the data as a parameter.

If every one of them would be exactly the same — take the data, return an answer — you have
functions, and they were fine.
