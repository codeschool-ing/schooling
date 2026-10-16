---
title: Running totals, differences and the position of the largest
version: 1
---

**Some operations keep the length of the array and look along it: a running total, a difference
from the day before, the position of the largest value.** They answer questions a reduction
cannot: not "how much rain in the year" but "by which day had half of it fallen".

The dates are text, so they are read on their own, as strings:

```python
dates = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=0, dtype=str)
dates[:2], dates.dtype
```

```
(array(['2025-01-01', '2025-01-02'], dtype='<U10'), dtype('<U10'))
```

## Running totals with `cumsum`

```python
so_far = np.cumsum(np.nan_to_num(rain))
so_far[-1], dates[np.argmax(so_far >= so_far[-1] / 2)]
```

```
(np.float64(1712.7999999999995), np.str_('2025-06-10'))
```

`cumsum` gives, for each day, the total up to and including that day; the last element is the
year's total of known days. `so_far >= so_far[-1] / 2` is `False` until half the year's rain has
fallen and `True` from then on, and **`np.argmax` returns the position of the first largest value**,
which for an array of booleans is the first `True`. Read through `dates`, that position is a day.
Half of Recife's 2025 rain had fallen by that date, in a rainy season that runs from April to July.

## The largest, and the largest few

```python
wettest = np.nanargmax(rain)
np.argmax(rain), wettest, dates[wettest], rain[wettest]
```

```
(np.int64(172), np.int64(80), np.str_('2025-03-22'), np.float64(45.9))
```

`np.argmax` returned the position of the first `nan`, because a missing value wins every
comparison it is in; `np.nanargmax` skips them and finds the real wettest day. For the top few, sort the positions rather than the values, so that the
dates come with them:

```python
top = np.argsort(np.nan_to_num(rain))[::-1][:3]
dates[top], rain[top]
```

```
(array(['2025-03-22', '2025-07-01', '2025-06-17'], dtype='<U10'),
 array([45.9, 41.4, 41. ]))
```

`np.argsort` returns the positions that would sort the array, smallest first; `[::-1]` reverses
them and `[:3]` keeps three. **Sorting positions instead of values is how you keep two arrays in
step**, and it is exactly what pandas does for you from lesson 9, when the dates and the rain live
in one table.

## The change from one day to the next

```python
change = np.diff(temp)
change.shape, change[:4].round(1), np.abs(change).max().round(1)
```

```
((364,), array([ 0.1,  0.7,  0.5, -0.4]), np.float64(3.6))
```

`np.diff` subtracts each element from the next, so the result is **one shorter** than the input:
364 changes between 365 days. Lesson 16 does the same for a series of trips, where the index keeps
the dates lined up and a lost element is a `NaN` instead.
