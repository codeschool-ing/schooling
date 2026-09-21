---
title: Two keywords, and what needing one usually means
version: 1
---

```python
count = 0

def bump():
    global count
    count += 1
```

`global` says the name belongs to the module. Without it the assignment would make `count` local
and the module's value would never move.

```python
def counter():
    n = 0
    def step():
        nonlocal n        # the enclosing function's n, not the module's
        n += 1
        return n
    return step
```

`nonlocal` says the name belongs to the nearest ENCLOSING function. It cannot reach module level,
and if there is no such name the file does not compile — a `SyntaxError`, raised when the module
is read and before a single line of it runs. That is the good failure: a typo in the name is
caught without anybody calling anything.

## Why they are rare

A function that changes a module-level name has an effect its signature does not mention. Two
things follow, and both are ordinary rather than theoretical:

- **its result depends on what ran before it**, so a test has to set the world up and put it back
- **two of them are hard to read together**, because the connection between them is a name in a
  third place

The usual alternative is to take the value and hand it back:

```python
def bump(count):
    return count + 1
```

Now the caller decides what happens to the result, and nothing about the function depends on
history.

## Where `global` is fine

A module-level constant, written once at import and never assigned again, needs no keyword at all
— reading is free. A genuine single-process cache or a registry filled at start-up is the case
where `global` earns its line, and **it deserves a comment saying why**, because the next reader
will assume it was an accident.

`nonlocal` has one home worth knowing: a closure that keeps state between calls, which is the
shape lesson 12 builds decorators from.
