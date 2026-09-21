---
title: An expression with parameters
version: 1
---

```python
square = lambda x: x * x        # don't
def square(x): return x * x     # do
```

A `lambda` is a function written as one expression. It has parameters, it returns the value of
the expression, and it has no name of its own.

**Assigning one to a name is the case where a `def` is strictly better**: same length, gives the
function a real name for the traceback, and allows a docstring.

## Where it is right

```python
rows.sort(key=lambda r: r["city"])
max(people, key=lambda p: p["score"])
sorted(words, key=lambda w: (len(w), w))
```

Passed straight into something that takes a function, used once, and short enough to read in
place. That is `key=` almost every time — the third example sorts by length and then
alphabetically, and writing it as a named function would put the interesting part on another
line.

## The limits

**It is one expression.** No statement fits inside: no assignment, no `if` statement (the
conditional EXPRESSION is fine), no loop, no `try`. That is not a restriction to work around — it
is the boundary that makes a lambda safe to read in the middle of another line.

## `operator`, for the common ones

```python
from operator import itemgetter
rows.sort(key=itemgetter("city"))
```

`itemgetter` and `attrgetter` say what they do and are a little quicker. Either is fine; the
lambda is more obvious to somebody who has not met `operator`.

## The rule

**If it is longer than the line it sits in, or you want to name it, write a `def`.** A lambda
that has grown to three clauses is a function that is hiding from its own name.
