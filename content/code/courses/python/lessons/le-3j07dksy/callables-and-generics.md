---
title: A function as a type, and taking the widest thing you can
version: 1
---

```python
from collections.abc import Callable

def apply(items: list[str], fn: Callable[[str], int]) -> list[int]:
    return [fn(x) for x in items]
```

`Callable[[argument types], return type]`. The inner brackets are the argument list, even when
there is one argument, and `Callable[..., int]` is "any arguments, returns an int" for when you
do not care.

## Take the widest type you can accept

```python
def total(rows: list[dict]) -> int: ...       # a list, and only a list
def total(rows: Iterable[dict]) -> int: ...   # a list, a tuple, a set, a generator
```

If the body only iterates, say `Iterable`. A caller with a generator then works — and lesson 11
spent a whole lesson on why the caller might have one.

| you do | annotate |
| --- | --- |
| iterate once | `Iterable[X]` |
| iterate, index, or take `len` | `Sequence[X]` |
| look things up by key | `Mapping[K, V]` |
| also CHANGE it | `list[X]`, `dict[K, V]` |

**The mutable ones are a promise you are making to the caller**, not just a requirement: taking
a `list` says you might append to it.

## And return the most specific type you can promise

```python
def names(rows: Iterable[dict]) -> list[str]:      # yes
def names(rows: Iterable[dict]) -> Iterable[str]:  # why?
```

Wide in, narrow out. The caller then knows it can index the result, and you have not promised
anything you did not mean.

## Where they come from

`collections.abc` since 3.9 — `Iterable`, `Sequence`, `Mapping`, `Callable`, `Iterator`. The
same names exist in `typing` and are the deprecated spelling.

## `Iterator` against `Iterable`

Lesson 11's distinction, in the annotations: a generator function returns an `Iterator[X]`, and
something that can be walked again is an `Iterable[X]`.

```python
def rows(path: Path) -> Iterator[str]:
    with open(path, encoding="utf-8") as f:
        yield from f
```
