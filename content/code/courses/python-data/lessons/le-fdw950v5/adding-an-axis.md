---
title: Adding an axis where the rule needs one
version: 1
---

**A length-1 axis costs nothing and changes everything about how an array broadcasts.** There are
three ways to add one, and they all produce the same `(52, 1)` from the same `(52,)`:

```python
weekly_flat.shape, weekly_flat[:, np.newaxis].shape, weekly_flat[:, None].shape, weekly_flat.reshape(-1, 1).shape
```

```
((52,), (52, 1), (52, 1), (52, 1))
```

`np.newaxis` is an alias of `None`, and inside square brackets it means "put a new axis of length
1 here". `[:, np.newaxis]` keeps every element on the first axis and adds a second; `[np.newaxis, :]`
would add it on the left instead, giving `(1, 52)`. `reshape(-1, 1)` says the same thing in terms of
the final shape. All three are views: no number is copied.

With the axis in place, the subtraction from the last section works:

```python
deviation = weeks - weekly_flat[:, np.newaxis]
deviation.shape, deviation[0].round(2)
```

```
((52, 7), array([-0.47, -0.37,  0.33,  0.83,  0.43, -0.87,  0.13]))
```

Each row now holds how far each day was from its own week's mean, and each row sums to
approximately zero, which is a quick check that the right thing was subtracted from the right
thing:

```python
np.abs(deviation.sum(axis=1)).max() < 1e-9
```

```
np.True_
```

## The habit that avoids it

**When you reduce something you are going to subtract back, keep the dimension.** `keepdims=True`
on the reduction produces the `(52, 1)` directly, and it says in the code why the shape is what it
is. Adding the axis afterwards works; it is the step people forget.

| you have | you want it to match | write |
|---|---|---|
| one value per row, `(n,)` | each row of an `(n, m)` table | `x[:, np.newaxis]`, or reduce with `keepdims=True` |
| one value per column, `(m,)` | each column of an `(n, m)` table | `x` as it is: it already lines up from the right |
| a column, `(n, 1)` | a row, `(m,)`, to get every pair | `x - y`, and mean it: "Every pair, on purpose", below |
