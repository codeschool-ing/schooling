---
title: Augmentation, more data out of the data you have
version: 1
---

The other cures restrain the network. **Augmentation changes the data instead**: it makes new training
examples from the old ones by changes that cannot alter the answer. A 3 moved one pixel to the left is
still a 3, so every image can give four more, moved up, down, left and right, each with the same label.

This is the strongest cure when it applies, because overfitting is a shortage of examples and this
makes more. It also has a condition that cannot be skipped: **the change must keep the label true.**
A one-pixel shift does, on 8 by 8 digits. A horizontal flip would not, because it turns some digits
into shapes that are not digits at all, and lesson 13 shows a rotation turning a 6 into a 9.

Save as `~/dl/shift.py`:

```schooling-example
{
  "language": "python",
  "file": "shift.py",
  "parts": [
    {
      "code": "\"\"\"shift: four more copies of every image, each moved by one pixel.\"\"\"\nimport numpy as np",
      "note": "Only NumPy: the new images are computed from the old ones."
    },
    {
      "code": "def shifted(x, y):\n    \"\"\"The images, then all of them moved up, down, left and right.\"\"\"\n    img = x.reshape(-1, 8, 8)\n    out = [img]\n    for axis, step in ((1, -1), (1, 1), (2, -1), (2, 1)):\n        moved = np.roll(img, step, axis=axis)\n        edge = 0 if step == 1 else -1\n        if axis == 1:\n            moved[:, edge, :] = 0\n        else:\n            moved[:, :, edge] = 0\n        out.append(moved)\n    return np.concatenate(out).reshape(-1, 64), np.tile(y, 5)",
      "note": "Each row of 64 goes back to 8 by 8. `np.roll` moves every image one pixel along an axis, and the row or column that wrapped round to the other side is set to zero, as if the paper continued blank. The labels are the same five times over, because moving a digit one pixel does not change which digit it is."
    },
    {
      "code": "if __name__ == \"__main__\":\n    import small\n    from fit import evaluate, fit\n    from optim import SGD\n\n    train, val = small.data()\n    big = shifted(*train)\n    print(\"images:\", len(train[1]), \"->\", len(big[1]), \" labels\", big[1][[0, 100, 400]])\n    print(\"original  up        right\")\n    for rows in zip(*(big[0][i].reshape(8, 8) for i in (0, 100, 400))):\n        print(\"  \".join(\"\".join(\" .:#\"[int(v * 3.99)] for v in row) for row in rows))",
      "note": "The first image in three of its five copies, drawn in characters: as it was, moved up, and moved right. Image 100 is the first of the copies moved up, and 400 the first moved right."
    },
    {
      "code": "    net = small.wide()\n    fit(net, SGD(net.params(), lr=0.2), big, val, epochs=300, every=50)\n    loss, acc = evaluate(net, *val)\n    print(f\"train acc {evaluate(net, *train)[1]:.3f}  val loss {loss:.4f}  val acc {acc:.3f}\")",
      "note": "The same network and the same 300 epochs as `overfit.py`, on 500 images. The train accuracy at the end is measured on the original 100."
    }
  ]
}
```

```
PENDING shift
```

The three drawings are one 6, as it was, moved up, and moved right. The top row of the moved-up copy
is the old second row, and its bottom row is blank.

**Accuracy improves more than anything else so far**: 0.928 at the end, against 0.903, nine more
validation images right out of 360. The network has seen each digit in five positions, and the
validation set has digits drawn a little off-centre too.

**The loss did not get better.** It ends at 0.3724, higher than without augmentation, and it climbs
from epoch 50 onwards in the same way. With 500 images and 16 steps an epoch, 300 epochs are five times
as many steps, and the network still reaches 1.000 on its training images and keeps growing more
confident. Five shifted copies of 100 images are not 500 independent images: they are the same 100
drawings, and a network this size can memorise all five versions. Augmentation moved the accuracy;
something else still has to stop the run.

Here the 400 new images were made once, before training. Frameworks more often draw a fresh random
change every time an image is used, so no two epochs see exactly the same set, and lesson 10 builds a
transform of that kind into a data loader.
