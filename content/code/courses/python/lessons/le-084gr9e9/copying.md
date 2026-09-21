---
title: Assignment is a second name, and `copy` is shallow
version: 1
---

This is the section the lesson exists for.

```python
>>> a = [1, 2, 3]
>>> b = a
>>> b.append(4)
>>> a
[1, 2, 3, 4]
```

**`b = a` copied nothing.** One list, two names. This is true of every mutable value — lists,
dictionaries, sets, and the objects you write in lesson 6.

It is not a flaw. It is how you hand a million-row table to a function without duplicating it. It
is a surprise exactly once, and then it is a tool.

## Three ways to copy a list

```python
b = a[:]
b = list(a)
b = a.copy()
```

All three do the same thing. For a dictionary, `dict(a)` or `a.copy()`; for a set, `set(a)`.

## They are all shallow

```python
>>> a = [[1, 2], [3, 4]]
>>> b = a.copy()
>>> b[0].append(99)
>>> a
[[1, 2, 99], [3, 4]]
```

The outer list was copied. **The inner lists were not** — both outer lists point at the same two
inner ones. A shallow copy is one level deep, always.

```python
import copy
b = copy.deepcopy(a)
```

`deepcopy` follows the whole structure. It is slower, it handles cycles, and it is the right
answer when you genuinely need an independent tree.

## When it does not matter

**Numbers, strings and tuples cannot be changed**, so sharing one is invisible. That is why you
can pass a string around for a year without ever meeting this.

## How it actually bites

```python
def clean(rows):
    for row in rows:
        row["name"] = row["name"].strip()
    return rows
```

This looks like it returns cleaned rows and leaves the caller's alone. It does not: the
dictionaries are the caller's, and they have been edited. Either say so in the name — `clean_in_place`
— or copy first:

```python
def clean(rows):
    return [{**row, "name": row["name"].strip()} for row in rows]
```

**A function that changes its argument and also returns it** is the shape that hides this. Do one
or the other.
