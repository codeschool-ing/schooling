---
title: Weight decay, an L2 penalty in the step
version: 1
---

A network that has memorised its training set has usually done it with large weights: a big weight
makes an output swing hard on a small change in one pixel, which is what it takes to give each of 100
images its own answer. **Weight decay makes size itself cost something.** It adds a penalty to the loss
for every weight, proportional to its square:

`loss + decay / 2 × (sum of every weight squared)`

You never compute that sum while training. Its gradient with respect to one weight `w` is
`decay × w`, so the penalty only adds `decay × w` to each gradient, and every step pulls each weight a
little towards zero on top of whatever the data asks for. The name *L2* comes from the squared size of
the weights, and *decay* from what that pull does to a weight the data stops defending.

It is a change to the optimiser, three lines in a subclass of the `SGD` from lesson 5. Save as
`~/dl/decay.py`:

```schooling-example
{
  "language": "python",
  "file": "decay.py",
  "parts": [
    {
      "code": "\"\"\"decay: SGD with weight decay, the L2 penalty folded into the step.\"\"\"\nfrom optim import SGD",
      "note": "It starts from the `SGD` of lesson 5's `optim.py` and changes one method."
    },
    {
      "code": "class SGDDecay(SGD):\n    def __init__(self, params, lr, decay):\n        super().__init__(params, lr)\n        self.decay = decay\n\n    def step(self):\n        for p, g in self.params:\n            if p.ndim == 2:\n                g += self.decay * p\n            p -= self.lr * g",
      "note": "The penalty `decay / 2 × w²` added to the loss has the gradient `decay × w`, so adding it to the gradient is the whole change. `p.ndim == 2` picks out the weight matrices and leaves the biases alone: a bias shifts a unit and does not make the network more flexible. `g += …` writes into the gradient array, which the next backward pass overwrites anyway."
    },
    {
      "code": "if __name__ == \"__main__\":\n    import small\n    from fit import evaluate, fit\n\n    train, val = small.data()\n    for decay in (0.0, 0.001, 0.01, 0.1):\n        net = small.wide()\n        fit(net, SGDDecay(net.params(), lr=0.2, decay=decay), train, val, epochs=300, every=1000)\n        weights = sum(float((p ** 2).sum()) for p, _ in net.params() if p.ndim == 2)\n        loss, acc = evaluate(net, *val)\n        print(f\"decay {decay:<6}  val loss {loss:.4f}  val acc {acc:.3f}  \"\n              f\"sum of squared weights {weights:7.1f}\")",
      "note": "Four runs that differ only in `decay`, each on a fresh network with the same seed. `every=1000` keeps `fit` quiet, and the last column measures how big the weights ended up."
    }
  ]
}
```

```
PENDING decay
```

**The last column is the mechanism, measured.** Without decay the squared weights add up to 2122.6;
at 0.001 they come to 1335.8, at 0.01 to 88.5, and at 0.1 to 16.5.

The first column is whether it helped. At 0.001 the validation loss ends at 0.2975 instead of 0.3281,
almost as low as the best epoch of `overfit.py`, while the accuracy moves from 0.903 to 0.897, two
images out of 360. At 0.01 the pull is strong enough to hurt: loss 0.4468, accuracy 0.869. At 0.1 the
network can no longer fit even its training set, and accuracy falls to 0.386.

**Decay is a dial with a cliff on one side.** Too little does nothing and too much stops learning, and
the right value depends on the network, the data and the learning rate, so it is found by trying a few
values on the validation set, as here. Values between 0.0001 and 0.01 are where most searches start.

One detail for when you meet it in a framework. Adding `decay × w` to the gradient is the same as an
L2 penalty for plain SGD, but not for Adam, whose per-parameter scaling from lesson 5 rescales the
penalty too. PyTorch's `AdamW` applies the decay to the weights directly instead, outside that scaling,
and it is the version to use with Adam.
