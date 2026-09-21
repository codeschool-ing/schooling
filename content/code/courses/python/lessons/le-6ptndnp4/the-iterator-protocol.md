---
title: Two methods, and what `for` is doing
version: 1
---

```python
it = iter([1, 2, 3])
next(it)      # 1
next(it)      # 2
next(it)      # 3
next(it)      # StopIteration
```

`iter(x)` asks `x` for an iterator by calling its `__iter__`. `next(it)` calls the iterator's
`__next__`. When there is nothing left, `__next__` raises `StopIteration`.

## What a `for` loop is

```python
for item in items:
    body(item)
```

is, near enough:

```python
it = iter(items)
while True:
    try:
        item = next(it)
    except StopIteration:
        break
    body(item)
```

**Every surprise in this lesson follows from that.** The loop asks once for an iterator and then
pulls values until the exception — so a second loop over the same ITERATOR gets nothing, and a
second loop over the same LIST gets a fresh iterator and works.

## `StopIteration` is a signal, not an error

It is an exception used for control flow, and the `for` loop swallows it. You will almost never
catch it yourself; `next(it, default)` is the version that returns a default instead of raising,
and it is what you want when asking for one value.

```python
first = next(it, None)
```

## Everything you already use

`range`, `zip`, `enumerate`, `map`, `filter`, a file object, a dictionary's `.items()`, every
generator expression. Some of those are iterators and some produce a fresh one each time — the
next section is that distinction, and it is the one that matters in practice.

## Why the protocol exists

Because `for` then works with anything that implements two methods. A list, a file, a database
cursor, a stream of rows from an API — the loop does not know the difference, and you can write
something new that it also does not know the difference about.
