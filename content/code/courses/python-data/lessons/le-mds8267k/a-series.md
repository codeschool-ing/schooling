---
title: A Series is an array with labels
version: 1
---

**A pandas Series is a NumPy array with a second array beside it, the index, that names every
element.** Everything else in pandas is built on that pairing. The NumPy lessons kept the dates in
one array and the rain in another, and kept them in step by being careful; a Series keeps them in
step by construction.

From this lesson on, the notebooks start with pandas:

```python
import numpy as np
import pandas as pd

weather = pd.read_csv("weather.csv")
rain = pd.Series(weather["rain_mm"].to_numpy(), index=weather["date"], name="rain_mm")
rain.head()
```

```
date
2025-01-01     0.0
2025-01-02     6.8
2025-01-03     7.9
2025-01-04    15.7
2025-01-05     0.0
Name: rain_mm, dtype: float64
```

The left column is the index, the dates; the right is the values; the last line gives the name and
the dtype. `head()` shows the first five. The Series was built by hand here, from a NumPy array and
an index, to show the two halves. Reading it straight out of a table is the next sections' job.

```python
rain.values[:3], rain.index[:3], rain.dtype, rain.name
```

```
(array([0. , 6.8, 7.9]),
 Index(['2025-01-01', '2025-01-02', '2025-01-03'], dtype='str', name='date'),
 dtype('float64'),
 'rain_mm')
```

`values` is the NumPy array underneath, the same kind lessons 4 to 8 worked with. `index` is its
own object, an `Index`. Notice the index's dtype, `str`: in pandas 3, text has a type of its own,
which lesson 3 met in two environments and lesson 12 explains.

## By label, and by position

A Series can be asked for an element by its label or by its position, and the two are different
questions, with different methods:

```python
rain.loc["2025-03-22"], rain.iloc[80]
```

```
(np.float64(45.9), np.float64(45.9))
```

`loc` looks up the label: the day called `2025-03-22`, the wettest of the year. `iloc` counts
positions from 0, like NumPy: the 81st element, which here happens to be the same day. Lesson 11
is about `loc` and `iloc` in full; for now, **say which one you mean**, because plain square
brackets on a Series have changed meaning between pandas versions and are not worth guessing about.

Everything NumPy does to the values still works, and keeps the index:

```python
(rain > 40).sum(), rain[rain > 40]
```

```
(np.int64(4),
 date
 2025-03-22    45.9
 2025-06-17    41.0
 2025-07-01    41.4
 2025-09-03    40.9
 Name: rain_mm, dtype: float64)
```

The mask from lesson 7, with the dates attached to the answer, which is the point.
