---
title: The default is created once, at definition
version: 2
---

```python
def add(item, basket=[]):
    basket.append(item)
    return basket
```

```python
>>> add("apple")
['apple']
>>> add("pear")
['apple', 'pear']
```

The second call did not start with an empty basket. **The default value was created once, when
the `def` line was read**, and every call that does not supply one shares that single list.

## Why it works that way

A `def` is a statement that runs. When Python reads it, it evaluates the defaults there and then
and stores them on the function object — you can look:

```python
>>> add.__defaults__
(['apple', 'pear'],)
```

That is the same list, still attached, still growing.

## The fix

```python
def add(item, basket=None):
    if basket is None:
        basket = []
    basket.append(item)
    return basket
```

`None` is immutable, so sharing it is harmless, and the new list is created **per call**. This is
why lesson 2's `none` section called it the right default for an argument that should get a list.

## Which defaults are safe

| | |
|---|---|
| safe | `None`, numbers, strings, `True`/`False`, tuples |
| **not safe** | `[]`, `{}`, `set()`, and any object with state |

The rule is the same as everywhere else in this lesson: **mutable or not**.

## It is not always a bug

```python
def fib(n, memo={}):
    ...
```

A cache that deliberately outlives the call uses exactly this behaviour. It is legitimate, it is
surprising to the next reader, and `functools.cache` in lesson 12 says it out loud instead.

Lesson 17's linter flags every mutable default, including the deliberate one — which is correct,
because the tool cannot tell them apart and the deliberate one deserves a comment anyway.
