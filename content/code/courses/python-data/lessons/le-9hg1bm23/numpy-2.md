---
title: NumPy 2, and the code written for NumPy 1
version: 1
---

**NumPy 2 changed two things you will see in every notebook, and one of them changes answers.**
Most code you find online, and much of what colleagues wrote before 2024, was written for NumPy 1.
It still runs. Here is a five-line script, `promote.py`, saved in `pydata`:

```py
import numpy as np

docks = np.array([14, 20, 12], dtype=np.uint8)
print(np.__version__, repr(docks.max()))
print(docks + 300)
```

It stores three dock counts in the smallest unsigned type, `uint8` (0 to 255), and adds 300 to each.
Run under the NumPy 1 that was current before this course, in a separate environment as lesson 3
built one, and under this course's NumPy 2:

@@capture:numpy1@@

## What a single number looks like now

`docks.max()` returns one number, and NumPy 1 printed it as `20`. NumPy 2 prints
`np.uint8(20)`: **the representation now says the type**. It is the same value and it behaves the
same; it only stopped pretending to be a Python `int`. You will see `np.float64(30.5)` and
`np.int64(167)` throughout this course wherever a cell's last line is a single number from an
array. `print` and `float()` give the bare number back when you want it.

## What an operation with a Python number does now

The second line is the real change. NumPy 1 looked at the **value** 300, saw it did not fit in
`uint8`, and quietly made the result a wider type, `uint16`, so the sums came out right. NumPy 2
follows the **type** of the array: a Python number joins the array's type, and if it cannot be
represented in it, that is an error rather than a silent promotion. The rule has a name, NEP 50, if
you need to look it up.

So `docks + 300` is an `OverflowError` in NumPy 2 and `[314 320 312]` in NumPy 1. That direction
is the safe one: code that depended on the old promotion now fails loudly instead of giving a
different number. The quieter cases are mixtures of array types, and floats with Python floats,
where NumPy 2 can return a result in a narrower type than NumPy 1 did. The fix in every case is the
same: **choose the dtype you mean**, with `astype` or the `dtype=` argument, rather than relying on
promotion.

```python
docks = np.array([14, 20, 12], dtype=np.uint8)
docks.astype(np.int64) + 300
```

```
array([314, 320, 312])
```

When old code behaves oddly under NumPy 2, NumPy's own migration guide lists every change; this
section shows the two you will meet first.
