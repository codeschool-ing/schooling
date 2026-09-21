---
title: The single most common fix
version: 1
---

```python
blocked = load_blocked_ids()      # a list of 3,000 ids
for order in orders:              # 20,000 orders
    if order.customer_id in blocked:
        continue
    ...
```

**Twenty thousand walks of a three-thousand item list.** Sixty million comparisons, for a check
that reads like one operation.

```python
blocked = set(load_blocked_ids())
```

One word, one line, and the loop is now twenty thousand hash lookups.

## What it is worth

```sh
$ python -m timeit -s "data = list(range(100_000))" "99_999 in data"
500 loops, best of 5: 866 usec per loop

$ python -m timeit -s "data = set(range(100_000))"  "99_999 in data"
10000000 loops, best of 5: 34.6 nsec per loop
```

**Twenty-five thousand times**, on this machine, at this size. The ratio grows with `n`, because
one side is `O(n)` and the other is `O(1)`.

## How to spot it

Look for `in` against a collection **inside a loop**. That is the whole pattern. The give-away
is that the collection is built once and never changed:

```python
valid_codes = ["BRL", "USD", "EUR", ...]      # built once
...
for row in rows:
    if row["code"] in valid_codes:            # searched n times
```

If a collection is only ever asked "is this in you", it should be a set. If it is asked "what is
the value for this", it should be a dict.

## When it does not matter

```python
if method in ("GET", "POST", "HEAD"):
```

Three items, and the tuple wins on both memory and speed because building a set costs more than
walking three elements. **The crossover is small** — somewhere under about ten items for simple
values — and below it the tuple is also easier to read.

The rule is about the size of the collection and the number of times it is searched, and both
have to be large before this matters.

## And the one that is not a fix

```python
if x in set(items):          # the set is built every time
```

Building a set is `O(n)`, so doing it inside the loop costs exactly what the walk did, plus the
allocation. The whole saving is in building it **once, outside**.
