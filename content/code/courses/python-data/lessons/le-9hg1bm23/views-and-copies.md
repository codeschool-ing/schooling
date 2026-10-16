---
title: Views and copies, and the change that shows up somewhere else
version: 1
---

**A slice of an array is not a new array of numbers; it is a new description of the same block.**
NumPy calls that a **view**. Changing a view changes the original, and that is either the most
efficient thing in the library or a bug that surfaces three cells later, depending on whether you
knew.

The rain column from the first section is itself a view, of `weather`:

```python
rain = weather[:, 0]
np.shares_memory(rain, weather), rain.base is weather
```

```
(True, True)
```

`np.shares_memory` answers whether two arrays use any of the same bytes, and a view's `base` is the
array that owns them. Now take the first week, and correct what looks like a sensor error in it:

```python
week = rain[:7]
week[0] = 0.0
week, rain[0], weather[0]
```

```
(array([ 0. ,  6.8,  7.9, 15.7,  0. ,  0. ,  1.3]),
 np.float64(0.0),
 array([ 0. , 29.9]))
```

The change made through `week` is in `rain` and in `weather`, because all three describe the same
eight bytes. Here the value was already `0.0`, so nothing was harmed; with any other value, the
year's data would now be different and no cell would show it being changed. **Slicing never
copies.** When you want an independent array, say so:

```python
week = rain[:7].copy()
week[1] = 99.0
rain[1], np.shares_memory(week, rain)
```

```
(np.float64(6.8), False)
```

## Which operations give a view

| gives a view | gives a copy |
|---|---|
| a slice, `a[2:5]`, `a[:, 0]`, `a[::2]` | a mask, `a[a > 10]` (lesson 7) |
| `reshape` of a contiguous array, `.T` | a list of positions, `a[[0, 3, 5]]` (lesson 7) |
| `ravel` when the order allows | arithmetic, `a + 1`, `a * 2` |
| `a.view(…)` | `.copy()`, `astype`, `flatten` |

A rule that covers nearly all of it: **an operation that can be done by changing the description
gives a view; one that has to choose or compute values gives a copy.** When it matters, do not
reason it out: ask `np.shares_memory`.

pandas sits on top of NumPy, and the same question, whether a selection is the data or a copy of
it, is what lesson 11 is about. pandas 3 answered it differently from NumPy, on purpose, and that
lesson says how.
