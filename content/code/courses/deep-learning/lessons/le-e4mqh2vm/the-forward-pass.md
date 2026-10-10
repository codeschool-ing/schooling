---
title: The forward pass, with one weight
version: 1
---

Lesson 1 ended with a network whose weights were written by hand. Nobody trains a real network
that way. **Training is a program searching for those numbers**, and the search needs three
things this lesson builds one at a time: a prediction, a measure of how wrong it is, and a rule for
which way to move. The model here has a single weight, so every one of the three can be printed and
checked by eye.

A **forward pass** is the computation from the input to the prediction, with the weights held
still. In lesson 1's `layer.py` it was `x @ W + b` followed by ReLU. Here it is `w * x`: a straight
line through zero whose slope is the weight. The name says which way the numbers flow, from the
input forward through the layers, and lesson 3 sends something back the other way.

The data is ten points, made by a program short enough to read at a glance. Save it as
`~/dl/points.py`:

```python
# points.py: ten points, made by a straight line plus noise that never changes
import numpy as np

x = np.arange(1, 11) / 10
noise = np.random.default_rng(0).normal(0, 0.2, 10)
y = (2 * x + 1 + noise).round(2)
```

`x` runs from 0.1 to 1.0. Each `y` is a line with slope 2 that crosses zero at height 1, plus noise
from a generator with a fixed seed, so every machine gets the same ten values. Rounding to two
decimals keeps the arithmetic of the next section small enough to do by hand. **The model is told
none of this.** It sees ten pairs of numbers.

Now the forward pass, for whatever weight you give it on the command line. Save as
`~/dl/forward.py`:

```python
# forward.py: the model's prediction for every point, at the weight you give it
import sys

from points import x, y

w = float(sys.argv[1])
prediction = w * x
for xi, yi, pi in zip(x, y, prediction):
    print(f"x {xi:.1f}   y {yi:.2f}   w*x {pi:.2f}   error {pi - yi:+.2f}")
```

```
ana@vm:~/dl$ python forward.py 2
x 0.1   y 1.23   w*x 0.20   error -1.03
x 0.2   y 1.37   w*x 0.40   error -0.97
x 0.3   y 1.73   w*x 0.60   error -1.13
x 0.4   y 1.82   w*x 0.80   error -1.02
x 0.5   y 1.89   w*x 1.00   error -0.89
x 0.6   y 2.27   w*x 1.20   error -1.07
x 0.7   y 2.66   w*x 1.40   error -1.26
x 0.8   y 2.79   w*x 1.60   error -1.19
x 0.9   y 2.66   w*x 1.80   error -0.86
x 1.0   y 2.75   w*x 2.00   error -0.75
```

At `w = 2`, the very slope the points were made with, **every prediction is too low**, by between
0.75 and 1.26. A line forced through zero cannot add the 1 the points were built on, so the right
slope misses all ten. The weight that misses least is somewhere else, and finding it is the rest of
this lesson.

Two things to notice in the program. The prediction is computed for all ten points in one
operation, `w * x` on an array, which is the habit lesson 1's matrix product started. And nothing
in it learns. A forward pass only answers; learning is what happens between two of them.
