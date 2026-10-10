---
title: Augmentation with torchvision's transforms
version: 1
---

Lesson 7 shifted the digits by one pixel with NumPy slicing, wrote every shifted copy into a bigger
training set, and trained on that. **For images, torchvision does this for you, and differently:
each time an image is used, a transform draws a new random change.** Nothing is stored. In an
epoch of 100 images the network sees 100 variants nobody has seen before, and the next epoch sees
100 more.

The transforms live in `torchvision.transforms.v2`. They take a tensor whose last two dimensions
are height and width, which is what `tdigits.load(images=True)` returns, so they apply to the
digits without any conversion. Save this as `~/dl/augment.py`:

```schooling-example
{
  "language": "python",
  "file": "augment.py",
  "parts": [
    {
      "code": "\"\"\"augment: what torchvision's transforms do to a digit, drawn in characters.\"\"\"\nimport torch\nfrom torchvision.transforms import v2\n\nimport tdigits\n\n(x, y), _, _ = tdigits.load(images=True)",
      "note": "The digits as images, shape 1x8x8 each, from the `tdigits.py` of lesson 9. `transforms.v2` is torchvision's current set of transforms, and it works on tensors directly."
    },
    {
      "code": "def draw(images):\n    \"\"\"Several 1x8x8 images side by side, ink as characters.\"\"\"\n    for r in range(8):\n        print(\"   \".join(\"\".join(\" .:-=+*#@\"[int(v * 8)] for v in img[0, r].clamp(0, 1))\n                         for img in images))",
      "note": "The drawing `look.py` did in lesson 1, for several images in a row. `clamp` keeps a value nudged past 1 by the interpolation inside the nine characters."
    },
    {
      "code": "torch.manual_seed(0)\njitter = v2.RandomAffine(degrees=15, translate=(0.125, 0.125),\n                         interpolation=v2.InterpolationMode.BILINEAR)\nprint(\"label\", y[0].item(), \"shape\", tuple(x[0].shape), \"- the original, then four draws:\")\ndraw([x[0]] + [jitter(x[0]) for _ in range(4)])",
      "note": "One transform, called four times on the same 6. Each call draws a new angle between -15 and 15 degrees and a new shift of up to an eighth of the width, one pixel here. Bilinear interpolation blends neighbouring pixels; the default, nearest, would snap a turned stroke into steps."
    },
    {
      "code": "shift = v2.RandomAffine(degrees=0, translate=(0.25, 0.25))\nbatch = x[:4]\nprint(\"four digits:\", y[:4].tolist())\ndraw(batch)\nprint(\"one call on the batch of four:\")\ndraw(shift(batch))\nprint(\"one call per image:\")\ndraw(torch.stack([shift(img) for img in batch]))",
      "note": "A shift of up to two pixels, given a batch of four images in one call and then one image per call. The two are not the same thing, and the output shows how."
    }
  ]
}
```

```
PENDING augment
```

## One transform, a different image each call

The first block is one 6 and four calls to the same `RandomAffine`. **No two came out alike**: one
leans left, one sits a pixel lower, one is turned enough to thin the loop. Every one is still a 6
that a person would read without hesitating, and that is the whole contract of an augmentation:
change what the label does not depend on, and nothing else.

`RandomAffine` covers the changes that matter most for small images: turning (`degrees`), moving
(`translate`, as a fraction of the size), zooming (`scale`) and slanting (`shear`). The rest of
the module has the others a photograph wants, among them `RandomResizedCrop` for a crop of a
random part, `ColorJitter` for brightness and contrast, and `RandomHorizontalFlip`. The next
section is about why that last one is wrong for digits.

## A batch gets one draw

The second half is the trap. **Given a batch of four images in one call, the transform drew one
shift and applied it to all four**: every digit moved up a pixel and left a pixel, together, and
the 2 on the right lost its top row. Called once per image, each of the four moved its own way.

The v2 transforms treat everything they are given in one call as one sample: an image with its
mask, or a batch that should move as one. That is the right behaviour for a picture and its
labels, and the wrong one for a training batch, where a shared shift teaches the network nothing
a single shifted image would not. The usual place to call a transform is therefore per image,
inside a `Dataset`'s `__getitem__` as lesson 10 did, so that every image draws its own. This
lesson's programs do the same thing in one line with `torch.stack`.
