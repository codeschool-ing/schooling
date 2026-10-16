---
title: Selecting with a list of positions
version: 1
---

**An array of integer positions selects those elements, in that order, repeats allowed.** NumPy
calls it fancy indexing. Lesson 5 used it without the name, when `dates[top]` read the dates of the
three wettest days through the positions `np.argsort` returned.

```python
picks = np.array([0, 90, 181, 273, 0])
dates[picks], temp[picks]
```

```
(array(['2025-01-01', '2025-04-01', '2025-07-01', '2025-10-01',
        '2025-01-01'], dtype='<U10'),
 array([29.9, 28.3, 28.5, 31.1, 29.9]))
```

The first day of each quarter, in the order asked for, and day 0 twice because it was asked for
twice. A slice cannot do either of those: it can only take a run with a fixed step.

## A copy, not a view

Unlike a slice, a list of positions **always makes a copy**, because the elements it picks are not
a regular pattern that new strides could describe:

```python
picked = temp[picks]
np.shares_memory(picked, temp), np.shares_memory(temp[0:300:90], temp)
```

```
(False, True)
```

The same rule covers masks: `rain[heavy]` is a copy too. Lesson 4's table said so; here is why
it matters, which is the next section.

## Rows and columns by position

On a table, a list of positions on one axis selects whole rows or columns:

```python
weeks[[0, 51]].shape, weeks[:, [3, 4]].shape
```

```
((2, 7), (52, 2))
```

The first and last weeks, and the weekends of every week. Two lists at once, one per axis, do
**not** give the rectangle you might expect. They pair up element by element:

```python
weeks[[0, 51], [3, 4]]
```

```
array([31.2, 31.9])
```

Two numbers: week 0's position 3 and week 51's position 4. For the rectangle of those weeks and
those days, `np.ix_` turns the two lists into the shapes that broadcast, `(2, 1)` and `(2,)`, the
outer product of lesson 6:

```python
weeks[np.ix_([0, 51], [3, 4])]
```

```
array([[31.2, 30.8],
       [30.9, 31.9]])
```
