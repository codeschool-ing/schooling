---
title: What is inside it, and the tuple that is two types
version: 2
---

```python
def names(rows: list[dict]) -> list[str]: ...
def counts(words: list[str]) -> dict[str, int]: ...
def pair() -> tuple[int, str]: ...
def point() -> tuple[float, float]: ...
```

The brackets say what is inside. `list` on its own is a list of anything, which is most of what
an annotation is for left unsaid.

## `dict[key, value]`

```python
dict[str, int]          # words to counts
dict[str, list[dict]]   # nesting, as deep as it goes
```

Two parameters, in that order, and they nest without limit. The second example is lesson 9's
JSON shape written down.

## The tuple that is not like the others

```python
tuple[int, str]         # exactly two items: an int and a str
tuple[int, ...]         # any number of ints
tuple[int]              # exactly ONE int
```

**A tuple's annotation lists every position**, because a tuple's positions have meanings. The
`...` is literal syntax — three dots — and it is how you say "more of the same". `tuple[int]` is a
one-item tuple and almost never what somebody meant.

## `set` and `frozenset`

```python
set[str]
frozenset[str]
```

Same shape, one parameter.

## Since Python 3.9

```python
list[int]               # now
List[int]               # before 3.9, from `typing`
```

The lowercase built-ins take brackets directly. The capitalised ones from `typing` still work and
are what you will see in older code — and `from __future__ import annotations` lets the new
syntax be used on any version, because the annotation is never evaluated.

## What to annotate when it is a mess

```python
def parse(data: dict) -> dict: ...          # says almost nothing
def parse(data: dict[str, Any]) -> Row: ... # says what you actually know
```

If the shape is genuinely irregular, say `dict[str, Any]` and move on — and if it is regular,
`TypedDict`, in this lesson's `your-own-types` section, gives it a name.
