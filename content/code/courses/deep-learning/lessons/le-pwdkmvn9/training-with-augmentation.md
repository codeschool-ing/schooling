---
title: Training with augmentation, and with the wrong one
version: 1
---

The two sections above give one program what it needs: transforms that draw per image, and a
test for which of them are safe. **This one trains the CNN on 100 images four times, once with
no augmentation, once with the safe one, and twice with the ones `preserve.py` warned against.**
`loop.fit` takes a fixed set of tensors, so the program carries a copy of its loop with one line
added. Save as `~/dl/augtrain.py`:

```schooling-example
{
  "language": "python",
  "file": "augtrain.py",
  "parts": [
    {
      "code": "\"\"\"augtrain: the CNN on 100 training images, with four kinds of augmentation.\"\"\"\nimport torch\nimport torch.nn.functional as F\nfrom torchvision.transforms import v2\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), val, _ = tdigits.load(images=True)\nfew = torch.cat([torch.nonzero(y == d).flatten()[:10] for d in range(10)])\nx, y = x[few], y[few]",
      "note": "Ten training images of each digit, a hundred in all, judged on the whole validation set. Augmentation matters most when the data is short, and lesson 7 measured the same 100-image regime."
    },
    {
      "code": "BILINEAR = v2.InterpolationMode.BILINEAR\nAUGMENTS = {\n    \"none\": v2.Identity(),\n    \"shift and turn\": v2.RandomAffine(degrees=15, translate=(0.125, 0.125), interpolation=BILINEAR),\n    \"mirror\": v2.RandomHorizontalFlip(),\n    \"any turn\": v2.RandomRotation(180, interpolation=BILINEAR),\n}",
      "note": "Four policies. `Identity` changes nothing and is the baseline. The second is `augment.py`'s. `RandomHorizontalFlip` mirrors half the images, and `RandomRotation(180)` turns each by any angle at all."
    },
    {
      "code": "def fit(model, augment, epochs, seed):\n    \"\"\"loop.fit's loop, with every image of every batch augmented on its own.\"\"\"\n    opt = torch.optim.Adam(model.parameters(), lr=1e-3)\n    g = torch.Generator().manual_seed(seed)\n    for epoch in range(epochs):\n        order = torch.randperm(len(y), generator=g)\n        for start in range(0, len(y), 32):\n            idx = order[start:start + 32]\n            batch = torch.stack([augment(img) for img in x[idx]])\n            loss = F.cross_entropy(model(batch), y[idx])\n            opt.zero_grad()\n            loss.backward()\n            opt.step()\n    return loop.evaluate(model, *val)",
      "note": "The loop of `loop.py`, with one line added: every image of the batch goes through the transform on its own, so each draws its own change. Validation is never augmented: `loop.evaluate` reads the images as they are."
    },
    {
      "code": "print(f\"{len(y)} training images, {len(val[1])} validation images, 150 epochs\")\nfor name, augment in AUGMENTS.items():\n    accs = []\n    for seed in (0, 1, 2):\n        torch.manual_seed(seed)\n        accs.append(fit(cnn.make_cnn(), augment, epochs=150, seed=seed)[1])\n    print(f\"{name:15s} val acc \" + \"  \".join(f\"{a:.3f}\" for a in accs))",
      "note": "Three seeds per policy, because with 100 images one run says little on its own. The seed fixes the starting weights, the order of the batches and every random draw of the transforms."
    }
  ]
}
```

```
PENDING augtrain
```

Read the rows against the first one.

**The safe augmentation helped, by little and steadily.** With no augmentation the three seeds
gave 0.886, 0.933 and 0.917; with shifts and small turns they gave 0.931, 0.928 and 0.942. The
lowest run with augmentation is above the lowest run without, and the spread shrank. On 100
images the gain is a couple of points; a network that has to learn a shape from ten examples is
helped most by being shown each of them in more than one position.

**The two unsafe ones did damage, and in proportion to how much they lied.** Mirroring half the
images took the network down to 0.819 to 0.858, because a mirrored 2, 3 or 7 went in labelled as
itself. Turning by any angle brought it down to between 0.669 and 0.706, since every 6 and 9 was
taught as both, and every digit had to be learnt in every orientation from ten examples.

Two things this run does not show, said plainly. **Augmentation does not make the network see
validation images differently**: validation is read as drawn, and the gain comes only from what
training learnt. And with all 1,077 training images the gap would be smaller, because the data
already holds more of the variation the transform imitates; it is on short data that
augmentation earns its place.
