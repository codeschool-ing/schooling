---
title: Five shapes, at a thousand and at a million
version: 1
---

| | n = 1,000 | n = 1,000,000 |
| --- | --- | --- |
| **O(1)** | 1 | 1 |
| **O(log n)** | 10 | 20 |
| **O(n)** | 1,000 | 1,000,000 |
| **O(n log n)** | 9,966 | 19,931,569 |
| **O(n²)** | 1,000,000 | 1,000,000,000,000 |

**Read the last row.** A loop inside a loop over a million items is a million million operations.
A bare accumulating loop on this machine runs about ten million iterations a second, so that is
around ninety-four thousand seconds — **just over a day**, for one report.

## What each one looks like in code

```python
d[key]                          # O(1)     one step, whatever the size
bisect.bisect(sorted_data, x)   # O(log n) halve, halve, halve
for row in rows: ...            # O(n)     one pass
sorted(rows)                    # O(n log n)
for a in rows:
    for b in rows: ...          # O(n²)    a pass per item
```

## `O(log n)` is the one that feels wrong

```sh
n = 1,000        10 steps
n = 1,000,000    20 steps
n = 1,000,000,000  30 steps
```

A thousand times more data and ten more steps. That is what halving does, and it is why every
index, every balanced tree and every binary search is built around it. **`O(log n)` is close
enough to free** that the difference between it and `O(1)` almost never decides anything.

## `O(n log n)` is what sorting costs

```sh
sorted, n =   1,000    0.088 ms
sorted, n =  10,000    1.277 ms      ← 10× the data, 14× the time
sorted, n = 100,000   18.112 ms      ← 10× the data, 14× the time
```

Measured. Ten times the data costs about fourteen times the work, every time — which is exactly
what `n log n` predicts and what a linear cost would not.

**Sorting is cheap enough to reach for.** If sorting the data first turns an `O(n²)` search into
an `O(n)` pass, sorting was free by comparison.

## And the ones past `O(n²)`

`O(2ⁿ)` and `O(n!)` exist — every subset, every ordering — and they are unusable above about
twenty and about ten respectively. If you have written one you generally know; the danger in
ordinary code is `O(n²)`, because it works fine on the test data.
