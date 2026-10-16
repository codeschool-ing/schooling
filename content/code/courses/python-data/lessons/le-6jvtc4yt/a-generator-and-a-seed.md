---
title: A generator, and the seed that makes it repeat
version: 1
---

**A computer's random numbers are not random: they are a long, fixed sequence that looks random,
computed from a starting value called the seed.** Same seed, same sequence, on every run and every
machine. That is not a weakness to apologise for. It is what makes a sample, a shuffle or a
simulation something another person can check.

NumPy's tool is a **Generator**, made by `np.random.default_rng`:

```python
import numpy as np

rng = np.random.default_rng(2025)
rng.integers(1, 7, size=10)
```

```
array([3, 6, 6, 3, 6, 5, 4, 6, 5, 6])
```

Ten throws of a die, from the seed 2025. Make a second generator from the same seed and it throws
the same ten:

```python
again = np.random.default_rng(2025)
again.integers(1, 7, size=10)
```

```
array([3, 6, 6, 3, 6, 5, 4, 6, 5, 6])
```

`integers(1, 7)` includes the 1 and excludes the 7, like `range`. The generator keeps its place in
the sequence, so the **next** call on `rng` continues where the last one stopped instead of starting
again:

```python
rng.integers(1, 7, size=5), again.integers(1, 7, size=5)
```

```
(array([3, 1, 3, 2, 3]), array([3, 1, 3, 2, 3]))
```

Both generators have made ten draws, so both are at the same place and draw the same five. A
generator is a position in a sequence: the seed decides where it starts, and every draw moves it on.

## Without a seed

`default_rng()` with no argument asks the operating system for a fresh, unpredictable seed. Two such
generators draw different numbers, and nothing printed here would match your screen:

```python
a = np.random.default_rng().integers(0, 1_000_000, size=3)
b = np.random.default_rng().integers(0, 1_000_000, size=3)
(a == b).all()
```

```
np.False_
```

That is the right choice for anything that must not be predictable, and the wrong one for analysis.
**A notebook that draws without a seed gives a different answer on every run**, and lesson 2's
restart-and-run-all will pass it every time while its numbers move.

## Where the seed goes

Once, at the top of the notebook, with the other settings, and nowhere else:

```py
SEED = 2025
rng = np.random.default_rng(SEED)
```

Every random draw in the notebook then goes through that one `rng`. Any number you like works as a
seed; what matters is that it is written down, so the run can be repeated.
