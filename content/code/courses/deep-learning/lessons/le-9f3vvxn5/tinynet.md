---
title: tinynet.py, the same rules for a whole batch
version: 1
---

`byhand.py` names every array, which is fine for nine weights and impossible for thousands. **The
module below turns each of the four rules into a class with two methods, `forward` and `backward`,
and a network into a list of those classes.** It is the whole of what lessons 3 to 8 train with.
Those lessons add an optimiser, dropout and normalisation beside it, and none of them changes this
file. Save it as `~/dl/tinynet.py`, beside the `digits.py` from lesson 1:

```schooling-example
{
  "language": "python",
  "file": "tinynet.py",
  "parts": [
    {
      "code": "\"\"\"tinynet: a neural network in NumPy, small enough to read in one sitting.\"\"\"\nimport numpy as np",
      "note": "The module lessons 3 to 8 build on. Nothing in it is hidden by a library: every gradient is a line you can read."
    },
    {
      "code": "class Linear:\n    \"\"\"y = x @ W + b on the way forward; the gradients of W, b and x on the way back.\"\"\"\n    params = (\"W\", \"b\")\n\n    def __init__(self, n_in, n_out, rng):\n        self.W = rng.normal(0, np.sqrt(2 / n_in), (n_in, n_out)).astype(np.float32)\n        self.b = np.zeros(n_out, dtype=np.float32)\n        self.dW = np.zeros_like(self.W)\n        self.db = np.zeros_like(self.b)\n\n    def forward(self, x):\n        self.x = x\n        return x @ self.W + self.b\n\n    def backward(self, grad):\n        self.dW[...] = self.x.T @ grad\n        self.db[...] = grad.sum(axis=0)\n        return grad @ self.W.T",
      "note": "`byhand.py`'s rules for a whole batch. `forward` keeps its input, because `backward` needs it: `x.T @ grad` is the input times the gradient, summed over the batch. The bias sums the gradient over the rows. What it returns, `grad @ W.T`, is the gradient for the layer below. The starting weights are random with a spread of √(2/n_in), a choice made for ReLU (He initialisation). `dW[...] =` writes into the same array every time, so an optimiser can hold on to it."
    },
    {
      "code": "class ReLU:\n    \"\"\"max(0, x), and a gradient that passes only where x was positive.\"\"\"\n\n    def forward(self, x):\n        self.mask = x > 0\n        return x * self.mask\n\n    def backward(self, grad):\n        return grad * self.mask",
      "note": "The `(z > 0)` of `byhand.py`, remembered from the forward pass. It has no parameters, so it has no `params`."
    },
    {
      "code": "class Net:\n    \"\"\"Layers in a row: forward runs them in order, backward in reverse.\"\"\"\n\n    def __init__(self, *layers):\n        self.layers = layers\n\n    def forward(self, x):\n        for layer in self.layers:\n            x = layer.forward(x)\n        return x\n\n    def backward(self, grad):\n        for layer in reversed(self.layers):\n            grad = layer.backward(grad)\n\n    def mode(self, training):\n        for layer in self.layers:\n            layer.training = training\n\n    def params(self):\n        \"\"\"(value, gradient) pairs: the arrays an optimiser changes in place.\"\"\"\n        return [(getattr(layer, k), getattr(layer, \"d\" + k))\n                for layer in self.layers for k in getattr(layer, \"params\", ())]",
      "note": "Backpropagation is the `reversed`. Each layer takes the gradient of its output and returns the gradient of its input, so a network of any depth is a loop. `mode` does nothing yet; lesson 7's dropout reads the flag it sets. `params` pairs each array with its gradient."
    },
    {
      "code": "def softmax_cross_entropy(logits, y):\n    \"\"\"The mean loss over a batch, and its gradient with respect to the logits.\"\"\"\n    z = logits - logits.max(axis=1, keepdims=True)\n    p = np.exp(z) / np.exp(z).sum(axis=1, keepdims=True)\n    rows = np.arange(len(y))\n    loss = -np.log(p[rows, y]).mean()\n    grad = p.copy()\n    grad[rows, y] -= 1\n    return loss, grad / len(y)",
      "note": "The loss for ten classes, taken as given here: lesson 4 is about it. It turns the ten outputs into probabilities and scores the probability of the right digit. What matters now is that it returns the gradient that starts the backward pass, the way `d_out` did in `byhand.py`."
    }
  ]
}
```

Three things to notice before using it.

**A layer keeps what its backward pass will need.** `Linear` keeps its input, `ReLU` keeps its mask.
That is the cost of backpropagation that nobody mentions: every intermediate value of the forward
pass stays in memory until the backward pass has used it. Lesson 19 measures that memory for a real
model.

**The batch is summed inside the product.** `self.x.T @ grad` is a 64 by 32 matrix times a 32 by
16 one, for a batch of 32 images entering 16 units. Each entry is one weight's gradient, added up
over the 32 images. For a batch of one, it is the outer product `byhand.py` wrote.

**`softmax_cross_entropy` is used as given.** It is the loss for choosing one of ten classes, and
lesson 4 is about why it is the right one. What matters here is its second return value, the
gradient that starts the backward pass, the way `d_out` did.

To see that the module computes what the hand did, build `byhand.py`'s network out of it and
overwrite the random weights with the hand-picked ones. Save as `~/dl/again.py`:

```schooling-example
{
  "language": "python",
  "file": "again.py",
  "parts": [
    {
      "code": "\"\"\"again: byhand.py's network, built from tinynet, gives the same gradients.\"\"\"\nimport numpy as np\n\nimport tinynet\n\nrng = np.random.default_rng(0)\nnet = tinynet.Net(tinynet.Linear(2, 2, rng), tinynet.ReLU(), tinynet.Linear(2, 1, rng))\nfirst, _, second = net.layers\nfirst.W[...] = [[0.5, -0.5], [0.25, 0.25]]\nfirst.b[...] = [0.0, -1.0]\nsecond.W[...] = [[1.5], [1.0]]\nsecond.b[...] = [0.25]",
      "note": "The same 2-2-1 network, with the random weights overwritten by `byhand.py`'s. The output layer's weights are a column here, because `Linear` always has a column per unit."
    },
    {
      "code": "out = net.forward(np.array([[1.0, 2.0]], dtype=np.float32))\nnet.backward(2 * (out - 1.0))\nfor value, gradient in net.params():\n    print(value.shape, gradient.ravel())",
      "note": "A batch of one image. The squared error's gradient is written by hand, since `tinynet` only carries the loss for classes."
    }
  ]
}
```

```
ana@vm:~/dl$ python again.py
(2, 2) [2.25 0.   4.5  0.  ]
(2,) [2.25 0.  ]
(2, 1) [1.5 0. ]
(1,) [1.5]
```

**The same numbers.** The first layer's weight gradient, flattened row by row, is 2.25, 0, 4.5, 0;
its bias gradient is 2.25 and 0; the output layer's are 1.5 and 0, and 1.5. The shapes are the
difference: the output weights are a 2 by 1 column here, because `Linear` always has one column per
unit.
