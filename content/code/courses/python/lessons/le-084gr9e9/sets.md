---
title: Membership and uniqueness, and no order at all
version: 2
---

```python
langs = {"python", "go", "sql"}
```

Braces with no colons. **The empty set is `set()`** — `{}` is an empty dictionary, which is the
one piece of syntax here that has to be memorised.

## What it is for

**Uniqueness.** Adding something twice leaves one:

```python
>>> seen = set()
>>> seen.add("ada")
>>> seen.add("ada")
>>> len(seen)
1
```

`list(set(items))` is the one-liner for removing duplicates, and it throws the order away. When
order matters, `list(dict.fromkeys(items))` keeps the first occurrence of each.

**And membership.** `x in some_set` is one step, like a dictionary and unlike a list.

## The operators

```python
>>> a = {1, 2, 3}
>>> b = {3, 4}
>>> a | b        # union — in either
{1, 2, 3, 4}
>>> a & b        # intersection — in both
{3}
>>> a - b        # difference — in a and not b
{1, 2}
>>> a ^ b        # symmetric difference — in one but not both
{1, 2, 4}
```

These replace loops. *Which users are in both groups* is `&`. *Which files are new* is `-`. Each
is one expression and each is fast.

## What it cannot do

**No order**, so no indexing: `langs[0]` raises. Printing one shows an order and you may not rely
on it.

**No duplicates**, which is the point and is occasionally the wrong tool — counting how many times
each word appears needs a dictionary.

**Only hashable members.** A set of tuples is fine; a set of lists raises `TypeError: unhashable
type: 'list'`.

## `frozenset`

The immutable version, which can therefore be a dictionary key or a member of another set. Rare,
and worth recognising when you meet it.
