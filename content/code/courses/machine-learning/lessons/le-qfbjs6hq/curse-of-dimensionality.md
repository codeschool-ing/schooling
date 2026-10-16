---
title: The curse of dimensionality
version: 1
---

Nearest neighbours assumes that some training rows are near and others far. **In many dimensions,
that stops being true**: every point ends up almost equally far from every other, and "nearest"
means very little. This is the curse of dimensionality, and it can be measured with nothing but
random numbers. Save this as `curse.py`:

```python
# curse.py
import numpy as np

rng = np.random.default_rng(0)
print("columns   nearest / farthest distance from one point to 1,000 others")
for d in [2, 10, 100, 1000]:
    points = rng.random((1001, d))
    gaps = np.linalg.norm(points[1:] - points[0], axis=1)
    print(f"{d:7}   {gaps.min() / gaps.max():.2f}")
```

```
ana@lab:~/ml$ python curse.py
columns   nearest / farthest distance from one point to 1,000 others
      2   0.01
     10   0.26
    100   0.67
   1000   0.89
```

The number printed is the distance to the nearest of 1,000 random points divided by the distance to
the farthest. In two dimensions it is **0.01**: the nearest point is a hundred times closer than the
farthest, and a neighbourhood is a meaningful thing. In a thousand dimensions it is **0.89**: the
nearest point is barely closer than the farthest, and the k "nearest" are an arbitrary handful from a
crowd that is all about the same distance away.

The reason is arithmetic. A distance adds up a difference per column; with many columns, the total
is a sum of many small random parts, and sums of many random parts all land close to the same value.
The spread between near and far shrinks relative to the distances themselves.

Real data is kinder than uniform random numbers, because real columns are related and the rows lie
on something far smaller than the full space. Feira em Casa's eleven numeric columns are no problem.
The curse bites in three common situations:

- **text**, where every distinct word is a column and there are thousands of them;
- **one-hot columns** for categories with many values, a city among five thousand, which add
  thousands of mostly-zero axes;
- **many weak columns thrown in together**, each adding a little noise to every distance.

The remedies are fewer, better columns (lesson 14), a reduction of the space before measuring
distance (lesson 17), or a model that does not rely on distance at all. Trees, which lessons 7 and 8
build, split one column at a time and are hardly troubled by the curse, which is part of why they
handle wide data so well.
