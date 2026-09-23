---
title: A function is an object, like everything else
version: 2
---

```python
def shout(s): return s.upper()

f = shout          # no parentheses: the function itself
f("ada")           # 'ADA'
```

A function can be assigned, passed, returned and put in a container. Nothing special is
happening — a `def` binds a name to an object, exactly as `=` does.

## Passing one

```python
def apply_to_all(items, fn):
    return [fn(x) for x in items]

apply_to_all(names, str.strip)
```

This is what `key=` has been doing since lesson 3, and what `sorted`, `max`, `map` and `filter`
all take. **The caller decides the behaviour and the function decides the shape.**

## A dictionary of functions

```python
ACTIONS = {
    "start": start,
    "stop":  stop,
    "status": status,
}

ACTIONS[command]()          # KeyError names the unknown command
```

A lookup table of behaviour, and it replaces a chain of `elif` that grows by one branch per
feature. The two things to get right: **the values have no parentheses** — the function, not its
result — and a missing key is an error you handle rather than a silent nothing.

## Returning one

```python
def multiplier(n):
    def multiply(x):
        return x * n        # n comes from the enclosing scope
    return multiply

double = multiplier(2)
double(5)                   # 10
```

`multiply` remembers `n` after `multiplier` has returned. That is a CLOSURE, it is the
`nonlocal` machinery from two sections ago, and it is the single idea lesson 12 builds decorators
out of.

## Why this matters before lesson 12

Every framework you will meet does this: you write a function and hand it over, and something
else decides when to call it. A route handler, a test, a callback, a `key=`. **The moment a
function is a value, "call this when that happens" is just an argument.**
