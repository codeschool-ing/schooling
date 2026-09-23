---
title: Counting operations, not seconds
version: 2
---

```python
def contains(items, target):
    for item in items:          # once per item, in the worst case
        if item == target:
            return True
    return False
```

**Seconds are a property of the machine.** The same function is faster on a newer laptop, slower
under a profiler, and different again on the day something else is compiling. None of that is a
property of the code.

So the measure is **how the work grows with the input**. Call the size of the input `n`. The
function above does at most `n` comparisons, so its cost is `O(n)`: double the data, double the
work.

## What `n` is

Whatever is getting bigger. The number of rows, of files, of users, of characters in a string. A
function can have two — `O(n × m)` for a loop over customers inside a loop over orders — and
naming them is most of the analysis.

## Why the constant is dropped

```python
for item in items:
    x = item * 2
    y = x + 1
    total += y          # three operations per item, not one
```

That is `3n`, and it is written `O(n)`. The constant is dropped because it depends on the
machine, the interpreter and the exact lines — and because **the shape is what survives a change
of scale**. At `n = 1,000,000`, a `3n` algorithm and an `n` algorithm are both a rounding error
beside an `n²` one.

The same argument drops the smaller terms: `n² + 5n + 200` is `O(n²)`, because at a million the
`n²` term is a million times bigger than the rest put together.

## Worst case, and why

`O` describes the **worst case** unless something says otherwise. `contains` returns immediately
when the target is first in the list, and that is `O(1)` on a good day — but a cost you can only
rely on when you are lucky is not a cost you can rely on.

## What it deliberately ignores

```python
data[i]                # O(1)
some_set.add(x)        # O(1)
```

Both are `O(1)` and one is several times the other. Big-O says they behave the same way as the
data grows, and it says nothing about which is faster today. **That is the trade**: it throws away
everything machine-specific so that what is left is true everywhere, which is also why it can
never replace a measurement.
