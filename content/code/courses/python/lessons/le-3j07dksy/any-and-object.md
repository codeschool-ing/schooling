---
title: The one that turns it off, and the one that does not
version: 2
---

```python
from typing import Any

def handle(payload: Any) -> None:
    payload.anything()        # no complaint
    payload + 1               # no complaint
    payload[0]                # no complaint
```

`Any` means **stop checking this value**. Everything is allowed on it, and everything it is
passed to is allowed.

## `object` keeps the checker on

```python
def handle(payload: object) -> None:
    payload.anything()        # error: "object" has no attribute "anything"
```

`object` is the top of the class hierarchy: every value IS one, so anything can be passed in —
and almost nothing can be done with it until you narrow it.

```python
    if isinstance(payload, dict):
        payload["key"]        # fine here
```

**`object` says "I accept anything and I will check before I use it".** `Any` says "I accept
anything and you may do what you like". The first is almost always what somebody meant.

## Why `Any` spreads

```python
data: Any = json.load(f)
rows = data["rows"]           # rows is Any
first = rows[0]               # Any
name = first["name"]          # Any — and three functions later, still Any
```

An `Any` flows through everything it touches, and the checking stops everywhere it reaches. That
is why an `Any` deserves a comment: it is not a local decision.

## Where `Any` is right

- data whose shape genuinely varies and is validated at the boundary
- a decorator's `*args, **kwargs` before you reach for the harder annotations
- the gap in a file you are annotating gradually

## And what a checker does with no annotation at all

An unannotated parameter is treated as `Any` by default. So a file with no annotations is not
"unchecked because it is wrong" — it is unchecked because nothing was claimed. Lesson 15 has the
setting that makes that an error.
