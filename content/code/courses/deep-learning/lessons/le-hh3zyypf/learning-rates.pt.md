---
title: Learning rates, and how far the weights travel
version: 1
---

Lesson 5 called the learning rate the setting that matters most, and in fine-tuning it gains a
second job. From scratch, the rate only decides how fast the network gets somewhere useful. **From
pretrained weights, it also decides how far the network is allowed to wander from where it
started**, and the starting point is the thing you borrowed. A rate that is right for random
weights can carry a pretrained layer well away from what it knew within the first few epochs.

That distance can be measured. The program below fine-tunes everything, with 10 images per class,
at three single rates and once with two: a slow body and a faster head, set through the parameter
groups of the first section. Beside each accuracy it prints how far the first convolution travelled,
as a fraction of its size in `base.pt`. Save as `~/dl/rates.py`:

```schooling-example
{
  "language": "python",
  "file": "rates.py",
  "parts": [
    {
      "code": "\"\"\"rates: fine-tuning all of base.pt at three learning rates, and with two at once.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nkeep = yv >= 5\nval = xv[keep], yv[keep] - 5\nidx = torch.cat([torch.nonzero(y == d).flatten()[:10] for d in range(5, 10)])\ntrain = x[idx], y[idx] - 5\n\nbase = cnn.make_cnn(5)\nbase.load_state_dict(torch.load(\"base.pt\"))",
      "note": "Dez imagens de cada dígito novo, o tamanho do meio do `depths.py`, e uma cópia intocada do `base.pt` guardada para medir contra ela."
    },
    {
      "code": "def moved(model):\n    \"\"\"How far the first convolution went from base.pt, as a fraction of its size.\"\"\"\n    w0, w = base[0].weight, model[0].weight\n    return ((w - w0).norm() / w0.norm()).item()",
      "note": "A distância entre os pesos da primeira camada agora e no `base.pt`, dividida pelo tamanho dos pesos no `base.pt`. 0.10 quer dizer que os filtros mudaram um décimo do próprio tamanho."
    },
    {
      "code": "SETUPS = {\n    \"one rate, 1e-2\": lambda m: [{\"params\": m.parameters(), \"lr\": 1e-2}],\n    \"one rate, 1e-3\": lambda m: [{\"params\": m.parameters(), \"lr\": 1e-3}],\n    \"one rate, 1e-4\": lambda m: [{\"params\": m.parameters(), \"lr\": 1e-4}],\n    \"body 1e-4, head 1e-3\": lambda m: [{\"params\": m[:8].parameters(), \"lr\": 1e-4},\n                                       {\"params\": m[8].parameters(), \"lr\": 1e-3}],\n}",
      "note": "Quatro otimizadores para a mesma rede, toda ela aprendendo. Os três primeiros usam uma taxa para todas as camadas; o último dá ao corpo uma taxa dez vezes menor que a da cabeça nova."
    },
    {
      "code": "for name, groups in SETUPS.items():\n    results = []\n    for seed in (0, 1, 2):\n        torch.manual_seed(seed)\n        model = cnn.make_cnn(5)\n        model.load_state_dict(torch.load(\"base.pt\"))\n        model[8] = nn.Linear(64, 5)\n        opt = torch.optim.Adam(groups(model))\n        history = loop.fit(model, opt, train, val, epochs=100, seed=seed, every=1000)\n        results.append(f\"{history[-1][3]:.3f} ({moved(model):.2f})\")\n    print(f\"{name:21s} val acc (first layer moved)  \" + \"  \".join(results))",
      "note": "Três sementes por configuração, como antes. Cada resultado é a acurácia de validação em 5 a 9 e, entre parênteses, quanto a primeira camada andou."
    }
  ]
}
```

```
PENDING rates
```

## Reading the two numbers together

**The rate sets the distance.** At 1e-4 the first layer moved by 0.03 to 0.04
of its own size, at 1e-3 by 0.16 to 0.18, and at 1e-2 by 0.32 to 0.40: the filters at 1e-2 were a
third of the way to being different filters. The two-group setup, body at 1e-4 and head at 1e-3,
moved the body as little as 1e-4 did, 0.04, because that is the rate its group was given.

**On this task, travelling far scored best.** 1e-2 reached 0.922 to 0.950, the highest row, level
with training from scratch in `depths.py`. The slow body scored lowest, 0.828 to 0.844, below
everything at 1e-3 and below the last block of `depths.py` too. That is the previous section's result in a
different form: `base.pt` has little to give the digits 5 to 9, so the less the body is held to
it, the better the new task goes.

What a high rate costs is not in this table, because the table only asks about the new task. The
next section asks the old one.

## Why fine-tuning usually runs slower

In practice fine-tuning uses lower rates than training from scratch, and often lower still for the
layers near the input, and the reason is the half of the trade this lab's donor cannot show. **With
a body worth keeping, every step away from it throws away something that took far more data to
learn than you are fine-tuning on.** The early layers, holding the most general features, get the
smallest rate; the layers near the head get more; the new head, which starts from nothing, gets the
most. Training each depth at its own rate is called discriminative fine-tuning, and it is exactly
the list of groups `rates.py` built, with more entries.

Two smaller habits come from the same reasoning:

- **A new head starts random, so its first gradients are large and arbitrary**, and they flow back
  into a body that was fine. Training the head alone for a few epochs first, then unfreezing, or
  starting with lesson 5's warm-up, keeps those first steps from undoing the body.
- **Choose the rate by validation, as always**, but read the distance too. A rate that wins on the
  new task by moving the body a third of its size is telling you the pretrained weights were not
  doing much, which is worth knowing before you pay for a larger donor.
