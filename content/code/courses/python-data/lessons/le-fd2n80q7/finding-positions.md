---
title: From a mask back to positions
version: 1
---

**A mask says *whether* for every element; sometimes you need *where*, as numbers.** `np.nonzero`
turns a mask into the positions of its `True` values, and `np.flatnonzero` does the same for a flat
array without wrapping the answer in a tuple:

```python
missing = np.flatnonzero(np.isnan(rain))
missing, dates[missing]
```

```
(array([172, 212, 216, 268, 304, 323]),
 array(['2025-06-22', '2025-08-01', '2025-08-05', '2025-09-26',
        '2025-11-01', '2025-11-20'], dtype='<U10'))
```

The six days with no rain reading, by position and by date. Positions are what you need to look
at a day's neighbours, to report a gap, or to fix one value by hand with a comment saying why.

## The first and the last

`argmax` on a mask finds the first `True`, as lesson 5 showed. The last is the same question asked
of the reversed mask:

```python
over_40 = rain > 40
first = np.argmax(over_40)
last = len(over_40) - 1 - np.argmax(over_40[::-1])
dates[first], dates[last], over_40.any()
```

```
(np.str_('2025-03-22'), np.str_('2025-09-03'), np.True_)
```

**Check `any()` before trusting `argmax` on a mask**: on a mask with no `True` at all, `argmax`
returns 0, which looks exactly like an answer.

## `np.where` with one argument

`np.where(mask)` with no second and third arguments is `np.nonzero(mask)`: a tuple of position
arrays, one per axis. On a table that gives a row array and a column array, paired:

```python
rows, cols = np.where(weeks > 32)
rows, cols, weeks[rows, cols]
```

```
(array([ 7, 10, 30, 36, 36, 48]),
 array([1, 0, 6, 4, 6, 0]),
 array([32.1, 32.1, 32.6, 32.1, 32.1, 32.1]))
```

Each pair `(rows[i], cols[i])` is one hot day: its week and its position in the week. Indexing the
table with the two arrays gives the temperatures back, element by element, as the last section's
paired lists did.
