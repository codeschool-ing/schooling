---
title: The program that made the data, read at last
version: 1
---

**Lesson 1 asked you to run `make_data.py` and trust it. Its random half can be read now.** The whole
program depends on one line, `rng = np.random.default_rng(2025)`, and on drawing everything from
that one generator in a fixed order. That is the reason your three files are byte for byte the
course's.

Here are the draws it makes, in the order it makes them, each with the distribution chosen and why:

| line in `make_data.py` | distribution | what it models |
|---|---|---|
| `rng.integers(10, 21, size=20)` | uniform integers | docks per station, 10 to 20 |
| `rng.gamma(1.2, 9, 365)` | gamma | the depth of rain on a wet day: never negative, usually small, sometimes large |
| `rng.random(365) < …` | uniform, compared | whether a day is wet at all: 70% in the rainy months, 30% otherwise |
| `rng.normal(0, 0.8, 365)` | normal | the day's deviation from the season's temperature |
| `rng.choice(365, size=6, replace=False)` | sample | the six days whose rain reading is lost |
| `rng.poisson(…)` | Poisson | trips per day, around 110 on weekdays and 70 at weekends, fewer when it rains hard |
| `rng.choice(24, n, p=…)` | choice with probabilities | the hour a trip starts, with commuting peaks on weekdays |
| `rng.dirichlet(np.full(20, 2.0))` | Dirichlet | how popular each station is: twenty shares that add up to 1 |
| `rng.lognormal(2.6, 0.5, n)` | log-normal | trip length in minutes: most around a quarter of an hour, a long tail |
| `rng.random(n) < 0.004` | uniform, compared | the bikes that never come back |

Two things about that list matter more than the distributions.

**The order is part of the seed.** Swap two of those lines and every number after the swap changes,
because each draw starts where the previous one stopped. The program is reproducible as a whole,
not line by line.

**Everything is drawn in arrays, not in loops.** `rng.poisson(…)` returns 365 days of counts in one
call, and `rng.choice(24, n, p=…)` returns an hour for each of the 33,337 trips. A loop drawing one
trip at a time would give the same kind of data and different numbers, and take far longer.

You can check the program against your files directly. The generator, restarted from the same seed
and asked for the same first draw, gives the docks in `stations.csv`:

```python
np.random.default_rng(2025).integers(10, 21, size=20)[:5]
```

```
array([14, 20, 20, 14, 20])
```

```python
np.genfromtxt("stations.csv", delimiter=",", skip_header=1, usecols=2)[:5]
```

```
array([14., 20., 20., 14., 20.])
```
