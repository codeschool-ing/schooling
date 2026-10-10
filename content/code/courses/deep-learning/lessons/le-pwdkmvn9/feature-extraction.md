---
title: Feature extraction, and when borrowing does not pay
version: 1
---

Feature extraction is the cheapest kind of transfer. **Freeze the borrowed body, put a new head
on it, and train only the head.** The body is used as a fixed function from images to features,
and the head is a small linear classifier on top: a few hundred parameters to learn instead of
tens of thousands, which is why it can work from very few examples.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 250\" role=\"img\" aria-label=\"The small CNN drawn as a row of layers. The first five boxes, two convolutions, the pooling and the 512-to-64 linear layer, sit inside a dashed frame labelled as the body copied from base.pt and frozen: learnt on the digits 0 to 4, 37,632 parameters never updated. The last box, a 64-to-5 linear layer, is the new head, trained on 50 images of the digits 5 to 9: 325 parameters.\"><rect x=\"78\" y=\"40\" width=\"432\" height=\"120\" rx=\"8\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"294\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">body: copied from base.pt, frozen</text><rect x=\"528\" y=\"40\" width=\"116\" height=\"120\" rx=\"8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"586\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">head: new, trained</text><text x=\"34\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">input</text><text x=\"34\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1x8x8</text><rect x=\"88\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"136\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Conv2d</text><text x=\"136\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1→16</text><path d=\"M60 100 L88 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80.6 103.1 L88 100 L80.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"194\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"242\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Conv2d</text><text x=\"242\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">16→32</text><path d=\"M180 100 L194 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M186.6 103.1 L194 100 L186.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"300\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"348\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pool, flatten</text><text x=\"348\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">512</text><path d=\"M286 100 L300 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M292.6 103.1 L300 100 L292.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"406\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"454\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Linear</text><text x=\"454\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">512→64</text><path d=\"M392 100 L406 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M398.6 103.1 L406 100 L398.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M502 100 L538 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M530.6 103.1 L538 100 L530.6 96.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"538\" y=\"70\" width=\"96\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"586\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Linear</text><text x=\"586\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">64→5</text><text x=\"294\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">learnt on the digits 0 to 4</text><text x=\"294\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">37,632 parameters, never updated</text><text x=\"586\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor-dim)\">learns 5 to 9</text><text x=\"586\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor-dim)\">from 50 images</text><text x=\"586\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor-dim)\">325 parameters</text></svg>", "caption": "The body is borrowed and stays as it was; only the head learns the new classes."}
```

The program below tries it on the digits 5 to 9 with 10 and then 50 training images, and sets it
against two other starts: the same network trained from scratch, and a middle way that keeps only
the two convolutions from `base.pt` and trains new linear layers above them. Save as
`~/dl/transfer.py`, next to `base.pt`:

```schooling-example
{
  "language": "python",
  "file": "transfer.py",
  "parts": [
    {
      "code": "\"\"\"transfer: the digits 5 to 9 from a few examples each, with and without base.pt.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nkeep = yv >= 5\nval = xv[keep], yv[keep] - 5",
      "note": "The new task is the five digits `pretrain.py` never saw, judged on every 5 to 9 in the validation split. Subtracting 5 makes the labels 0 to 4, which is what a five-output head answers."
    },
    {
      "code": "def pretrained():\n    model = cnn.make_cnn(5)\n    model.load_state_dict(torch.load(\"base.pt\"))\n    for p in model.parameters():\n        p.requires_grad = False\n    return model",
      "note": "The network as `pretrain.py` left it, built first and then filled from the file, with every parameter frozen: `requires_grad = False` means backward computes no gradient for it, and the optimiser has nothing to move."
    },
    {
      "code": "def scratch():\n    return cnn.make_cnn(5)\n\n\ndef head_only():\n    model = pretrained()\n    model[8] = nn.Linear(64, 5)\n    return model\n\n\ndef convolutions_only():\n    model = pretrained()\n    model[6] = nn.Linear(512, 64)\n    model[8] = nn.Linear(64, 5)\n    return model",
      "note": "Three starts. `head_only` keeps the whole body and replaces layer 8, the last `Linear`. `convolutions_only` keeps the two convolutions and replaces both linear layers. A new layer is created with `requires_grad` on, so it is the part that learns."
    },
    {
      "code": "with torch.no_grad():\n    hidden = pretrained()[:8](val[0])\nprint(\"the 64 units before base.pt's head: silent on every 5 to 9 in val:\",\n      int((hidden.max(dim=0).values == 0).sum()))",
      "note": "Slicing a `Sequential` gives the layers up to the head. This counts the units of the 64 whose ReLU stays at zero for every one of the new digits: a feature that never fires is a feature a new head cannot use."
    },
    {
      "code": "for per_class in (2, 10):\n    few = torch.cat([torch.nonzero(y == d).flatten()[:per_class] for d in range(5, 10)])\n    train = x[few], y[few] - 5\n    print(f\"{len(few)} training images, {len(val[1])} validation images\")\n    for make in (scratch, head_only, convolutions_only):\n        accs = []\n        for seed in (0, 1, 2):\n            torch.manual_seed(seed)\n            model = make()\n            params = [p for p in model.parameters() if p.requires_grad]\n            opt = torch.optim.Adam(params, lr=1e-3)\n            history = loop.fit(model, opt, train, val, epochs=100, seed=seed, every=1000)\n            accs.append(history[-1][3])\n        print(f\"  {make.__name__:17s} trains {sum(p.numel() for p in params):5d} parameters,\"\n              \" val acc \" + \"  \".join(f\"{a:.3f}\" for a in accs))",
      "note": "The first 2 and then the first 10 training images of each new digit. Each start is trained three times with three seeds, the same 100 epochs and the same rate, and the optimiser is given only the parameters that still learn. `every=1000` keeps `loop.fit` quiet."
    }
  ]
}
```

```
PENDING transfer
```

## The result is the lesson

**Borrowing the whole body lost, and by a lot.** With 50 images, training from scratch reached
0.944, 0.933 and 0.933; the head on the frozen body reached 0.683, 0.689 and 0.672. With only 10
images the order was the same, 0.828 to 0.850 against 0.600 to 0.667. The 325 parameters trained
fine; the features they were given were the problem.

The first line of the output says why. **25 of the 64 units before the head never fire for any
5 to 9 in the validation set.** Pretraining on 0 to 4 shaped that layer into detectors for those
five digits, and a third of it has nothing to say about a 7. That is the general rule about where
features live: the layers near the input learn parts that any digit has, and the layers near the
output learn the old task's answers.

The middle start agrees. Keeping only the convolutions and learning the linear layers again
recovered almost all of it: 0.917 to 0.922 with 50 images, and with 10 images it matched scratch,
0.833 to 0.856. **It still did not beat training from scratch.** Here the honest reason is the
size of the donor: 528 images of five digits is barely more than the new task, and a small CNN
learns 8 by 8 digits from 50 examples well enough on its own. Transfer pays when the old task is
much larger and broader than the new one, which is exactly the case of the next section.

What to take from this run into your own work:

- **Cut where the features are still general.** The deeper the layer, the more it belongs to the
  old labels. With a large donor the last hidden layer is usually fine; with a narrow one, cut
  earlier.
- **Always train the from-scratch baseline too.** It costs one more run, and without it a
  transfer that lost would have looked like a reasonable 0.68.
- **Frozen means cheap.** The head-only start trained 325 parameters; on a large body the frozen
  part can even be run once, its features stored, and only the head trained on them.

Lesson 17 starts from the same `base.pt` and lets some of the body learn too.
