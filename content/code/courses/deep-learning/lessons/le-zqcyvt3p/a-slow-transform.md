---
title: a-slow-transform
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "warp.py",
  "parts": [
    {
      "code": "\"\"\"warp: a transform that costs real work for every image read, as decoding and augmenting a photograph does.\"\"\"\nimport torch\nimport torch.nn.functional as F",
      "note": "Everything here is ordinary tensor arithmetic from `torch.nn.functional`: no library of image transforms, and no sleeping to fake a cost."
    },
    {
      "code": "class Warp:\n    \"\"\"Turn a flat 8x8 digit into a 32x32 image, bent by a smooth random field, with noise added.\"\"\"\n\n    def __init__(self, size=32, work=128, strength=0.08, noise=0.05):\n        self.size, self.work, self.strength, self.noise = size, work, strength, noise\n        self.base = F.affine_grid(torch.eye(2, 3)[None], [1, 1, work, work], align_corners=False)\n\n    def __call__(self, img):\n        w = self.work\n        big = F.interpolate(img.reshape(1, 1, 8, 8), size=(w, w), mode=\"bicubic\", align_corners=False)\n        field = F.interpolate(2 * torch.rand(1, 2, 4, 4) - 1, size=(w, w), mode=\"bicubic\", align_corners=False)\n        bent = F.grid_sample(big, self.base + self.strength * field.permute(0, 2, 3, 1),\n                             mode=\"bicubic\", align_corners=False)\n        small = F.interpolate(bent, size=(self.size, self.size), mode=\"bilinear\", antialias=True, align_corners=False)\n        return small[0] + self.noise * torch.randn(1, self.size, self.size)",
      "note": "Four steps for every image. Blow the 8x8 digit up to 128x128 by bicubic interpolation; make a smooth random field from 4x4 random numbers; move every pixel along that field with `grid_sample`, which bends the strokes the way two people write one digit differently; shrink the result to 32x32 with antialiasing and add a little noise. Working at 128 and shrinking is what a real pipeline does with a large photograph, and it is where the cost comes from."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "slow.py",
  "parts": [
    {
      "code": "\"\"\"slow: what the warp costs per image against a plain read, and what it makes of digit 0.\"\"\"\nimport time\n\nimport torch\n\nfrom dset import Digits\nfrom warp import Warp\n\ntorch.manual_seed(0)\nplain, warped = Digits(\"train\"), Digits(\"train\", transform=Warp())\nfor name, ds in ((\"plain\", plain), (\"warped\", warped)):\n    start = time.perf_counter()\n    for i in range(len(ds)):\n        ds[i]\n    per = (time.perf_counter() - start) / len(ds)\n    print(f\"{name:6s} {per * 1e6:7.1f} microseconds an image, {per * len(ds):.3f} s for all {len(ds)}\")",
      "note": "Every item of the training set read once, with and without the transform, timed with `time.perf_counter`. Reading a plain item is indexing two tensors that are already in memory."
    },
    {
      "code": "img, label = warped[0]\nprint(\"item 0:\", tuple(img.shape), \" label\", label.item(), \" read again, same image:\", torch.equal(img, warped[0][0]))",
      "note": "The same index read twice. The transform runs at every read and draws new random numbers each time."
    },
    {
      "code": "RAMP = \" .:-=+*#%@\"\n\n\ndef rows(picture):\n    \"\"\"A 32x32 picture as 16 lines of characters, two pixel rows to a line.\"\"\"\n    shades = picture.reshape(16, 2, 32).mean(dim=1).clamp(0, 1)\n    return [\"\".join(RAMP[int(v * 9.99)] for v in row) for row in shades]",
      "note": "A picture in the terminal: each brightness from 0 to 1 becomes one of ten characters, from a space to `@`. Two pixel rows share a line because a character is about twice as tall as it is wide."
    },
    {
      "code": "original = plain[0][0].reshape(8, 8).repeat_interleave(4, dim=0).repeat_interleave(4, dim=1)\npanels = [rows(original), rows(warped[0][0][0]), rows(warped[0][0][0])]\nfor line in zip(*panels):\n    print(\"  \".join(line))",
      "note": "Three panels side by side: the original 8x8 digit with each pixel repeated four times, then two reads of the same warped item."
    }
  ]
}
```
