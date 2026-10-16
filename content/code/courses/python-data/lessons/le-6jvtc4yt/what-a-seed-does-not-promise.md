---
title: What a seed does not promise
version: 1
---

**A seed makes a run repeatable on the same code with the same libraries. It does not make a result
true, and it does not freeze the numbers forever.** Three limits, each one a way a seeded notebook
can still surprise you.

## Across versions of NumPy

NumPy guarantees that the old global functions, `np.random.seed` and the rest, will produce the same
numbers for the same seed in every future version: that interface is frozen, which is part of why it
is still around. It does **not** make that promise for the Generator's methods. A later NumPy may
improve the algorithm behind `rng.normal` or `rng.choice`, and the same seed will then give
different numbers. That is one more reason lesson 3 pins `numpy==2.5.3`: the seed reproduces a run
only together with the version it ran on.

## Across parallel work

Two pieces of work that each need random numbers, a simulation split across processes, for
instance, must not share one generator, and must not each be seeded with `2025`, which would make
them draw the same numbers. A generator can **spawn** children whose streams are independent of
each other and of the parent:

```python
parent = np.random.default_rng(2025)
children = parent.spawn(3)
[c.integers(0, 100, size=3) for c in children]
```

```
[array([87, 99, 72]), array([53, 71, 62]), array([ 5, 72, 24])]
```

Three generators, three different streams, all reproducible from the one seed. Give each worker one.

## Against yourself

The seed is a number you chose, and a different one gives a different sample, a different split, a
different bootstrap interval. **Trying seeds until the result looks good is a way of choosing the
result**, and nothing in the notebook would show it was done: the code shows one seed and a
satisfying number. The defences are habits:

- choose the seed before you look at the results, write it at the top, and leave it alone;
- when a result depends on randomness, run it under several seeds, as the bootstrap section did,
  and report the spread rather than the best;
- if a conclusion changes with the seed, the conclusion was the noise.

The `machine-learning` course splits data into training and test sets with exactly this kind of
seeded shuffle, and the same three habits apply there with more at stake.
