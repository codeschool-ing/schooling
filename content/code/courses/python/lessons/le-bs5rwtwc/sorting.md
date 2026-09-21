---
title: `sort`, `sorted`, `key=`, and what it costs
version: 1
---

```python
data.sort()               # sorts in place, returns None
new = sorted(data)        # returns a new list, leaves data alone
```

```sh
>>> d = [3, 1, 2]
>>> d.sort()
>>> d
[1, 2, 3]
```

**`sort()` returns `None`.** `x = data.sort()` sets `x` to nothing, and it is the most common
mistake with either of them. `sorted` is the one to reach for by default; `sort` is for when the
list is large and you do not need the original.

`sorted` also takes anything iterable and always gives back a list, which is how you sort a set, a
dict's keys or a generator.

## `key=`

```python
rows.sort(key=lambda r: r["cents"])
rows.sort(key=lambda r: (r["country"], -r["cents"]))     # country, then by size
```

The function is called **once per element**, and the results are what get compared. A tuple sorts
by its first item, then the second, which is how a secondary sort is written on one line — and
negating a number reverses that component on its own.

```sh
sorted with key=lambda,  n=100,000    27.5 ms
sorted with itemgetter,  n=100,000    25.3 ms
sorted, no key,          n=100,000    18.1 ms
```

A `key` costs about half as much again. `operator.itemgetter` is slightly faster than a lambda
and not by enough to matter.

## Stability

```sh
>>> rows = [("b", 2), ("a", 1), ("b", 1), ("a", 2)]
>>> sorted(rows, key=lambda r: r[0])
[('a', 1), ('a', 2), ('b', 2), ('b', 1)]
```

**Equal elements keep their original order.** `('b', 2)` is still before `('b', 1)` because it
was, and nothing about the sort disturbed it.

That is a guarantee, and it is what makes two sorts work:

```sh
>>> sorted(sorted(rows, key=lambda r: r[1]), key=lambda r: r[0])
[('a', 1), ('a', 2), ('b', 1), ('b', 2)]
```

Sort by the secondary key first, then by the primary. The second sort leaves the first one's
order intact within each group.

## What it costs

`O(n log n)`, measured in the section on the curves: ten times the data, about fourteen times the
work. Python's sort is Timsort, which is much faster on data that is already partly ordered — at a
million floats, sorting a random list takes 344 ms and sorting an already-sorted one takes 85,
because it finds the runs that are already in order and merges them.

## When you do not need a sort

```python
max(rows, key=lambda r: r["cents"])              # O(n), not O(n log n)
heapq.nlargest(10, rows, key=lambda r: r["cents"])
```

```sh
at n = 1,000,000 floats
  sorted(data)[-10:]     349.6 ms
  heapq.nlargest(10, …)   15.2 ms
  max(data)               11.3 ms
```

Sorting everything to take the biggest one is `O(n log n)` where `max` is a single pass. For the
top few, `heapq.nlargest` is twenty-three times a full sort at a million items.
