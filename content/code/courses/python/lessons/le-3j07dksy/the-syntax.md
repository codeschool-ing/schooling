---
title: A colon, an arrow, and nothing enforced
version: 1
---

```python
def greet(name: str, times: int = 1) -> str:
    return f"hello, {name} " * times
```

A colon and a type after each parameter, an arrow and a type before the colon that ends the
header. A default goes after the annotation: `times: int = 1`.

## Variables too

```python
rows: list[dict] = []
total: float = 0.0
path: Path                 # declared, not yet assigned
```

The last one is an annotation with no value — legal, and useful at the top of a class body or
where the assignment happens in a branch.

## Nothing is checked at run time

```python
greet(3)          # runs; the annotation is not consulted
```

**Python stores the annotations and does not act on them.** `greet(3)` produces
`hello, 3 ` — the `f`-string was happy to format an integer. The failure, when there is one,
happens later and somewhere else.

That is the single most important sentence in this lesson. A type hint is a note for a reader,
an editor and a checker, and it is lesson 15 that reads it.

## Where the annotations go

```python
greet.__annotations__      # {'name': str, 'times': int, 'return': str}
```

A dictionary on the function. `@dataclass` in lesson 6 read exactly this to know what the fields
were — which is the one place in this course where an annotation does something at run time.

## Forward references

```python
class Node:
    def parent(self) -> "Node": ...       # a string, because Node is not finished yet
```

The class does not exist while its own body is being read, so the name goes in quotes. `from
__future__ import annotations` at the top of a file makes every annotation lazy and removes the
need — and it is worth doing in a file with many of them.

## And the one to avoid

```python
def f(x: "whatever I feel like") -> "who knows": ...
```

Any expression is accepted, because nothing checks. A checker will complain; Python will not.
