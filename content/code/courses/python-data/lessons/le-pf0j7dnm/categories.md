---
title: Categories, for columns with few distinct values
version: 1
---

**A categorical column stores each distinct value once and gives every row a small integer pointing
at it.** For a column like `plan`, with two values repeated 33,337 times, that is much less memory, and
it carries the list of allowed values with it.

```python
plan = trips["plan"].astype("category")
plan.dtype, plan.cat.categories.tolist(), trips["plan"].memory_usage(deep=True), plan.memory_usage(deep=True)
```

```
(CategoricalDtype(categories=['annual', 'day'], ordered=False, categories_dtype=str),
 ['annual', 'day'],
 437153,
 33495)
```

The text column takes over 400 kB; the categorical one, under 35. Lesson 20 does this to every column
that allows it. The data does not change: `value_counts`, comparisons and filters work as before.

## Categories that are not there

A category can exist with no rows in it, and a categorical column remembers it:

```python
weekday = pd.Categorical(["Mon", "Tue", "Mon"], categories=["Mon", "Tue", "Wed"])
pd.Series(weekday).value_counts()
```

```
Mon    2
Tue    1
Wed    0
Name: count, dtype: int64
```

`Wed` is counted with 0. For a report that must show every weekday, including the empty ones, that is
exactly right; lesson 13's `groupby` has the same behaviour, and an `observed` argument for when you
want the empty groups left out.

## Ordered categories

When the values have an order, say so, and comparisons and sorting follow it rather than the
alphabet. `pd.cut` makes ordered categories from numbers, a band for each range:

```python
weather = pd.read_csv("weather.csv")
band = pd.cut(weather["rain_mm"], bins=[-0.1, 0, 10, 100], labels=["dry", "light", "heavy"])
band.dtype, band.value_counts(sort=False), (band > "light").sum()
```

```
(CategoricalDtype(categories=['dry', 'light', 'heavy'], ordered=True, categories_dtype=str),
 rain_mm
 dry      192
 light    104
 heavy     63
 Name: count, dtype: int64,
 np.int64(63))
```

`bins` are the edges: up to 0, over 0 to 10, over 10 to 100. The bands come out ordered, so
`band > "light"` means heavier than light, not later in the alphabet. And the six unread days are
`NaN`, in no band: `value_counts` leaves them out, and the three counts add up to 359, not 365.
