---
title: The silent one, (n,) against (n, 1)
version: 1
---

**The dangerous broadcasting is the one that works.** An error stops you; a broadcast you did not
intend gives you an array of the wrong shape and lets you carry on. The classic case is a column and
a row of the same length, `(n, 1)` and `(n,)`: the rule stretches both, and instead of `n` results
you get `n × n`.

Ana has a forecast for the first week of January, one value per day, kept as a column because that
is how a model handed it over:

```python
forecast = np.array([30.1, 30.0, 30.5, 31.0, 30.8, 30.2, 30.6]).reshape(-1, 1)
actual = temp[:7]
forecast.shape, actual.shape
```

```
((7, 1), (7,))
```

The error of each day's forecast is a subtraction, and here it is:

```python
error = forecast - actual
error.shape
```

```
(7, 7)
```

**Seven by seven.** Every forecast minus every actual: day 1's forecast against day 4's temperature,
and 42 other pairs that mean nothing. No error, no warning. The next line is where it does damage,
because a summary of a wrong-shaped array is a number like any other:

```python
np.abs(error).mean().round(3), np.abs(forecast.ravel() - actual).mean().round(3)
```

```
(np.float64(0.539), np.float64(0.2))
```

The first number is the mean absolute error of 49 comparisons, 42 of them nonsense; the second is
the real one, from the seven days compared with themselves. They differ, and nothing about the first
would make you suspicious if you had not seen the second.

## How to stay out of it

- **Check the shape of a result you expected to have a known shape.** One line, `error.shape`, would
  have shown `(7, 7)` instead of `(7,)`. An `assert error.shape == actual.shape` in a notebook
  costs nothing and turns the silence into an error.
- **Flatten columns that are really lists.** A forecast for seven days is one-dimensional data, and
  `ravel()` or `reshape(-1)` makes it so before it meets anything else.
- **Prefer pandas for data with labels.** From lesson 9, two Series line up by their index, not by
  their shape, and this particular mistake becomes a different one, lesson 9's "index nobody reads".
