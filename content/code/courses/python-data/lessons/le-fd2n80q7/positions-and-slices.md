---
title: Positions and slices, in one and two dimensions
version: 1
---

**An index picks elements by position; a slice picks a run of them and gives back a view.** In one
dimension NumPy indexes exactly like a Python list. In two it takes one index per axis, separated by
commas, inside one pair of brackets, and that comma is where most of the new habits are.

The notebook for this lesson reads the weather and the dates, as the last two lessons did:

```python
import numpy as np

weather = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=(1, 2))
dates = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=0, dtype=str)
rain, temp = weather[:, 0], weather[:, 1]
weeks = temp[:364].reshape(52, 7)
```

## One dimension

```python
temp[0], temp[-1], temp[:3], temp[-3:], temp[::91]
```

```
(np.float64(29.9),
 np.float64(32.2),
 array([29.9, 30. , 30.7]),
 array([31. , 31.3, 32.2]),
 array([29.9, 29.2, 27.8, 31.1, 32.2]))
```

Position 0 is the first day; `-1` counts from the end. A slice `start:stop:step` **includes the
start and stops before the stop**, so `temp[:3]` is positions 0, 1 and 2, and leaving a bound out
means "from the beginning" or "to the end". `temp[::91]` takes every 91st day, a reading per
quarter.

## Two dimensions

```python
weeks[3, 4], weeks[3], weeks[:, 4][:3], weeks[:2, :3]
```

```
(np.float64(30.0),
 array([30.8, 30.2, 29.5, 29.4, 30. , 30.4, 30.5]),
 array([30.8, 31.3, 31.4]),
 array([[29.9, 30. , 30.7],
        [31.3, 30.7, 30.5]]))
```

| expression | gives | shape |
|---|---|---|
| `weeks[3, 4]` | one number: week 3, position 4 | `()` |
| `weeks[3]` | the whole of week 3 | `(7,)` |
| `weeks[:, 4]` | position 4 of every week, every Sunday | `(52,)` |
| `weeks[:2, :3]` | the first two weeks, their first three days | `(2, 3)` |

**`weeks[3, 4]` and `weeks[3][4]` give the same number and are not the same operation.** The first
is one lookup with two indices. The second makes `weeks[3]`, a view of the row, and then indexes it.
For reading, the difference is speed. For writing, it is the difference between changing the table
and, in some cases, changing a temporary that is thrown away; the section on writing through an
index, below, is that case, and lesson 11 is the same case in pandas.

A slice keeps the axis it slices; an integer removes it. `weeks[3]` is `(7,)` but `weeks[3:4]` is
`(1, 7)`, one week still in a table:

```python
weeks[3].shape, weeks[3:4].shape
```

```
((7,), (1, 7))
```

Lesson 6 would add: if you plan to broadcast the result against something, that difference decides
whether it lines up.
