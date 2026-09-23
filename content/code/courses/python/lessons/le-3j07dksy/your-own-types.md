---
title: Your classes, an alias, and a shape for the JSON
version: 2
---

## A class is a type

```python
class Student: ...

def enrol(student: Student) -> None: ...
```

Nothing to declare. Every class you write is usable as an annotation, and a subclass is accepted
wherever the parent is asked for.

## An alias, for the shape you keep writing

```python
Row = dict[str, str]
Rows = list[Row]

def load(path: Path) -> Rows: ...
```

An ordinary assignment. It shortens the signature and gives the shape a name a reader can
recognise — and changing the shape is then one line.

`type Rows = list[Row]` is the 3.12 syntax for the same thing, with the advantage that it is
unambiguously a type and not a value.

## `NewType`, when two things of the same shape must not mix

```python
from typing import NewType

UserId = NewType("UserId", int)
OrderId = NewType("OrderId", int)

def load_user(uid: UserId) -> User: ...
load_user(OrderId(7))        # the checker refuses
```

Both are integers at run time and neither costs anything. What it buys is that passing the wrong
one is an error — which is the bug that is invisible in every other way.

## `TypedDict`, for lesson 9's JSON

```python
from typing import TypedDict

class Row(TypedDict):
    name: str
    city: str
    score: int

def parse(data: dict) -> list[Row]: ...
```

It is a dictionary at run time — the same `{"name": ...}` you already have — and a checker knows
which keys exist and what each holds. `row["ctiy"]` becomes an error rather than a `KeyError` in
production.

`total=False` makes every key optional; `NotRequired[str]` marks one.

**This is the annotation for data you parsed**, and it is the one that repays the effort fastest
on anything that came out of a file.
