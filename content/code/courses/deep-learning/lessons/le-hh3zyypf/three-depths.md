---
title: Three depths, against scratch
version: 1
---

There are three usual places to draw the line between what stays frozen and what learns. **Head
only** is lesson 13's feature extraction. **Last block** lets the layer just below the head learn
too, starting from the weights `base.pt` gave it. **Everything** lets every layer learn, so the
pretrained weights are only a starting point. The new head starts from random weights in all
three, because the old one answered a different question.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 330\" role=\"img\" aria-label=\"A grid of four rows and four layers. The layers are Conv2d 1 to 16, Conv2d 16 to 32, Linear 512 to 64 and Linear 64 to 5. Scratch: all four learn from random weights, 37,957 parameters. Head: the three body layers are kept from base.pt and frozen, the new head learns, 325 parameters. Last block: the two convolutions are frozen, the 512-to-64 layer learns from base.pt&#x27;s weights and the new head from random ones, 33,157 parameters. Everything: all three body layers learn from base.pt&#x27;s weights and the new head from random ones, 37,957 parameters.\"><text x=\"186.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Conv2d</text><text x=\"186.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1→16</text><text x=\"288.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Conv2d</text><text x=\"288.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">16→32</text><text x=\"390.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Linear</text><text x=\"390.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">512→64</text><text x=\"492.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Linear</text><text x=\"492.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">64→5</text><text x=\"492.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">new head</text><text x=\"600\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">trains</text><text x=\"124\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">scratch</text><rect x=\"140\" y=\"76\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"242\" y=\"76\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"344\" y=\"76\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"446\" y=\"76\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">37,957</text><text x=\"124\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">head</text><rect x=\"140\" y=\"122\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"242\" y=\"122\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"344\" y=\"122\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"446\" y=\"122\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">325</text><text x=\"124\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">last block</text><rect x=\"140\" y=\"168\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"242\" y=\"168\" width=\"92\" height=\"36\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"344\" y=\"168\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"446\" y=\"168\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">33,157</text><text x=\"124\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">everything</text><rect x=\"140\" y=\"214\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"242\" y=\"214\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"344\" y=\"214\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"446\" y=\"214\" width=\"92\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">37,957</text><rect x=\"40\" y=\"270\" width=\"30\" height=\"18\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"80\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">kept from base.pt, frozen</text><rect x=\"330\" y=\"270\" width=\"30\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"370\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">learns, starting from base.pt</text><rect x=\"40\" y=\"300\" width=\"30\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"80\" y=\"309\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">learns, from random weights</text></svg>", "caption": "The four layers that hold parameters, in the four starts of depths.py. Solid boxes learn; dashed ones keep base.pt's weights."}
```

The more of the body learns, the more the network can adapt to the new task, and the more
parameters it has to fit from the same few images. Which effect wins depends on the donor and on
how much new data there is, so it is measured rather than argued. The program trains all three
depths and the from-scratch baseline on the digits 5 to 9, with 2, 10 and 50 training images of
each. Save as `~/dl/depths.py`:

```schooling-example
{
  "language": "python",
  "file": "depths.py",
  "parts": [
    {
      "code": "\"\"\"depths: base.pt fine-tuned on the digits 5 to 9 at three depths, against scratch.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nkeep = yv >= 5\nval = xv[keep], yv[keep] - 5",
      "note": "The task of lesson 13's `transfer.py`: the five digits `base.pt` never saw, labelled 0 to 4 by subtracting 5, judged on every 5 to 9 in the validation split."
    },
    {
      "code": "LEARNS = {\"head\": [8], \"last block\": [6, 8], \"everything\": [0, 2, 6, 8]}\n\n\ndef start(depth):\n    model = cnn.make_cnn(5)\n    if depth == \"scratch\":\n        return model\n    model.load_state_dict(torch.load(\"base.pt\"))\n    model[8] = nn.Linear(64, 5)\n    for i, layer in enumerate(model):\n        for p in layer.parameters():\n            p.requires_grad = i in LEARNS[depth]\n    return model",
      "note": "The positions of the layers that learn at each depth: 0 and 2 are the convolutions, 6 is the 512-to-64 layer and 8 the head. Every pretrained start gets a new head, and every layer not listed is frozen. `scratch` is the same network with random weights and nothing frozen."
    },
    {
      "code": "for per_class in (2, 10, 50):\n    idx = torch.cat([torch.nonzero(y == d).flatten()[:per_class] for d in range(5, 10)])\n    train = x[idx], y[idx] - 5\n    print(f\"{per_class} per class, {len(idx)} training images\")\n    for depth in (\"scratch\", \"head\", \"last block\", \"everything\"):\n        accs = []\n        for seed in (0, 1, 2):\n            torch.manual_seed(seed)\n            model = start(depth)\n            params = [p for p in model.parameters() if p.requires_grad]\n            opt = torch.optim.Adam(params, lr=1e-3)\n            history = loop.fit(model, opt, train, val, epochs=100, seed=seed, every=1000)\n            accs.append(history[-1][3])\n        print(f\"  {depth:10s} trains {sum(p.numel() for p in params):5d} parameters, val acc \"\n              + \"  \".join(f\"{a:.3f}\" for a in accs))",
      "note": "The first 2, 10 and 50 training images of each new digit; 2 and 10 are the two sizes lesson 13 used. Every start is trained three times with three seeds, by Adam at 1e-3 for 100 epochs, and the optimiser gets only the parameters that learn."
    }
  ]
}
```

```
PENDING depths
```

## What the table says

**The rows lesson 13 already ran come out the same.** Scratch and head at 2 and 10 per class are
the same images, seeds and recipe as lesson 13's `transfer.py`, and they repeat its numbers to the
last digit: 0.944, 0.933 and 0.933 from scratch with 10 per class, 0.683, 0.689 and 0.672 for the
head. Anything new in the table is the fine-tuned rows.

**Letting the body learn pays.** With 10 per class the head alone reached 0.672 to 0.689, the
last block 0.894 to 0.911 and everything 0.917 to 0.933. With 50 per class the head stays far
behind at 0.789 to 0.806, and the other two are level: 0.967 to 0.978 for the last block, 0.967 to
0.972 for everything. Unfreezing
the 512-to-64 layer did most of the work, which fits what lesson 13 found: 25 of its 64 units were
silent on every 5 to 9, and a layer that can learn can stop being silent.

**And none of it beats training from scratch.** At 10 per class everything scored 0.917 to 0.933
against scratch's 0.933 to 0.944; at 50 per class it scored 0.967 to 0.972 against 0.972 to 0.983.
The only size where any fine-tuned depth came out ahead is the smallest: with 2 images per class,
everything scored 0.850, 0.900 and 0.872, and scratch 0.850, 0.833 and 0.828. That is one tie and
two wins on ten training images and three seeds, which is a hint rather than a finding; lesson 18
measures how far three seeds can be trusted.

## Why, and what it means outside this lab

This is lesson 13's result again, seen from the other side. **`base.pt` was trained on 528 images
of five digits, which is not much more than the new task has**, and a small CNN learns 8 by 8
digits from 50 examples well on its own. A donor that small has little to give, so the best thing
fine-tuning can do with it is to move away from it, and the start that moves furthest, everything,
ends up closest to scratch.

The case this lab cannot show is a donor trained on far more data than you have, such as the
ImageNet weights of lesson 13. There it is the baseline that moves: a network trained from scratch
on a few hundred photographs is poor, which is why fine-tuning is where most image work starts.
**The recipe is the same either way**:

1. Train the from-scratch baseline. It is one run, and it is the only thing that says whether
   borrowing paid.
2. Train the head only. It is the cheapest, and if it is close to the best, stop there.
3. Unfreeze the last block, then everything, and keep the depth only if the validation score
   says it earned its extra parameters.

The less new data there is, the more the frozen depths are worth trying, because every parameter
that learns is fitted to those few images. The more the new images differ from the donor's, the
deeper the cut has to go, because the features near the head belong to the old task.
