---
title: Gradient descent, step by step
version: 1
---

The rule follows from the signs: **move against the slope.** A negative slope means step right and
a positive one means step left, and steeper ground means a longer step. In one line it is
`w = w - lr * slope`, where `lr`, the **learning rate**, says how far to go per unit of slope.
Repeat until the slope is zero. That is **gradient descent**, and every network in this course is
trained by some version of it.

Save as `~/dl/descent.py`:

```schooling-example
{
  "language": "python",
  "file": "descent.py",
  "parts": [
    {
      "code": "# descent.py: gradient descent on one weight, printed step by step\nimport numpy as np\n\nfrom points import x, y"
    },
    {
      "code": "w, lr = 0.0, 1.0\nfor step in range(12):\n    loss = np.mean((w * x - y) ** 2)\n    grad = np.mean(2 * x * (w * x - y))\n    print(f\"step {step:2d}   w {w:.4f}   loss {loss:.4f}   slope {grad:+.4f}\")\n    w = w - lr * grad",
      "note": "One pass of the loop is one step: the loss and the slope at the current weight, printed, and then the update. The last line is gradient descent. Lesson 3 is about computing `grad` when there are thousands of weights, and lesson 5 about choosing the step."
    },
    {
      "code": "best = np.sum(x * y) / np.sum(x * x)\nprint(f\"closed form   w {best:.4f}\")",
      "note": "The bottom found by algebra instead: set the slope to zero and solve for `w`. Descent should land on the same number."
    }
  ]
}
```

```
ana@vm:~/dl$ python descent.py
step  0   w 0.0000   loss 4.7918   slope -2.6378
step  1   w 2.6378   loss 0.5126   slope -0.6067
step  2   w 3.2445   loss 0.2863   slope -0.1395
step  3   w 3.3840   loss 0.2743   slope -0.0321
step  4   w 3.4161   loss 0.2737   slope -0.0074
step  5   w 3.4235   loss 0.2736   slope -0.0017
step  6   w 3.4252   loss 0.2736   slope -0.0004
step  7   w 3.4256   loss 0.2736   slope -0.0001
step  8   w 3.4257   loss 0.2736   slope -0.0000
step  9   w 3.4257   loss 0.2736   slope -0.0000
step 10   w 3.4257   loss 0.2736   slope -0.0000
step 11   w 3.4257   loss 0.2736   slope -0.0000
closed form   w 3.4257
```

**The first step is the longest**, from 0 to 2.6378: the slope at 0 is -2.6378 and the rate is 1, so
the step is the slope with its sign turned round. Each later step is shorter, because the slope
shrinks as the weight nears the bottom: 0.6067, then 0.1395, then 0.0321. By step 8 the weight has
stopped moving in the fourth decimal, at 3.4257, with a loss of 0.2736.

**The last line checks it.** For this model the bottom can also be found by algebra. Set the slope
to zero, `mean(2x(w*x - y)) = 0`, and solve for `w`: it is `Σxy / Σx²`, which is 3.4257, the
number eight steps of descent arrived at. That formula is the least-squares line through zero: the
criterion `machine-learning` used to fit a linear regression.

So why descend, when algebra gets there in one line? Because the algebra exists only for models
whose loss is a parabola in their weights. Put a ReLU between two layers and there is no formula
for the bottom, but there is still a slope at every point, and descent needs nothing else. The
price is that descent finds a bottom near where it started, which is not always the lowest one
there is. Networks are trained that way regardless, because nothing better is known at their size.

**Notice what 3.4257 is: the best this model can do, not the slope the points were made with.** The
points came from a line of slope 2 at height 1, and a line forced through zero has to tilt more
steeply to get near them. A slope of 3.43 is the tilt that misses least, and the 0.2736 left over
is a loss no weight can lower. The last section of this lesson gives the model the parameter it is
missing.
