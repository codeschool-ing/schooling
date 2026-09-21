---
title: Building a lookup once, instead of searching repeatedly
version: 1
---

```python
for order in orders:                      # 5,000 orders
    for customer in customers:            # 5,000 customers
        if customer["id"] == order["customer_id"]:
            out.append((customer["name"], order["cents"]))
            break
```

```python
by_id = {c["id"]: c for c in customers}   # one pass, built once
out = [(by_id[o["customer_id"]]["name"], o["cents"]) for o in orders]
```

```text
slow     0.5485s   5000 rows
fast     0.0030s   5000 rows
same answer: True
```

**O(n²) becoming O(n), for one line.** Measured on five thousand of each; at twenty thousand the
gap is five hundred times, which is the demonstration at the end of this lesson.

## Why it works

The inner loop is a search, and a search is what a dict does in one step. Building the index is
one pass over the customers — `O(n)` — and then every lookup is `O(1)`, so the whole thing is
`O(n + m)` instead of `O(n × m)`.

You pay one pass and some memory. You save a pass per row.

## The shapes that fit

```python
by_id = {c["id"]: c for c in customers}              # one value per key
```

```python
from collections import defaultdict
by_country = defaultdict(list)
for c in customers:
    by_country[c["country"]].append(c)               # many values per key
```

```python
from collections import Counter
counts = Counter(o["country"] for o in orders)       # just the count
```

`defaultdict(list)` is the grouping one and it comes up constantly — it is `sort | uniq` without
the sort, and the next lesson's `groupby` is the same idea over a table.

## Where to build it

**Outside every loop that uses it**, and once per program rather than once per call:

```python
def report(orders, customers):
    by_id = {c["id"]: c for c in customers}    # once
    for o in orders:
        ...
```

Building it inside the loop is the same mistake as `set(items)` inside a condition: the index is
`O(n)` to build, so building it `n` times is the `O(n²)` you were removing.

## And the honest limit

This works when you are looking things up **by an exact key**. A search for "any customer whose
name starts with these letters", or "the nearest value", is a different problem — `bisect` over a
sorted list for ranges, and a real index or a database for anything larger.
