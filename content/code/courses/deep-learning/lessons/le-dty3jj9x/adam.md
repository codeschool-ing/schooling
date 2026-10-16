---
title: "Adam: a step size for every parameter"
version: 1
---

The picture most people start with is one learning rate for the whole network. The rate is one
number, but **the step each weight takes is the rate times its own gradient**, and gradients inside
one network differ by orders of magnitude, between layers and between the weights of a layer. A rate
that suits the large ones barely moves the small ones, and a rate that suits the small ones throws
the large ones about.

Adam, published by Kingma and Ba in 2014, answers this by dividing each parameter's gradient by a
running measure of that parameter's own gradient size. It keeps two averages per parameter: `m`, of
the gradient, which is momentum's velocity in another form, and `v`, of the gradient squared. The
program below takes its first five steps on three made-up parameters. Save as `~/dl/adam_steps.py`:

```schooling-example
{
  "language": "python",
  "file": "adam_steps.py",
  "parts": [
    {
      "code": "\"\"\"adam_steps: Adam's first steps on three parameters with very different gradients.\"\"\"\nimport numpy as np\n\nlr, b1, b2, eps = 0.001, 0.9, 0.999, 1e-8\nm, v = np.zeros(3), np.zeros(3)\nnp.set_printoptions(precision=6, suppress=True)",
      "note": "Adam's settings as almost everybody leaves them: a rate of 0.001, `beta1` 0.9 for the average of the gradient, `beta2` 0.999 for the average of its square. Both averages start at zero."
    },
    {
      "code": "def gradient(t):\n    \"\"\"A large steady gradient, a small steady one, and a small one that flips sign.\"\"\"\n    return np.array([100.0, 0.01, 0.01 * (-1) ** (t + 1)])",
      "note": "Three parameters, made up so that each shows one thing: a gradient of 100 at every step, one of 0.01 at every step, and one of 0.01 whose sign flips each time."
    },
    {
      "code": "print(\"plain SGD at the same rate steps\", lr * gradient(1))\nfor t in range(1, 6):\n    g = gradient(t)\n    m = b1 * m + (1 - b1) * g\n    v = b2 * v + (1 - b2) * g * g",
      "note": "`m` follows the gradient and `v` follows its square, each a running average that keeps most of its old value. Every operation is element by element, so each parameter has an `m` and a `v` of its own."
    },
    {
      "code": "    m_hat = m / (1 - b1 ** t)\n    v_hat = v / (1 - b2 ** t)\n    step = lr * m_hat / (np.sqrt(v_hat) + eps)\n    uncorrected = lr * m / (np.sqrt(v) + eps)\n    print(f\"step {t}: Adam {step}   uncorrected {uncorrected}\")",
      "note": "The correction divides each average by how much of it has been filled so far: `1 - 0.9 ** 1` is 0.1 after one step. The step is the averaged gradient over the square root of the averaged square, so its size no longer depends on the gradient's."
    }
  ]
}
```

```
ana@vm:~/dl$ python adam_steps.py
plain SGD at the same rate steps [0.1     0.00001 0.00001]
step 1: Adam [0.001 0.001 0.001]   uncorrected [0.003162 0.003162 0.003162]
step 2: Adam [ 0.001     0.001    -0.000053]   uncorrected [ 0.00425   0.004249 -0.000224]
step 3: Adam [0.001    0.001    0.000336]   uncorrected [0.00495  0.00495  0.001662]
step 4: Adam [ 0.001     0.001    -0.000053]   uncorrected [ 0.005442  0.005442 -0.000286]
step 5: Adam [0.001    0.001    0.000204]   uncorrected [0.005797 0.005797 0.001185]
```

Three things in that table.

**The scale is gone.** Plain SGD at the same rate would move the first parameter by 0.1 and the
second by 0.00001, ten thousand times less. Adam moves both by 0.001, which is the rate itself. For a
gradient that keeps its sign, `m_hat` over the square root of `v_hat` is 1, so in Adam **the rate is
roughly the size of a step**, measured in the parameter's own units. That is why one default, 0.001,
is a reasonable first try on networks that have nothing else in common.

**A gradient that keeps changing its mind gets small steps.** The third parameter's gradient is as
large as the second's, but its sign flips. In `m` the plus and the minus nearly cancel, while `v`
averages squares and cannot cancel, and after the first step, which has seen one gradient only, the
steps come out at 0.000053, 0.000336, 0.000053 and 0.000204: a fraction of the rate, in alternating
directions.

**The correction matters at the start, and in the direction few people guess.** `m` and `v` start at
zero, so after the first step `m` holds a tenth of the gradient and `v` a thousandth of its square.
The thousandth is the smaller fraction, and its square root is about 0.0316, so the uncorrected
ratio is 0.1 / 0.0316: the first step is 0.003162, more than three times the rate. By step 5 it is
0.005797, almost six. Without the correction Adam's first steps are too large, at the moment a fresh
network is least ready for large steps. Dividing `m` by `1 - 0.9 ** t` and `v` by `1 - 0.999 ** t`
brings both back to scale, and the steps are 0.001 from the first one.

**Adam is momentum plus a scale for every parameter**, and it is the usual first choice today because
it needs the least tuning to work at all. Least is not none: the sweep
two sections on shows its rate mattering as much as anybody's. AdamW, the variant behind most large
models, changes only how weight decay is applied, which is lesson 7's subject.
