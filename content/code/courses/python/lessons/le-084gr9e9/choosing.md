---
title: Four questions that settle it
version: 1
---

| | list | tuple | dict | set |
|---|---|---|---|---|
| ordered | yes | yes | by insertion | **no** |
| can change | yes | **no** | yes | yes |
| duplicates | yes | yes | keys: no | **no** |
| indexed by | position | position | key | — |
| `in` costs | **a walk** | **a walk** | one step | one step |
| can be a dict key | no | **yes** | no | no |

## The questions, in order

**Is there a name for each piece?** Then a dictionary. `person["city"]` says what it is;
`person[1]` needs you to remember. This is the answer most of the time, and a list of dictionaries
is what almost every file you read turns into.

**Do you only need to know whether something is there?** A set. No duplicates and no walk.

**Is it a fixed group of things that belong together?** A tuple — a coordinate, a return value, a
key.

**Otherwise a list**, which is the honest default: an ordered collection of things of the same
kind.

## The one that costs real time

```python
for name in names:            # 100_000 names
    if name in banned:        # banned is a list of 5_000
        ...
```

That is five hundred million comparisons. Change `banned` to a set and it is a hundred thousand
steps, and the line of code does not otherwise change. Lesson 20 measures exactly this and the
answer is eleven seconds against forty milliseconds.

**The rule of thumb:** if `in` is inside a loop, the thing on the right should be a set or a
dictionary.

## What they have in common

All four are iterable, all four have `len`, all four work with `in`, and all four can be built
from another with `list()`, `tuple()`, `set()` or `dict()`. Converting between them is cheap and
is often the neatest way to say something:

```python
>>> sorted(set(words))       # unique, in order
>>> dict(pairs)              # a list of two-item tuples into a dictionary
```
