---
title: Dropout, and the training flag
version: 1
---

A wide layer can let its units divide the work into private arrangements: one unit fires for a
particular stroke because three others always fire with it. On 100 images, an arrangement like that
can fit one picture and nothing else. **Dropout breaks them by removing units at random while
training.** At every step, each unit of a hidden layer is switched off with probability `p`, a
different set each time, so no unit can count on any other being there.

Two details make it work, and both are in the layer below.

**The survivors are scaled up.** With `p = 0.5`, half the units are off, so the next layer receives
about half the sum it would without dropout. Dividing the survivors by `1 - p` puts the expected sum
back where it was. That is *inverted* dropout, and it is the version frameworks use, because it leaves
evaluation with nothing to correct.

**At evaluation, nothing is dropped.** The network you measure and deploy uses every unit. That is what
the `training` flag is for: `Net.mode` from lesson 3 sets it on every layer, and the `fit` of lesson 5
switches it off while it evaluates and back on to train. Forget the switch and your validation numbers
come from a network that throws away half of itself at random.

Save as `~/dl/dropout.py`:

```schooling-example
{
  "language": "python",
  "file": "dropout.py",
  "parts": [
    {
      "code": "\"\"\"dropout: a layer that switches off a random share of units while training.\"\"\"\nimport numpy as np\n\nfrom tinynet import Linear, Net, ReLU",
      "note": "Nothing new to import: the layer only needs NumPy."
    },
    {
      "code": "class Dropout:\n    def __init__(self, p, rng):\n        self.p, self.rng, self.training = p, rng, True\n\n    def forward(self, x):\n        if not self.training:\n            return x\n        self.mask = (self.rng.random(x.shape) >= self.p) / (1 - self.p)\n        return x * self.mask\n\n    def backward(self, grad):\n        return grad * self.mask",
      "note": "A layer with tinynet's interface and no parameters. `training` is the attribute `Net.mode` sets on every layer, and `fit` switches it off while it evaluates. In training, each unit survives with probability `1 - p`, and the survivors are divided by `1 - p` so the expected sum reaching the next layer is the same as without dropout. Backward lets the gradient through the same units, scaled the same way."
    },
    {
      "code": "def wide_dropout(p, seed=0):\n    \"\"\"small.wide(), with a Dropout after each hidden layer.\"\"\"\n    rng = np.random.default_rng(seed)\n    return Net(Linear(64, 512, rng), ReLU(), Dropout(p, rng),\n               Linear(512, 512, rng), ReLU(), Dropout(p, rng),\n               Linear(512, 10, rng))",
      "note": "The same network as `small.wide()`, with a `Dropout` after each hidden ReLU. Dropout draws no numbers when it is built, so with the same seed the starting weights are the same as `small.wide()`'s."
    },
    {
      "code": "if __name__ == \"__main__\":\n    import small\n    from fit import evaluate, fit\n    from optim import SGD\n\n    train, val = small.data()\n    for p in (0.0, 0.2, 0.5, 0.8):\n        net = wide_dropout(p)\n        fit(net, SGD(net.params(), lr=0.2), train, val, epochs=300, every=1000)\n        loss, acc = evaluate(net, *val)\n        print(f\"dropout {p:.1f}  train acc {evaluate(net, *train)[1]:.3f}  \"\n              f\"val loss {loss:.4f}  val acc {acc:.3f}\")",
      "note": "Four rates of dropout, 0.0 being no dropout at all. Train accuracy is measured with the layer switched off, as `evaluate` does."
    }
  ]
}
```

```
PENDING dropout
```

The row for 0.0 is the run of `overfit.py` again, number for number, which is the check that the layer
does nothing when it drops nothing.

**At 0.2 and 0.5 the accuracy goes up a little and the loss goes up too.** Validation accuracy reaches
0.906 and then 0.911, three and then eight images more than without dropout out of 360; the loss rises
from 0.3281 to 0.3328 and 0.3798. Training accuracy is still 1.000 in both. Dropout made the network
learn something a little more general, and did nothing to stop 300 epochs of growing confidence. At
0.8 it removes so much that the network cannot fit its own training set, 0.900, and validation
accuracy falls to 0.739.

Whether three or eight images is a real improvement is a fair question, and the last section of this
lesson answers it with a run that changes nothing but the seed. Dropout earns more in larger networks
trained on more data than this, where it was introduced, in 2014, and it is one of the reasons the
transformers of lesson 15 still carry it.
