---
title: Universal functions, element by element
version: 1
---

**A ufunc is a function that takes arrays and works element by element, in compiled code.** `+`,
`*` and `>` on arrays are ufuncs under other names (`np.add`, `np.multiply`, `np.greater`), and so
are `np.sqrt`, `np.log`, `np.abs`, `np.maximum` and about sixty more. Anything you would write as
"for each value, compute this" is probably one of them already.

```python
temp[:4], np.round(temp[:4]), np.maximum(temp[:4], 30.0)
```

```
(array([29.9, 30. , 30.7, 31.2]),
 array([30., 30., 31., 31.]),
 array([30. , 30. , 30.7, 31.2]))
```

`np.maximum` compares two arrays element by element and keeps the larger of each pair; here the
second "array" is the single number 30, which NumPy stretches to match, the subject of lesson 6.

## Comparisons give arrays of booleans

```python
hot = temp > 31.5
hot[:6], hot.sum(), hot.mean()
```

```
(array([False, False, False, False, False, False]),
 np.int64(19),
 np.float64(0.052054794520547946))
```

`temp > 31.5` asks the question of every day and answers with an array of `True` and `False`.
**Summing it counts the hot days, and its mean is their share of the year**, because `True` counts
as 1. Lesson 7 uses arrays like `hot` to select values; here they are already a statistic.

## Choosing per element with `np.where`

`np.where(condition, a, b)` takes `a` where the condition holds and `b` where it does not, element
by element. It replaces the `if` inside a loop:

```python
label = np.where(rain > 10, "wet", "dry")
label[:6], (label == "wet").sum()
```

```
(array(['dry', 'dry', 'dry', 'wet', 'dry', 'dry'], dtype='<U3'), np.int64(63))
```

`np.clip` is the special case of limiting values to a range, and saves two `where`s:

```python
np.clip(rain[:6], 1, 10)
```

```
array([ 1. ,  6.8,  7.9, 10. ,  1. ,  1. ])
```

## What a ufunc does with `nan`

**A missing value spreads.** Any arithmetic with `nan` gives `nan`, and any comparison with it gives
`False`:

```python
rain[np.isnan(rain)][:2] + 1, np.nan > 0, np.nan == np.nan
```

```
(array([nan, nan]), False, False)
```

The last one surprises everybody once: `nan` is not equal to itself, which is why `np.isnan` exists
and `== np.nan` never finds anything. And it is why the `wet` count above, like the list
comprehension in lesson 1, quietly left the six unread days out: `nan > 10` is `False`, so each
became `"dry"`. **A vectorised operation is as silent about missing values as a loop.** The next
section is about the functions that let you say what to do with them.
