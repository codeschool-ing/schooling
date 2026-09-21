---
title: Five you have already used
version: 1
---

Every one of these is a function that takes a function.

## `@property`

`area = property(area)`, inside a class body. The `property` object implements the protocol that
makes attribute access call your function — lesson 6 had the behaviour, and this is what it is.

## `@staticmethod` and `@classmethod`

`f = staticmethod(f)` and `f = classmethod(f)`. Each wraps the function in an object that
decides what, if anything, is passed as the first argument.

## `@functools.cache`

```python
@functools.cache
def fib(n):
    return n if n < 2 else fib(n - 1) + fib(n - 2)
```

A wrapper holding a dictionary from arguments to results. `fib(100)` goes from impossible to
instant, and the decorator is twenty lines you did not write.

**The arguments must be hashable**, because they are the dictionary key — so a list argument
raises `TypeError`, and the message is about the cache rather than about your function.

`@functools.lru_cache(maxsize=128)` is the bounded version, and it takes an argument, which makes
it a three-layer decorator like the previous section.

## `@pytest.fixture` and friends

Lesson 15's testing framework uses decorators to register things: this function provides a
fixture, this one is a test, run this one three times with these arguments. **The decorator's job
there is the registry** — it puts the function in a list the framework reads later, which is the
"applied at definition" note from earlier doing real work.

## And `@dataclass`

Lesson 6's, and the odd one out: it takes a CLASS, adds methods to it, and returns it. Same
rule — a function that takes a thing and returns a thing — with a class in the middle.
