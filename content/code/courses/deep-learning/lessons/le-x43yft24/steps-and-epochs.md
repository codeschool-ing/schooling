---
title: Steps and epochs, the two clocks of a run
version: 1
---

A run is described in epochs, and it is tempting to read an epoch as one move of the weights. **It is
not. An epoch is one pass over all the training images; a step is one update of the weights**, made
from one batch. How many steps fit in an epoch depends on the batch size, and that number is what
changes when the batch size does.

The loop in the `fit.py` from lesson 5 says so in one line: `for start in range(0, len(y),
batch_size)` cuts the shuffled training set into batches, and each batch gets one forward pass, one
backward pass and one call to `opt.step()`. The program below works out the count for four batch
sizes and then checks it by counting. Save it as `~/dl/steps.py`, beside the `digits.py` from
lesson 1, the `tinynet.py` from lesson 3 and the `optim.py` and `fit.py` from lesson 5:

```schooling-example
{
  "language": "python",
  "file": "steps.py",
  "parts": [
    {
      "code": "\"\"\"steps: how many steps make an epoch, worked out and then counted.\"\"\"\nimport math\n\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nn = len(train[1])\nfor batch in (1, 32, 100, 1077):\n    steps = math.ceil(n / batch)\n    print(f\"batch {batch:4d}: {steps:4d} steps an epoch, the last one {n - (steps - 1) * batch} images\")",
      "note": "The arithmetic first. An epoch cuts the 1,077 training images into batches, and the last batch takes whatever is left, so the number of steps is the division rounded up."
    },
    {
      "code": "class Counting(SGD):\n    \"\"\"SGD that also counts how many times it was asked to step.\"\"\"\n\n    def __init__(self, params, lr):\n        super().__init__(params, lr)\n        self.steps = 0\n\n    def step(self):\n        super().step()\n        self.steps += 1",
      "note": "Then a check that does not trust the arithmetic. This optimiser is the SGD of lesson 5 with a counter added, and `fit` calls `step` once per batch without knowing the difference."
    },
    {
      "code": "rng = np.random.default_rng(0)\nnet = Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))\nopt = Counting(net.params(), 0.1)\nfit(net, opt, train, val, epochs=3)\nprint(\"steps counted in 3 epochs:\", opt.steps)",
      "note": "The network every run of this lesson trains: 64 inputs, 64 hidden units, 10 outputs. `fit` is left at its default batch of 32."
    }
  ]
}
```

```
PENDING steps
```

**At a batch of 32, an epoch is 34 steps**, and three epochs made 102 calls to `step`, exactly 3 ×
34. 1,077 is not a multiple of 32, so 33 full batches take 1,056 images and **the last batch holds
the 21 left over**. At a batch of 100 the remainder is 77, and at a batch of 1 there is no remainder
because every batch is a single image.

## What the remainder does

The 21-image batch gets a whole step, at the same rate as the others. Its gradient is a mean over
21 images rather than 32, so it is a slightly noisier estimate, and nothing else about it is
special. `fit` also reports the training loss as the plain mean of the 34 batch losses, so those 21
images count for as much as a full batch of 32 in that number. Both effects are small at 34 steps an
epoch. Some loops drop the short batch instead, and PyTorch's `DataLoader` has a flag for it that
lesson 10 sets.

**`fit` shuffles again at the start of every epoch.** `rng.permutation(len(y))` runs once per pass,
so epoch 2 does not repeat the 34 batches of epoch 1: every image comes back, in a different
company. Without the reshuffle, a network would see the same 34 averages forever, in the same order.

## Which clock to quote

Epochs say how many times the network has seen each image. Steps say how many times the weights
moved. While the batch size stays fixed the two are the same clock in different units: ten epochs at
32 is always 340 steps. **The moment the batch size changes, they stop agreeing**, and "trained for
ten epochs" no longer says how much training happened. The next section changes it.
