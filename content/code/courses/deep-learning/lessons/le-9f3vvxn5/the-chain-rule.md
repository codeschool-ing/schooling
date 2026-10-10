---
title: The chain rule, on one unit
version: 1
---

Lesson 2 found the slope of the loss by moving a weight a little and measuring the loss again. That
works for one weight. **A network has thousands, and nudging each one in turn costs two forward
passes per weight per step.** The 64-16-10 network checked later in this lesson has 1,210 weights,
so a single step would need 2,420 forward passes over the batch.

Backpropagation gets every one of those slopes from one forward pass and one backward pass. It is
not an approximation and it is not a trick of the frameworks. **It is the chain rule from calculus,
applied in an order that never computes anything twice.**

## Three steps, three local derivatives

One unit already shows the whole idea. With an input `x`, a weight `w` and a bias `b`, it computes
in three steps, and the loss is lesson 2's squared error against the target `y`:

```
z = w·x + b        a = sigmoid(z)        L = (a − y)²
```

Each step has a derivative that only knows about that step. The square's is `2(a − y)`. The
sigmoid's is `a(1 − a)`, which can be read off its own output. The sum's, with respect to `w`, is
`x`. The chain rule says the derivative of the whole is the product of the parts:

```
dL/dw = dL/da · da/dz · dz/dw
```

Save as `~/dl/chain.py` and run it:

```schooling-example
{
  "language": "python",
  "file": "chain.py",
  "parts": [
    {
      "code": "\"\"\"chain: one unit, three steps, and the derivative of the loss through all of them.\"\"\"\nimport numpy as np\n\nx, y = 1.5, 1.0\nw, b = 0.8, -0.5",
      "note": "One input, the answer it should give, and one unit with a weight and a bias. The question is how the loss changes when `w` moves."
    },
    {
      "code": "def loss(w):\n    z = w * x + b\n    a = 1 / (1 + np.exp(-z))\n    return (a - y) ** 2",
      "note": "The whole computation as a function of `w`: a sum, a sigmoid, a squared error. It exists only for the check at the end."
    },
    {
      "code": "z = w * x + b\na = 1 / (1 + np.exp(-z))\nL = (a - y) ** 2\nprint(f\"forward:  z = {z:.4f}   a = {a:.4f}   L = {L:.4f}\")",
      "note": "The forward pass, keeping every intermediate value. The backward pass needs them: each local derivative is evaluated where the forward pass went."
    },
    {
      "code": "dL_da = 2 * (a - y)\nda_dz = a * (1 - a)\ndz_dw = x\nprint(f\"local:    dL/da = {dL_da:.4f}   da/dz = {da_dz:.4f}   dz/dw = {dz_dw:.4f}\")\nprint(f\"chain:    dL/dw = {dL_da * da_dz * dz_dw:.6f}\")",
      "note": "Three local derivatives, each knowing only its own step: the square's, the sigmoid's (`a·(1−a)`, read off its output), and the sum's, which is the input. The chain rule multiplies them."
    },
    {
      "code": "h = 1e-6\nprint(f\"nudge w:  dL/dw = {(loss(w + h) - loss(w - h)) / (2 * h):.6f}\")",
      "note": "Lesson 2's check: move `w` a millionth each way and measure the loss. It needs no calculus, and it costs two whole forward passes for one weight."
    }
  ]
}
```

```
ana@vm:~/dl$ python chain.py
forward:  z = 0.7000   a = 0.6682   L = 0.1101
local:    dL/da = -0.6636   da/dz = 0.2217   dz/dw = 1.5000
chain:    dL/dw = -0.220701
nudge w:  dL/dw = -0.220701
```

**The product and the nudge agree to six decimals**, at -0.220701. The sign is the useful part: the
unit outputs 0.6682 where the target is 1, so a larger `w` would lower the loss, and gradient
descent will move `w` up.

Two things in the program matter for everything that follows. **Every local derivative is evaluated
at a value the forward pass computed**: `a` for the square and for the sigmoid, `x` for the sum. So
the forward pass keeps its intermediate values, and the backward pass reads them. And the sigmoid's
factor here is 0.2217. It can never be larger than 0.25, and the last section of this lesson shows
what that does when ten of them are multiplied together.
