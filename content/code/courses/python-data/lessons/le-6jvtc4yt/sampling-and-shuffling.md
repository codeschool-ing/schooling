---
title: Samples, shuffles and a bootstrap
version: 1
---

**The most common random operation in analysis is not drawing numbers from a shape; it is choosing
some of the rows you already have.** A sample to look at, a shuffle to split data, a resample to ask
how much a statistic would move if the data had come out slightly differently.

The rain, with the six unread days set aside, as lesson 7 did it:

```python
weather = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=(1, 2))
rain = weather[:, 0]
known = rain[~np.isnan(rain)]
rng = np.random.default_rng(7)
```

## A sample

```python
days = rng.choice(len(known), size=5, replace=False)
days, known[days]
```

```
(array([222, 244, 335, 207, 321]), array([21. ,  0. ,  0. ,  0. ,  0.4]))
```

`replace=False` means no position is chosen twice, which is what "a sample of five days" means.
Choose positions rather than values, as lesson 5 sorted positions: the same positions then pick the
matching dates, temperatures or anything else in step.

## A shuffle

```python
order = rng.permutation(10)
order
```

```
array([3, 2, 6, 8, 1, 5, 0, 7, 4, 9])
```

`permutation(n)` is the numbers 0 to n − 1 in a random order, a new array. Indexing with it shuffles
any array of that length without touching the original; `rng.shuffle(a)` does the same **in place**,
changing `a` itself. The first is the safer default, for lesson 4's reasons.

## A bootstrap

How sure is the mean daily rain, 4.77 mm? The data is one year; a different year would have given a
different mean. The **bootstrap** imitates "a different year" by drawing 359 days **with**
replacement from the 359 we have, many times, and looking at how the mean moves:

```python
means = np.array([rng.choice(known, size=len(known), replace=True).mean() for _ in range(2000)])
known.mean().round(3), np.percentile(means, [2.5, 97.5]).round(2)
```

```
(np.float64(4.771), array([3.9 , 5.63]))
```

Two thousand resampled years, and the middle 95% of their means. The interval says that, by this
year's own evidence, the average day's rain could plausibly sit anywhere in that range. That is a
loop, and it is fine: two thousand iterations of a vectorised mean.

The interval is a random result, and a seed makes it a reproducible one. **Change the seed and the
endpoints move in the second decimal**:

```python
for seed in (1, 2, 3):
    r = np.random.default_rng(seed)
    m = np.array([r.choice(known, size=len(known)).mean() for _ in range(2000)])
    print(seed, np.percentile(m, [2.5, 97.5]).round(2))
```

```
1 [3.92 5.61]
2 [3.98 5.63]
3 [3.99 5.62]
```

That spread is the honest size of the simulation's own noise. The `statistics` course is where the
bootstrap is argued properly; here the point is the seed.
