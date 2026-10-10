---
title: The 2-2-1 network, number by number
version: 1
---

The graph in the last section is a drawing, and a drawing can be wrong. **This program computes
every number on it, with nothing but NumPy and the four rules.** Each line of the backward pass is
one rule applied to one node, in the reverse of the order the forward pass ran. Save as
`~/dl/byhand.py`:

```schooling-example
{
  "language": "python",
  "file": "byhand.py",
  "parts": [
    {
      "code": "\"\"\"byhand: a 2-2-1 network, forward and backward, one number at a time.\"\"\"\nimport numpy as np\n\nx = np.array([1.0, 2.0])\ny = 1.0\nW1 = np.array([[0.5, -0.5],\n               [0.25, 0.25]])\nb1 = np.array([0.0, -1.0])\nW2 = np.array([1.5, 1.0])\nb2 = 0.25",
      "note": "Two inputs, two hidden units, one output, and every weight written out. They were chosen so that the arithmetic can be followed by hand, and so that hidden unit 2 comes out negative."
    },
    {
      "code": "z = x @ W1 + b1\nh = np.maximum(0, z)\nout = h @ W2 + b2\nL = (out - y) ** 2\nprint(\"forward   z\", z, \" h\", h, \" out\", out, \" L\", L)",
      "note": "The forward pass of lesson 1, followed by lesson 2's squared error. Every intermediate array is kept in its own name."
    },
    {
      "code": "d_out = 2 * (out - y)\ndW2 = h * d_out\ndb2 = d_out",
      "note": "The backward pass starts at the loss. `d_out` is how much the loss moves per unit of output. A weight of the last layer gets that times the value it multiplied, and the bias gets it as it is."
    },
    {
      "code": "dh = W2 * d_out\ndz = dh * (z > 0)\ndW1 = np.outer(x, dz)\ndb1 = dz\ndx = W1 @ dz\nprint(\"backward  d_out\", d_out, \" dW2\", dW2, \" db2\", db2)\nprint(\"          dh\", dh, \" dz\", dz, \" db1\", db1)\nprint(\"          dW1\", dW1.tolist(), \" dx\", dx)",
      "note": "One layer back. Each hidden output gets `d_out` times the weight that carried it forward. ReLU passes it only where `z` was positive. Then the same rule as above: a weight's gradient is its input times the gradient arriving at its unit."
    },
    {
      "code": "lr = 0.05\nW1, b1, W2, b2 = W1 - lr * dW1, b1 - lr * db1, W2 - lr * dW2, b2 - lr * db2\nout = np.maximum(0, x @ W1 + b1) @ W2 + b2\nprint(\"one step  out\", round(out, 4), \" L\", round((out - y) ** 2, 4))",
      "note": "What the gradients are for: one step of lesson 2's gradient descent on all nine numbers at once, and the forward pass again."
    }
  ]
}
```

```
ana@vm:~/dl$ python byhand.py
forward   z [ 1. -1.]  h [1. 0.]  out 1.75  L 0.5625
backward  d_out 1.5  dW2 [1.5 0. ]  db2 1.5
          dh [2.25 1.5 ]  dz [2.25 0.  ]  db1 [2.25 0.  ]
          dW1 [[2.25, 0.0], [4.5, 0.0]]  dx [1.125  0.5625]
one step  out 0.6381  L 0.131
```

Read the backward lines from the top, because that is the order they were computed in.

- `d_out` is 1.5: twice the error of 0.75. The output bias gets it unchanged, `db2`.
- `dW2` is `[1.5 0.]`. Each output weight gets 1.5 times the hidden value it multiplied, and
  `h2` was 0, so the weight from `h2` gets nothing.
- `dh` is `[2.25 1.5]`: 1.5 times each output weight. Both hidden outputs would change the loss
  if they moved.
- `dz` is `[2.25 0.]`. ReLU lets the 2.25 through and stops the 1.5, because `z2` was -1. This
  is the line that makes unit 2 untrainable on this input.
- `dW1` is `[[2.25, 0.0], [4.5, 0.0]]`: rows are inputs, columns are hidden units. The weight
  from `x2` gets twice what the weight from `x1` gets, because `x2` is twice as large, and the
  column of the dead unit is all zeros.
- `dx` is `[1.125 0.5625]`: the sum at each input's fork, which only a deeper network would use.

**The last line is the point of all of it.** One step of gradient descent with a rate of 0.05 moved
all nine numbers at once, and the loss fell from 0.5625 to 0.131. The output went from 1.75 to
0.6381, past the target of 1 on the other side: a step that size overshoots on this input, which is
lesson 2's learning rate at work again.

Count the cost. The forward pass did one product per weight, and the backward pass did
about two: one for the weight's gradient and one to pass the gradient on. **Getting all nine
gradients cost roughly twice a forward pass, where nudging would have cost eighteen.** Lesson 9
builds this same network in PyTorch, and its automatic gradients print these same numbers.
