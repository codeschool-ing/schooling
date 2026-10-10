---
title: Channels, and what a convolution costs
version: 1
---

A layer of convolution is not one filter. **It is many filters side by side, and each one makes a map
of its own**, called a channel. Sixteen filters over a digit give sixteen 8 by 8 maps: one may light up
on left edges, another on the bottom of a loop. The next layer then reads all sixteen maps at once, so
its filters are not 3 by 3 but 16 by 3 by 3, one 3 by 3 slice per channel coming in. A colour
photograph is the same idea from the start: three channels, red, green and blue.

The weight of `nn.Conv2d` has the shape `(out_channels, in_channels, k, k)`, and its parameters can
be counted by hand. Save as `~/dl/params.py`:

```schooling-example
{
  "language": "python",
  "file": "params.py",
  "parts": [
    {
      "code": "\"\"\"params: what a convolution costs, against a dense layer giving the same outputs.\"\"\"\nimport torch.nn as nn\n\n\ndef count(layer):\n    return sum(p.numel() for p in layer.parameters())"
    },
    {
      "code": "conv1 = nn.Conv2d(1, 16, kernel_size=3, padding=1)\nprint(\"conv1 weight\", tuple(conv1.weight.shape), \"bias\", tuple(conv1.bias.shape), \"->\", count(conv1))\nprint(\"a Linear from 64 pixels to 16 x 8 x 8 outputs ->\", count(nn.Linear(64, 16 * 8 * 8)))",
      "note": "The first layer of the network in the next section: 16 filters over a 1-channel image, padded so each output map stays 8 by 8. A dense layer producing the same 1,024 numbers needs a weight from every pixel to every one of them."
    },
    {
      "code": "conv2 = nn.Conv2d(16, 32, kernel_size=3, padding=1)\nprint(\"conv2 weight\", tuple(conv2.weight.shape), \"bias\", tuple(conv2.bias.shape), \"->\", count(conv2))\nprint(\"a Linear from 16 x 8 x 8 to 32 x 8 x 8 ->\", count(nn.Linear(16 * 8 * 8, 32 * 8 * 8)))",
      "note": "The second layer reads the 16 maps the first one made. Each of its 32 filters is 16 by 3 by 3: it looks at the same 3x3 place in all 16 maps at once."
    },
    {
      "code": "# The same conv1 on a 224 x 224 colour photograph, and the dense layer it would replace.\nphoto = nn.Conv2d(3, 16, kernel_size=3, padding=1)\nprint(\"conv on a 3 x 224 x 224 photo ->\", count(photo))\nprint(\"a Linear doing the same ->\", 3 * 224 * 224 * 16 * 224 * 224 + 16 * 224 * 224)",
      "note": "A photograph has three channels, red, green and blue. The dense layer is counted with arithmetic rather than built, because building it would need far more memory than the machine has."
    }
  ]
}
```

```
ana@vm:~/dl$ python params.py
conv1 weight (16, 1, 3, 3) bias (16,) -> 160
a Linear from 64 pixels to 16 x 8 x 8 outputs -> 66560
conv2 weight (32, 16, 3, 3) bias (32,) -> 4640
a Linear from 16 x 8 x 8 to 32 x 8 x 8 -> 2099200
conv on a 3 x 224 x 224 photo -> 448
a Linear doing the same -> 120847089664
```

**The first layer has 160 parameters**: 16 filters of 1 × 3 × 3 weights, plus one bias each. A dense
layer that turned the same 64 pixels into the same 1,024 outputs would need 66,560. **The second layer
has 4,640**, 32 × 16 × 9 + 32, against 2,099,200 for the dense one. On a photograph the gap stops
being a ratio and becomes a wall: 448 for the convolution, and 120,847,089,664 for a dense layer, a
number no machine would hold.

**The count does not depend on the size of the image.** The same 448 parameters run on a photograph of
any size, because the filter is the same at every position. That is weight sharing, and it is the
whole saving: a dense layer pays for every pair of input and output, a convolution pays for one small
window.

The saving is not free. A convolution can only combine pixels that are close together, and it treats
every place in the image alike. Those are two assumptions about pictures, and for pictures they are
right: a stroke is made of neighbouring pixels, and a stroke is a stroke wherever it is drawn. A dense
layer could learn the same thing, but it would have to learn it separately for every position, from
examples.
