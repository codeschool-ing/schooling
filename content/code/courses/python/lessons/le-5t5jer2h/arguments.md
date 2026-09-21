---
title: Positional, keyword, and the default that is built once
version: 1
---

```python
def connect(host, port=5432, timeout=10):
    ...

connect("db.example.tld")
connect("db.example.tld", 6543)
connect("db.example.tld", timeout=30)
```

Positional arguments are matched by order; keyword arguments by name. A parameter with a default
may be left out, and **every parameter with a default comes after every parameter without one** —
otherwise there would be no way to tell which positional went where.

## Which to use at the call site

`connect("db.example.tld", 6543)` is readable because a host and a port are obviously a host and
a port. `charge(account, 1200, True)` is not readable by anybody, including the person who wrote
it.

**A boolean at a call site should almost always be a keyword**: `charge(account, 1200,
refundable=True)` says what the `True` means, in the place where somebody is reading it.

## The default is evaluated once, at the `def`

```python
def add(item, basket=[]):       # ONE list, for the life of the program
    basket.append(item)
    return basket

add("apple")     # ['apple']
add("pear")      # ['apple', 'pear']   ← the same list
```

This is lesson 3's mutable-sharing trap wearing its most common costume. The default expression
runs when the `def` line runs, so there is exactly one list and every call that does not bring
its own gets that one.

**The fix is four words:**

```python
def add(item, basket=None):
    if basket is None:
        basket = []
```

`None` is the marker for "the caller did not say", and the fresh list is built per call. The same
applies to `{}`, to a `set()`, and to anything else that can be changed. A number, a string or a
tuple as a default is safe, because there is nothing to change.

## Arguments are passed by reference to the same object

```python
def append_one(xs):
    xs.append(1)      # the caller's list changes

def rebind(xs):
    xs = [1]          # only the local name changes
```

Neither copies. The first mutates the object both names point at; the second points the local
name somewhere else and the caller sees nothing. It is lesson 3's `b = a` distinction, at a
function boundary — and **it is why a function that takes a list and changes it should say so in
its name**.
