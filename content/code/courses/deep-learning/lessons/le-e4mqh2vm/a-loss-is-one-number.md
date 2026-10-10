---
title: A loss is one number
version: 1
---

Ten errors are ten numbers, and ten numbers cannot say whether `w = 3` is better than `w = 2`: some
may shrink while others grow. **Training needs one number that goes down when the predictions get
better.** That number is the **loss**. The first one to know is the **mean squared error**: square
each error, then take the mean.

The square does two jobs. It makes every error count as a positive amount, so a prediction 1.03 too
high and another 1.03 too low cannot cancel into a perfect score. And it makes a large error count
far more than a small one: an error of 2 costs four times what an error of 1 does. Lesson 4 looks
at when that second job is the wrong one to want.

By hand, at `w = 2`, with the errors `forward.py` printed: the first is -1.03 and its square is
1.0609. Square all ten, add them, divide by ten. Save as `~/dl/loss.py`, which does that sum first
and then the loss at six weights:

```python
# loss.py: mean squared error, one number for how wrong a weight is
import numpy as np

from points import x, y


def loss(w):
    return np.mean((w * x - y) ** 2)


errors = 2 * x - y
print("squared errors at w = 2:", (errors ** 2).round(4))
print(f"sum {np.sum(errors ** 2):.4f}   mean {np.mean(errors ** 2):.4f}")
for w in [0, 1, 2, 3, 4, 5]:
    print(f"w {w}   loss {loss(w):.4f}")
```

```
ana@vm:~/dl$ python loss.py
squared errors at w = 2: [1.0609 0.9409 1.2769 1.0404 0.7921 1.1449 1.5876 1.4161 0.7396 0.5625]
sum 10.5619   mean 1.0562
w 0   loss 4.7918
w 1   loss 2.5390
w 2   loss 1.0562
w 3   loss 0.3434
w 4   loss 0.4006
w 5   loss 1.2278
```

The squares add to 10.5619 and their mean is 1.0562, which is the loss at `w = 2` on the table's
third line. **Down the table, the loss falls from 4.7918 at `w = 0`, reaches its lowest between 3
and 4, and rises again.** 0.3434 at 3 against 0.4006 at 4 puts the best weight between them, nearer
3.

**For this model the curve is a parabola.** Each point contributes `(w*x - y)²`, which is a
quadratic in `w`, and a sum of quadratics is one quadratic. The next section draws it. A network's
loss has a dimension per weight and more than one dip, but the question asked of it is the same:
where is it lowest?

Six tries narrowed the answer to a gap one unit wide, and more tries would narrow it further. That
is a fine way to search one weight and a hopeless way to search many. Ten candidate values for each
of the 1,040 parameters of lesson 1's layer is 10 to the power 1,040 evaluations. What is needed is
a direction rather than a grid.
