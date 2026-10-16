---
title: Drawing from a distribution
version: 1
---

**A Generator draws from dozens of distributions, each with the parameters that describe it.** You
choose the shape that matches how the thing you are simulating behaves, and the generator supplies
values with that shape. Four do most of the work in data science.

```python
rng = np.random.default_rng(2025)
heights = rng.normal(loc=170, scale=8, size=10_000)
heights.mean().round(2), heights.std().round(2)
```

```
(np.float64(170.03), np.float64(8.04))
```

**Normal**, the bell curve: `loc` is the mean and `scale` the standard deviation. Ten thousand
draws come back with a mean and a spread close to the ones asked for, and not exactly equal to them,
which is what a sample is.

```python
arrivals = rng.poisson(lam=4, size=10_000)
arrivals[:10], arrivals.mean().round(3)
```

```
(array([2, 2, 3, 4, 5, 1, 1, 5, 5, 3]), np.float64(3.944))
```

**Poisson**, counts of events in a fixed interval when they happen independently at a steady rate:
`lam` is the average count. Trips per hour at a station, calls per minute at a desk. Every value is a
whole number, never negative.

```python
gaps = rng.exponential(scale=15, size=10_000)
gaps.mean().round(2), (gaps > 45).mean().round(3)
```

```
(np.float64(14.85), np.float64(0.047))
```

**Exponential**, the waiting time between Poisson events: `scale` is the mean wait. Mostly short,
occasionally long. The share of waits over three times the mean comes out near 5%, which is a
property of this shape and a useful thing to know about queues.

```python
plans = rng.choice(["annual", "day"], size=10_000, p=[0.7, 0.3])
(plans == "day").mean()
```

```
np.float64(0.2908)
```

**Choice with probabilities**, for categories: each draw is one of the items, with the
probabilities in `p`, which must add up to 1.

## Seeing the shape

A summary number cannot tell a bell from a skewed tail. A histogram can, and `np.histogram` counts how
many values fall into each of a set of bins without drawing anything:

```python
counts, edges = np.histogram(gaps, bins=[0, 15, 30, 45, 60, 1000])
counts
```

```
array([6387, 2291,  854,  277,  191])
```

More than half the waits under the mean of 15, and a long tail beyond. Lesson 18 draws histograms;
the counts are the same either way.
