---
title: Scaling the rate with the batch
version: 1
---

The equal-epoch table of the last section was not fair to the large batch. It kept the rate at 0.1,
the rate that suits a batch of 32, and gave the batch of 1,077 ten steps of that size. **A batch
size and a learning rate are chosen together**, and changing one without the other is the commonest
way to make a comparison of batch sizes say nothing.

The argument for scaling is short. Multiply the batch by *k* and an epoch has *k* times fewer steps.
Each of those steps averages *k* times as many images, so its gradient is about the same size, just
less noisy. To cover the same distance in an epoch with *k* times fewer steps, each step has to be
*k* times longer. **That is the linear scaling rule: multiply the batch by *k*, multiply the rate by
*k*.** Goyal and colleagues at Facebook used it in 2017 to train an image classifier on ImageNet at a
batch of 8,192 in an hour, with the accuracy of the batch of 256 it replaced.

Save this as `~/dl/batch_lr.py`. Every run is twenty epochs:

```schooling-example
{
  "language": "python",
  "file": "batch_lr.py",
  "parts": [
    {
      "code": "\"\"\"batch_lr: bigger batches at the same rate, and at a rate scaled with the batch.\"\"\"\nimport math\n\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nRUNS = [(32, 0.1), (128, 0.1), (128, 0.4), (256, 0.1), (256, 0.8), (1077, 0.1), (1077, 1.6), (1077, 3.4)]",
      "note": "Each larger batch is tried twice: at the rate that suits a batch of 32, and at that rate multiplied by the same factor as the batch. 128 is four times 32, so 0.4; 256 is eight times, so 0.8. For the full batch, 3.4 is the strict rule and 1.6 is half of it."
    },
    {
      "code": "for batch, lr in RUNS:\n    rng = np.random.default_rng(0)\n    net = Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))\n    history = fit(net, SGD(net.params(), lr), train, val, epochs=20, batch_size=batch, every=21)\n    _, _, val_loss, val_acc = history[-1]\n    print(f\"batch {batch:4d}  lr {lr:3.1f}  {20 * math.ceil(len(train[1]) / batch):4d} steps  \"\n          f\"val loss {val_loss:.4f}  val acc {val_acc:.3f}\")",
      "note": "Twenty epochs for everybody, so every run sees each image twenty times and the larger batches take fewer, bigger steps."
    }
  ]
}
```

```
PENDING batch-lr
```

**Up to eight times the batch, the rule works.** At 128 and the old rate the accuracy fell from
0.956 to 0.928; at the scaled rate of 0.4 it came back to 0.958. At 256 the old rate gave 0.903 and
the scaled 0.8 gave 0.956, with 100 steps where the batch of 32 had 680. Same images, about a seventh of
the steps, and the same result.

**At the full batch, it breaks.** The rule asks for 3.4, and that run ended at 0.119, which is a
network guessing. Halving it to 1.6 gave 0.358, worse than the unscaled 0.1. Two things go wrong at
once. Twenty steps is too few to recover from a bad one, and the argument above assumed that a
step's direction barely changes over its length, which stops being true when the step is that long.
The last section of this lesson shows what a rate of 1.5 does to a curve.

Goyal's recipe had a second ingredient for exactly this reason: **warm-up**, the climb from a small
rate to the full one that lesson 5 drew. The first steps of a fresh network are the ones a long
step damages most, and warm-up keeps them short. Even with it, the paper reports a batch size past
which accuracy fell, so the rule has a ceiling that has to be found by running.

What to take from this into practice:

- **When you change the batch size, change the rate** in the same proportion, and then check the
  rate with a short sweep rather than trusting the rule.
- **A rate in a published recipe belongs to its batch size.** Copying the rate and using half the
  batch, because your graphics card has half the memory, is a different experiment.
- **Compare batch sizes at their own best rate**, or the comparison is a comparison of rates.
