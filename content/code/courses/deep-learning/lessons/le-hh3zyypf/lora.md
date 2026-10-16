---
title: LoRA, a small correction beside frozen weights
version: 1
---

Fine-tuning a layer replaces its weight matrix `W` with `W + ΔW`, where `ΔW` is whatever training
added. For the 512-to-64 layer of `base.pt`, `ΔW` has 32,768 numbers, as many as `W` itself. **LoRA,
short for low-rank adaptation, bets that the change a new task needs is far simpler than the matrix
it changes**, and writes it as the product of two thin matrices: `ΔW = B A`, with `A` of `r` rows
by 512 and `B` of 64 rows by `r`. The rank `r` is small, so the two together hold `r × (512 + 64)`
numbers: 2,304 at rank 4, against 32,768.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 270\" role=\"img\" aria-label=\"A diagram of the adapted layer. The input, 512 numbers, goes two ways. Above, through the frozen weight W of 64 by 512 from base.pt, 32,768 numbers. Below, through A, 4 by 512, 2,048 numbers, then B, 64 by 4, 256 numbers, which starts at zero; A and B learn. The two results are added to give the output, 64 numbers.\"><text x=\"50\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">input</text><text x=\"50\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">512 numbers</text><rect x=\"160\" y=\"34\" width=\"220\" height=\"64\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"270\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">W  64 × 512</text><text x=\"270\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">32,768</text><text x=\"270\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">frozen, from base.pt</text><rect x=\"160\" y=\"160\" width=\"100\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"210\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">A  4 × 512</text><text x=\"210\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">2,048</text><rect x=\"280\" y=\"160\" width=\"100\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"330\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">B  64 × 4</text><text x=\"330\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">256</text><text x=\"270\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">learns</text><text x=\"330\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">starts at zero</text><path d=\"M260 188 L280 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M272.6 191.1 L280 188 L272.6 184.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 129 L120 129\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M120 66 L120 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M120 66 L160 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M152.6 69.1 L160 66 L152.6 62.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M120 188 L160 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M152.6 191.1 L160 188 L152.6 184.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"450\" cy=\"129\" r=\"14\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"450\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">+</text><path d=\"M380 66 L450 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 66 L450 115\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M446.9 107.6 L450 115 L453.1 107.6\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M380 188 L450 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 188 L450 143\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M453.1 150.4 L450 143 L446.9 150.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M464 129 L530 129\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M522.6 132.1 L530 129 L522.6 125.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"580\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">output</text><text x=\"580\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">64 numbers</text></svg>", "caption": "The frozen layer and the adapter beside it, at rank 4. Only A and B learn."}
```

Three details make it work. **`W` stays frozen**, so whatever the training does, the original layer
is still there underneath. **`B` starts at zero**, so `B A` is zero and the adapted network begins
exactly where `base.pt` was, with no random jolt. And the input passes through `A` and `B` beside
`W` rather than through a rebuilt matrix, which keeps the cost of the adapter to its own small size.
The whole idea fits in one class. Save as `~/dl/lora.py`:

```schooling-example
{
  "language": "python",
  "file": "lora.py",
  "parts": [
    {
      "code": "\"\"\"lora: a low-rank adapter beside a frozen nn.Linear.\"\"\"\nimport torch\nimport torch.nn as nn\n\n\nclass LoRA(nn.Module):\n    def __init__(self, base, rank, alpha):\n        super().__init__()\n        self.base = base\n        for p in base.parameters():\n            p.requires_grad = False\n        self.A = nn.Parameter(torch.randn(rank, base.in_features) / base.in_features ** 0.5)\n        self.B = nn.Parameter(torch.zeros(base.out_features, rank))\n        self.scale = alpha / rank",
      "note": "The layer it wraps is kept as it is and frozen. `A` is `rank` by inputs, random; `B` is outputs by `rank`, all zeros. Their product is a full-size correction to the weight matrix, and while `B` is zero the correction is zero, so the wrapped layer starts out computing exactly what the original did. `alpha / rank` scales the correction."
    },
    {
      "code": "    def forward(self, x):\n        return self.base(x) + (x @ self.A.T @ self.B.T) * self.scale",
      "note": "The input goes through the frozen layer as before, and through `A` then `B` beside it: down to `rank` numbers and back up to the output size. The two results are added."
    },
    {
      "code": "    def merged(self):\n        \"\"\"A plain nn.Linear that computes the same thing, with the adapter folded in.\"\"\"\n        out = nn.Linear(self.base.in_features, self.base.out_features)\n        with torch.no_grad():\n            out.weight.copy_(self.base.weight + self.scale * self.B @ self.A)\n            out.bias.copy_(self.base.bias)\n        return out",
      "note": "`B @ A` is a matrix of the same shape as the frozen weight, so it can be added to it once, after training. The result is an ordinary layer with no adapter and no extra work per prediction."
    }
  ]
}
```

The experiment puts the adapter on the 512-to-64 layer, the one that did most of the work in
`depths.py`, freezes everything else in `base.pt`, and trains it with a new head, at ranks 1, 4 and
16. Then it checks the two promises in the class: that the adapter folds into a plain layer, and
that removing it gives back the old network. Save as `~/dl/adapt.py`, next to `lora.py`:

```schooling-example
{
  "language": "python",
  "file": "adapt.py",
  "parts": [
    {
      "code": "\"\"\"adapt: base.pt frozen whole, a LoRA adapter on its 512-to-64 layer, a new head.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\nfrom lora import LoRA\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nnew_val = xv[yv >= 5], yv[yv >= 5] - 5\nold_val = xv[yv < 5], yv[yv < 5]",
      "note": "The same two validation sets as `forget.py`, and the `LoRA` class from `lora.py`, which has to sit in `~/dl` beside this file."
    },
    {
      "code": "def adapted(rank):\n    model = cnn.make_cnn(5)\n    model.load_state_dict(torch.load(\"base.pt\"))\n    for p in model.parameters():\n        p.requires_grad = False\n    old_head = model[8]\n    model[6] = LoRA(model[6], rank, alpha=rank)\n    model[8] = nn.Linear(64, 5)\n    return model, old_head",
      "note": "Everything in `base.pt` is frozen, the 512-to-64 layer included. The adapter is put around that layer, and a new head replaces the old one, which is kept for later. With `alpha` equal to the rank the scale is 1."
    },
    {
      "code": "for per_class in (10, 50):\n    idx = torch.cat([torch.nonzero(y == d).flatten()[:per_class] for d in range(5, 10)])\n    train = x[idx], y[idx] - 5\n    print(f\"{per_class} per class\")\n    for rank in (1, 4, 16):\n        accs = []\n        for seed in (0, 1, 2):\n            torch.manual_seed(seed)\n            model, old_head = adapted(rank)\n            params = [p for p in model.parameters() if p.requires_grad]\n            opt = torch.optim.Adam(params, lr=1e-3)\n            history = loop.fit(model, opt, train, new_val, epochs=100, seed=seed, every=1000)\n            accs.append(history[-1][3])\n        print(f\"  rank {rank:2d} trains {sum(p.numel() for p in params):4d} parameters, val acc \"\n              + \"  \".join(f\"{a:.3f}\" for a in accs))",
      "note": "The recipe of `depths.py`, with 10 and 50 images per class, three seeds, Adam at 1e-3 for 100 epochs, and three ranks. What learns is `A`, `B` and the new head."
    },
    {
      "code": "adapter = model[6]\nmodel.eval()\nfeatures = model[:6](new_val[0])\nmerged = adapter.merged()\nprint(\"merged layer against adapter, largest difference:\",\n      (merged(features) - adapter(features)).abs().max().item())",
      "note": "The last model trained, rank 16 on 50 images per class with seed 2. Its adapter is folded into a plain layer and both are given the same inputs: the 512 numbers per validation image that reach that layer."
    },
    {
      "code": "old = nn.Sequential(*model[:6], adapter, model[7], old_head)\nprint(\"0 to 4 with the adapter on:  \", f\"{loop.evaluate(old, *old_val)[1]:.3f}\")\nold[6] = adapter.base\nprint(\"0 to 4 with the adapter off: \", f\"{loop.evaluate(old, *old_val)[1]:.3f}\")",
      "note": "The old task, as `forget.py` measured it: the body with `base.pt`'s head on top. First with the adapter in place, then with the adapter taken out and the frozen layer it wrapped put back."
    }
  ]
}
```

```
PENDING adapt
```

## What the adapter bought

**At rank 4 the adapter matched the last block with about a twelfth of its parameters.** It trained
2,629 parameters, the 2,304 of `A` and `B` plus the new head's 325, where unfreezing the last block
trained 33,157. With 50 images per class it scored 0.967, 0.967 and 0.972, against 0.967, 0.978
and 0.967 for the last block in `depths.py`; with 10 per class, 0.867 to 0.917 against 0.894 to
0.911. Rank 1 was too thin, 0.889 to 0.900 with 50 per class, and rank 16 added nothing over rank
4 there.

It did not beat training from scratch either, and could not be expected to: it adapts the same
small donor as every other row in this lesson.

**The adapter folds away.** The merged layer and the adapter gave the same outputs to within
8.6e-06, which is float32 rounding. After training, `B A` can be added to `W` once, and the network
that ships is the plain `cnn.make_cnn(5)` shape with no adapter in it and nothing extra to compute
per prediction.

**And it can be taken off.** With the adapter on, the old task scored 0.950: the corrected layer
has drifted from what `base.pt`'s head expects, as fine-tuning did in the previous section. With
the adapter removed and the frozen layer put back, it scored 0.989, the number `base.pt` had in
lesson 13. **Nothing was forgotten, because nothing was overwritten.** One frozen network can carry
several adapters, one per task, each a small file, swapped in when its task is asked for.

Lesson 13's finding still holds: the adapter cannot add what the frozen layers below it never
learnt. LoRA decides how much you train and what you keep, not what the donor knows.
