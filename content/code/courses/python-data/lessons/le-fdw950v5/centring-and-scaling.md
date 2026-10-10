---
title: Centring and scaling every column at once
version: 1
---

**The most common use of broadcasting in data work is putting columns on a common footing**:
subtract each column's mean, divide by each column's spread. It is one line, and the rule is why it
is one line.

The two weather columns are on different scales: rain from 0 to 45.9 millimetres, temperature
within a few degrees of 30. Take the days with a rain reading, so that every value is known:

```python
known = weather[~np.isnan(weather[:, 0])]
known.shape, known.mean(axis=0).round(2), known.std(axis=0).round(2)
```

```
((359, 2), array([ 4.77, 29.93]), array([8.09, 1.03]))
```

`~` turns `True` into `False` and back, so the mask keeps the rows whose rain is not `nan`; lesson 7
explains masks properly. The means and standard deviations come out with shape `(2,)`, one per
column, which lines up from the right with the `(359, 2)` table. So:

```python
z = (known - known.mean(axis=0)) / known.std(axis=0)
z.shape, z.mean(axis=0).round(6), z.std(axis=0).round(6)
```

```
((359, 2), array([0., 0.]), array([1., 1.]))
```

Every column now has mean 0 and standard deviation 1: a **z-score**, how many standard deviations a
value is from its column's mean. The wettest day and the hottest day can now be compared on one
scale:

```python
z[:, 0].max().round(2), z[:, 1].max().round(2)
```

```
(np.float64(5.08), np.float64(2.21))
```

The wettest day sits much further out in rain than the hottest day sits in temperature, which is a
statement about Recife's weather that the raw numbers, in millimetres and degrees, could not make.
The `machine-learning` course scales columns this way before most of its models, with a library
that does the same arithmetic.

## Scaling rows instead

To scale each **row** by its own numbers, the statistics have to keep their axis, as in the last
two sections. The share of each week's warmth carried by each day, as a fraction of the week's
total:

```python
share = weeks / weeks.sum(axis=1, keepdims=True)
share.shape, share.sum(axis=1)[:3]
```

```
((52, 7), array([1., 1., 1.]))
```

Each row sums to 1. Without `keepdims`, the `(52,)` would have met the `(52, 7)` from the right,
and the error from two sections ago would have been the result.
