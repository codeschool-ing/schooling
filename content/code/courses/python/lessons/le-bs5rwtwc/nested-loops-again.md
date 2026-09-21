---
title: Lesson 4's nested loop, counted
version: 1
---

```python
for order in orders:              # n
    for customer in customers:    # × m
        if customer["id"] == order["customer_id"]:
            ...
```

**Two loops, one inside the other, over different collections: `O(n × m)`.** Twenty thousand each
is four hundred million comparisons, which is where the nine seconds in the demonstration came
from.

The shape is easy to see when it is written like this. The reason it survives in real code is
that it usually is not.

## The three disguises

```python
for order in orders:
    customer = find_customer(order.customer_id)      # a loop, one frame down
```

A helper function. The loop is still there and the call site looks like one operation. This is
exactly what the demonstration's `find_customer` was, and splitting the function is what made the
profiler point at it.

```python
for order in orders:
    if order.customer_id in blocked_list:            # a loop, inside an operator
```

`in` against a list. Two sections ago.

```python
matched = [(c, o) for o in orders for c in customers if c.id == o.customer_id]
```

A comprehension. Shorter, and exactly the same two loops.

## The three rewrites

**An index**, when you are looking things up by a key — the dictionary, built once. This is the
one that applies most of the time.

```python
by_id = {c["id"]: c for c in customers}
```

**A set**, when the inner loop is only asking whether something is present.

```python
blocked = set(blocked_ids)
```

**A sort and a single walk**, when the join is by a range rather than an exact key — sort both
sides once, `O(n log n)`, then walk them together in one pass. This is what a database calls a
merge join, and it is the answer when a hash lookup will not do.

## When to leave it alone

```python
for row in rows:                 # 40 rows
    for column in columns:       # 12 columns
```

Four hundred and eighty operations. Making it a dictionary costs a reader's attention and saves
nothing you can measure. **`O(n²)` on small `n` is fine**, and the number that matters is the
product rather than the shape.

The question to ask is not "is this nested" but "how big do these get, in production, in a
year".
