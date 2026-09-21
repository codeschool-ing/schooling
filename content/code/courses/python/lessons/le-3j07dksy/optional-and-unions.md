---
title: `X | None`, and the union that is a smell
version: 1
---

```python
def find(code: str) -> Rate | None:
    ...
```

**The most useful annotation in the lesson.** It says the function sometimes finds nothing, and
a checker then points at every caller that used the result without asking.

## The older spelling

```python
Optional[Rate]        # from typing — the same thing
Union[int, str]       # from typing — now int | str
```

`Optional[X]` means `X | None` and never meant "this argument may be omitted", which is what its
name suggests and what everybody assumes once. The `|` form is the one to write now.

## Narrowing

```python
rate = find(code)
if rate is None:
    return 0.0
return total * rate          # here the checker knows it is a Rate
```

A checker follows the `if` and knows that `rate` cannot be `None` below it. That is what makes
the annotation useful rather than annoying: you check once, and the rest of the function is
clean.

`if rate is not None:` and an early `return` do the same, which is lesson 4's guard clause paying
for itself again.

## A default of `None`

```python
def connect(timeout: int | None = None) -> None:
    if timeout is None:
        timeout = 30
```

The annotation is `int | None` and the default is `None`. Writing `timeout: int = None` is a
common slip, and a checker refuses it.

## When a union is a design smell

```python
def load(source: str | Path | bytes | IO) -> list[dict]: ...
```

Four things, and the body has to branch on which it got. **Two is often fine; four is usually a
function that should have been two functions**, or one that takes something narrow and a caller
that converts.

The honest exception is a boundary — a parser, an adapter, the thing that meets the outside
world. That is the one place where accepting several shapes is the job.
