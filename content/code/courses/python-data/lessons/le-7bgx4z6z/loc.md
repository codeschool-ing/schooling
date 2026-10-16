---
title: loc, by label
version: 1
---

**`loc` takes a row selection and a column selection, separated by a comma, and both are labels.**
A single label, a list of labels, a slice of labels, or a boolean mask: each works on either side.

```python
weather.loc["2025-03-22", "rain_mm"]
```

```
np.float64(45.9)
```

One row, one column: one value. Leave a side out with `:` to mean "all":

```python
weather.loc["2025-03-22", :]
```

```
rain_mm     45.9
temp_max    30.0
Name: 2025-03-22, dtype: float64
```

## Slices of labels include the end

```python
weather.loc["2025-03-20":"2025-03-22", "rain_mm"]
```

```
date
2025-03-20    25.0
2025-03-21    14.3
2025-03-22    45.9
Name: rain_mm, dtype: float64
```

Three days, the 20th **and** the 22nd. A position slice in Python stops before its end; a label slice
cannot, because "the label before `2025-03-22`" is not something you could write. Lesson 9 met this;
here is the rule: **`loc` slices are closed at both ends, `iloc` slices at the start only.**

## Masks, with the columns chosen in the same step

The commonest use of `loc` is a condition on the rows and a choice of columns at once:

```python
wet = weather["rain_mm"] > 40
weather.loc[wet, ["rain_mm", "temp_max"]]
```

```
            rain_mm  temp_max
date                         
2025-03-22     45.9      30.0
2025-06-17     41.0      27.7
2025-07-01     41.4      28.5
2025-09-03     40.9      30.6
```

The mask is a boolean Series with the same index as `weather`, and `loc` keeps the rows where it is
`True`. Combine conditions with `&` and `|`, each in parentheses, exactly as lesson 7 did with NumPy:

```python
weather.loc[(weather["rain_mm"] > 20) & (weather["temp_max"] > 31), "rain_mm"]
```

```
date
2025-08-02    23.9
2025-08-14    21.0
Name: rain_mm, dtype: float64
```

## A label that is not there

```python
weather.loc["2025-02-30"]
```

```
KeyError: '2025-02-30'
```

`KeyError`, naming the label. That is a good failure: `loc` never quietly hands back something else
when the label you asked for does not exist.
