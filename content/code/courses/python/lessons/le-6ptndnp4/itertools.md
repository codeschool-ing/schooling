---
title: Six that are worth the import
version: 1
---

```python
from itertools import islice, chain, groupby, count, cycle, takewhile
```

## `islice`

```python
islice(rows, 10)          # the first ten
islice(rows, 10, 20)      # the tenth to the twentieth
```

Slicing for things you cannot index. On a million-row file it reads ten rows, which `list(rows)[:10]`
does not.

## `chain`

```python
for row in chain(header_rows, body_rows, footer_rows):
```

Three iterables, walked as one, with nothing concatenated. `chain.from_iterable(list_of_lists)`
flattens one level, lazily.

## `groupby`

```python
for city, group in groupby(sorted(rows, key=city_of), key=city_of):
```

Runs of CONSECUTIVE equal keys, which is why the sort is not optional — unsorted input gives you
the same key several times and says nothing. Lesson 7 met this; it is worth meeting twice.

## `count` and `cycle`

```python
for i, row in zip(count(1), rows):        # numbering, without len
for row, colour in zip(rows, cycle(["odd", "even"])):
```

Both are infinite, which is fine because `zip` stops at the shorter one. `count` is `range` with
no end; `cycle` repeats a sequence forever and **keeps a copy of it**, which matters if it is big.

## `takewhile` and `dropwhile`

```python
takewhile(lambda r: r["date"] < cutoff, rows)     # stop at the first that fails
```

`takewhile` stops at the first item that fails the test — it does not filter, it ENDS. On a
sorted file that is the difference between reading the part you want and reading all of it.

## And one rule about all of them

They return iterators. Everything in this lesson applies: one pass, no length, and nothing
computed until something asks.
