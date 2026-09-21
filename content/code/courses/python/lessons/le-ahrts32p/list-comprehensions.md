---
title: `[f(x) for x in xs if p(x)]`
version: 1
---

```python
discounted = [price * 0.9 for price in prices if price > 100]
```

Six lines of loop in one, and the first thing it says is **what is being built**.

## Reading it

The order it is written in is not the order it runs in:

```
[  price * 0.9        for price in prices       if price > 100  ]
   what to keep       where it comes from       which ones
```

Execution goes right to left: take each price, test it, and if it passes, evaluate the expression.
Reading goes left to right, which is what makes it readable.

## The shapes

```python
[x * 2 for x in xs]                  # map
[x for x in xs if x > 0]             # filter
[x * 2 for x in xs if x > 0]         # both
[y for row in grid for y in row]     # flatten — the loops in the order you would write them
```

**The nested one is the only one that surprises.** The `for` clauses read left to right exactly
as nested `for` statements, which is the opposite of what most people guess.

## When it stops being clearer

```python
# three conditions and a conditional expression — this is a loop
[transform(x) if ok(x) else fallback(x) for x in xs if a(x) and b(x)]
```

Two rules that hold up:

**If it does not fit on one line, it is a loop.** Not "wrap it" — the wrapping is the signal.

**If you want to do anything but build a value, it is a loop.** A comprehension cannot log,
cannot `break`, cannot assign to anything outside itself. That is a feature — it is why you can
trust what one does at a glance — and it is also the boundary.

## What it is not for

```python
[print(x) for x in xs]      # no
```

This builds a list of `None`s and throws it away, for the side effect. Write the loop; it is the
same length and it says what it means.
