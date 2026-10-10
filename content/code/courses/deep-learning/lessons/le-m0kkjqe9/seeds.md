---
title: Seeds, and what one fixes
version: 1
---

Training looks deterministic from the outside: the same program, the same data, the same settings.
**It is not, because three things in it are drawn at random**: the starting weights, the order the
images are shuffled into for each epoch, and, one level up, which images went into which set.
Change any of them and the final accuracy changes, with nothing in the code to say why.

A seed is the number a random number generator starts from. Start it from the same number and it
produces the same sequence again, so everything drawn from it is drawn again. Three lines, run twice
with seed 0 and once with seed 1:

```
PENDING init
```

The same seed gave the same first three weights, digit for digit, and seed 1 gave different ones.
**Nothing about the generator is random once it has a seed.** It is a long, fixed sequence, and the
seed says where in it to begin.

## One run, every choice in one place

To compare runs, every choice a run makes has to be an argument, never a line somebody edits. Save
this as `~/dl/exp.py`, beside the `digits.py` from lesson 1 and the `tdigits.py` and `loop.py` from
lesson 9:

```schooling-example
{
  "language": "python",
  "file": "exp.py",
  "parts": [
    {
      "code": "\"\"\"exp: one training run on the digits, decided by a config and a seed and nothing else.\"\"\"\nimport torch\nfrom torch import nn\n\nimport loop\nimport tdigits",
      "note": "`tdigits.py` and `loop.py` are the ones from lesson 9. This file adds no new idea about training; it puts every choice a run makes in one place, so that two runs can be told apart by their arguments."
    },
    {
      "code": "def build(config):\n    h = config[\"hidden\"]\n    return nn.Sequential(nn.Linear(64, h), nn.ReLU(), nn.Linear(h, 10))",
      "note": "The network of lesson 9: one hidden layer whose width comes from the config."
    },
    {
      "code": "def run(config, seed):\n    \"\"\"Train one network; return the model and its final validation accuracy.\"\"\"\n    torch.manual_seed(seed)\n    train, val, _ = tdigits.load()\n    model = build(config)",
      "note": "`torch.manual_seed` resets PyTorch's random number generator, and `build` draws the starting weights from it right after. Same seed, same starting weights. The split is not touched: `tdigits.load()` uses its own fixed seed of 0, so every run sees the same 1,077 training images."
    },
    {
      "code": "    opt = torch.optim.SGD(model.parameters(), lr=config[\"lr\"], momentum=0.9)\n    history = loop.fit(model, opt, train, val, config[\"epochs\"],\n                       batch_size=config[\"batch_size\"], seed=seed, every=config[\"epochs\"] + 1)\n    return model, history[-1][3]",
      "note": "The same seed goes to `loop.fit`, which uses it for the order the images are shuffled into each epoch. `every` larger than the number of epochs keeps `fit` from printing, and the last entry of `history` holds the final validation accuracy."
    }
  ]
}
```

Each of the three random things has its own seed here, and it is worth knowing which is which:

| random thing | fixed by |
| --- | --- |
| which images are train, validation and test | `digits.load(seed=0)`, inside `tdigits.load()`: never changes in this lesson |
| the starting weights | `torch.manual_seed(seed)`, just before `build` |
| the order of the batches in every epoch | the generator `loop.fit` makes from `seed` |

The split stays fixed on purpose. Varying it is a fair question too, and it answers a different
one: how much the result depends on which 360 images happened to be held out.

## Twice with the same seed

Save as `~/dl/seeds.py`:

```schooling-example
{
  "language": "python",
  "file": "seeds.py",
  "parts": [
    {
      "code": "\"\"\"seeds: the same seed twice, then another one.\"\"\"\nimport torch\n\nimport exp\n\nconfig = {\"hidden\": 32, \"lr\": 0.01, \"epochs\": 10, \"batch_size\": 32}\na, acc_a = exp.run(config, 0)\nb, acc_b = exp.run(config, 0)\nc, acc_c = exp.run(config, 1)",
      "note": "Three complete trainings of ten epochs: two with seed 0 and one with seed 1. Everything else is identical."
    },
    {
      "code": "def same(m, n):\n    return all(torch.equal(p, q) for p, q in zip(m.parameters(), n.parameters()))\n\n\nprint(f\"seed 0  val acc {acc_a:.4f}\")\nprint(f\"seed 0  val acc {acc_b:.4f}  every weight equal to the first run's: {same(a, b)}\")\nprint(f\"seed 1  val acc {acc_c:.4f}  every weight equal to the first run's: {same(a, c)}\")",
      "note": "`torch.equal` is true only when two tensors hold the same numbers to the last bit. Close is not equal here, on purpose."
    }
  ]
}
```

```
PENDING seeds
```

**Seed 0 twice gave the same network to the last bit**, not merely the same accuracy. Ten epochs of
34 batches is 340 optimiser steps, and after all of them not one parameter differed. Seed 1
ended somewhere else, at a different accuracy.

That is what a seed buys and all it buys: **the same run, again, on the same machine with the same
libraries.** It does not make a result true. Seed 0's accuracy is one draw from all the accuracies
this configuration can reach, and the next section measures how wide that range is.
