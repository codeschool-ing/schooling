---
title: What an augmentation must preserve
version: 1
---

The tempting reading of the last section is that more variety is always better: turn the digits
by any angle, mirror them, and the network sees more of the world. **An augmentation is a claim
that the change does not alter the label, and for some changes on some images the claim is
false.** A 6 turned upside down is a 9. A 2 mirrored left to right is not a 2 of any handwriting.

That can be measured before any augmented training, by asking a network that never saw a turned
or mirrored digit what it makes of them. Save as `~/dl/preserve.py`:

```schooling-example
{
  "language": "python",
  "file": "preserve.py",
  "parts": [
    {
      "code": "\"\"\"preserve: a trained CNN reads flipped and turned digits.\"\"\"\nimport torch\nfrom torchvision.transforms import v2\n\nimport cnn\nimport loop\nimport tdigits\n\ntrain, (x, y), _ = tdigits.load(images=True)\ntorch.manual_seed(0)\nmodel = cnn.make_cnn()\nloop.fit(model, torch.optim.Adam(model.parameters(), lr=1e-3), train, (x, y), epochs=20, every=20)\nmodel.eval()",
      "note": "The CNN of lesson 11, trained on all ten digits with no augmentation at all. `x` and `y` are the validation set, which is what the rest of the program reads."
    },
    {
      "code": "def predict(images):\n    with torch.no_grad():\n        return model(images).argmax(dim=1)\n\n\nviews = {\"as drawn\": x, \"mirrored\": v2.functional.horizontal_flip(x),\n         \"upside down\": v2.functional.rotate(x, 180)}",
      "note": "The functional forms of the transforms apply one fixed change, with nothing random, to the whole set: a mirror image left to right, and a half turn."
    },
    {
      "code": "print(\"digit \" + \"\".join(f\"{name:>13}\" for name in views))\nfor d in range(10):\n    keep = y == d\n    row = [(predict(v[keep]) == d).float().mean().item() for v in views.values()]\n    print(f\"{d:5d} \" + \"\".join(f\"{a:13.2f}\" for a in row))",
      "note": "For each digit, the share of its validation images that the network still calls by their own label, in each of the three views."
    },
    {
      "code": "for d in (6, 9):\n    guesses = predict(views[\"upside down\"][y == d])\n    print(f\"{d}s turned upside down are read as:\", torch.bincount(guesses, minlength=10).tolist())",
      "note": "Where the upside-down 6s and 9s went: one count per answer, from 0 to 9."
    }
  ]
}
```

```
PENDING preserve
```

The first column is the network on the images as drawn, between 0.92 and 1.00 for every digit.
The other two are the same images changed, and **what survives is exactly what a person would
predict from the shapes**. The 0 and the 8 are symmetric both ways and keep 0.94 and 0.91 mirrored,
0.91 and 0.89 upside down. The 3, the 6 and the 2 have a direction, and fall to 0.00, 0.00 and
0.11 when mirrored.

The last two lines are the trap in its plainest form. **Of the 6s turned upside down, 40 were
read as 9**. The upside-down 9s spread wider, with 18 read as 6, but none was read as a 9. If
training had used a rotation of up to 180 degrees, every one of those images would have gone into
the loss with its old label, and the network would have been taught that a shape is both a 6 and
a 9.

## The rule, and where it bends

Choose an augmentation by asking whether a person would still give the image the same label after
it. For these digits, small turns and shifts pass, and large turns and mirroring fail. The answer
belongs to the task, not to the transform:

| images | a horizontal flip | a large rotation |
| --- | --- | --- |
| handwritten digits, letters | changes the label | changes the label |
| photographs of animals or cars | keeps it | rarely right: the world has an up |
| satellite or microscope images | keeps it | keeps it: there is no up |
| road signs with arrows | turns a left arrow into a right one | changes the label |

A change can also be fine for the label and still break something the task needs. A crop that
cuts off the object, a colour change on a task about ripeness, or a blur when the answer is in
the fine detail all keep the label written down while removing the evidence for it.
