---
title: The boundary, and the annotation that says nothing
version: 2
---

## In order

1. **Public functions** — the ones another module calls. The signature is the contract, and this
   is where a reader looks first.
2. **Anything taking or returning a collection** — `list` alone says nothing about what is
   inside, and `list[Row]` says everything.
3. **Anything that can return `None`** — the bug that earns the whole lesson back.
4. **Everything else, eventually**, and only if it helps.

## The ones that need nothing

```python
def _slug(title: str) -> str:
    return title.lower().replace(" ", "-")      # annotated anyway: it is a boundary of one line

def _key(row):
    return row["city"]                          # a `sorted` key, three lines from its use
```

A two-line private helper used once, beside its caller, is understood by reading it. A checker
infers most of it anyway.

## The annotation that says nothing

```python
def parse(data: dict) -> dict: ...
def process(items: list) -> list: ...
def handle(payload: Any) -> Any: ...
```

Each of those is the shape of a lie by omission: it looks annotated, so nobody looks harder, and
it claims nothing a checker can use. **An empty annotation is worse than none**, because the
absence at least says nobody has been here.

## Variables mostly do not need one

```python
rows = []                 # the checker cannot tell what goes in
rows: list[Row] = []      # now it can
total = 0                 # obvious; leave it
```

Annotate the empty container and the one whose type is not visible on the line. Everything else
is noise.

## Gradually, and from the outside in

Annotate the module's public surface, run the checker, fix what it finds, and go one layer
deeper. **That order finds the most bugs per hour**, because the outside is where the wrong
assumptions meet each other.

And a file that is half annotated is not half broken. That is the whole design of the system:
`Any` where nothing is claimed, and checking where something is.
