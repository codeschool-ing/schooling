---
title: Five types and a return that is not a value
version: 1
---

```python
def load(path: str) -> bytes: ...
def rate(code: str) -> float: ...
def valid(row: dict) -> bool: ...
def count(items: list) -> int: ...
```

`int`, `str`, `bool`, `float`, `bytes` — the class itself is the annotation. There is nothing to
import and nothing special to learn.

## `None` as a return

```python
def save(rows: list) -> None:
    ...
```

`-> None` means the function returns nothing useful. It is not "returns no value" — every Python
function returns something, and this one returns `None`.

**Write it.** A function with no return annotation is one a checker may skip entirely, and
`-> None` is also a statement of intent: this one is here for its effect.

## `int` and `float`

```python
def half(n: float) -> float: ...
half(4)            # fine
```

A checker treats `int` as acceptable wherever `float` is asked for — a deliberate special case in
the type system, because refusing it would make every numeric annotation tiresome. The reverse is
not true.

## `bool` is an `int`

`True` is `1` and `bool` is a subclass of `int`, so a `bool` is accepted where an `int` is asked
for. That is occasionally what you want and is usually an accident, and a checker will not save
you from it.

## `str` and `bytes` are not interchangeable

Lesson 9 said it about `==`, and the checker says it about arguments: a function annotated `str`
refuses `bytes`, which is exactly the boundary mistake that section was about.

## And the empty annotation

```python
def f(x):          # no annotation: the checker assumes nothing
```

An unannotated parameter is `Any` to most checkers in their default mode — which means the
checking stops there. That is not a failure; it is how a file gets annotated gradually.
