---
title: MobileNet and EfficientNet, and the convolution split in two
version: 1
---

ResNet answered how to go deeper. **The next question came from phones**: how to get the same
accuracy from fewer operations, on a processor with a battery behind it. The answer both MobileNet
and EfficientNet are built on is to stop asking one filter to do two jobs.

A full 3x3 convolution from 32 channels to 64 does two things at once. It looks at a 3 by 3
neighbourhood, and it mixes the 32 input channels into each of the 64 outputs. It pays for both
together: 3 × 3 × 32 × 64 weights. **A depthwise separable convolution does them one after the
other.** First a depthwise convolution gives each input channel its own 3x3 filter and mixes nothing,
3 × 3 × 32 weights. Then a pointwise 1x1 convolution mixes the channels at each pixel and looks at no
neighbourhood, 32 × 64 weights. Save as `~/dl/separable.py`:

```schooling-example
{
  "language": "python",
  "file": "separable.py",
  "parts": [
    {
      "code": "\"\"\"separable: a 3x3 convolution against its depthwise separable version, and where the second one is used.\"\"\"\nimport torch\nimport torch.nn as nn\nfrom torchvision.models import efficientnet_b0, mobilenet_v3_small\n\n\ndef params(m):\n    return sum(p.numel() for p in m.parameters())"
    },
    {
      "code": "full = nn.Conv2d(32, 64, 3, padding=1, bias=False)\ndepthwise = nn.Conv2d(32, 32, 3, padding=1, groups=32, bias=False)\npointwise = nn.Conv2d(32, 64, 1, bias=False)",
      "note": "`groups=32` splits the 32 input channels into 32 groups of one, so each channel gets its own 3x3 filter and nothing mixes across channels. The 1x1 convolution then mixes them, one pixel at a time. No bias, as in the networks that use this."
    },
    {
      "code": "x = torch.randn(1, 32, 56, 56)\nprint(\"full 3x3:  \", params(full), \"parameters, output\", tuple(full(x).shape))\nprint(\"depthwise: \", params(depthwise), \"parameters, output\", tuple(depthwise(x).shape))\nprint(\"pointwise: \", params(pointwise), \"parameters, output\", tuple(pointwise(depthwise(x)).shape))\nprint(\"separable: \", params(depthwise) + params(pointwise), \"parameters\")",
      "note": "The same input through both, to check the pair ends at the same shape as the full convolution."
    },
    {
      "code": "for build in (mobilenet_v3_small, efficientnet_b0):\n    convs = [m for m in build(weights=None).modules() if isinstance(m, nn.Conv2d)]\n    dw = sum(1 for c in convs if c.groups > 1 and c.groups == c.in_channels)\n    one = sum(1 for c in convs if c.kernel_size == (1, 1))\n    print(f\"{build.__name__}: {len(convs)} convolutions, {dw} depthwise, {one} 1x1\")",
      "note": "Every convolution in the two networks, sorted into depthwise (one group per input channel), 1x1, and whatever is left."
    }
  ]
}
```

```
PENDING separable
```

The pair reaches the same output shape for 2,336 parameters against 18,432, nearly eight times fewer, and
the multiplications per pixel fall by the same factor. **It is not the same function.** A full
convolution can learn a filter that is a different 3x3 pattern for every pair of channels; the
separable one cannot, and it is a bet that it rarely needs to. The networks that make the bet repay
it with width and depth bought with the savings.

The last two lines show how far it goes. Of MobileNet-V3-Small's 52 convolutions, 11 are depthwise
and 40 are 1x1; the one left over is the first convolution, which reads the three colour channels.
EfficientNet-B0 is the same: 81 convolutions, 16 depthwise, 64 of them 1x1, and one full
convolution at the entrance. Both also use a small branch that rescales each channel by a learnt
weight, called squeeze-and-excitation, which accounts for some of those 1x1 layers.

**EfficientNet added a second idea, compound scaling.** A network that works at one size can be made bigger in three ways: more layers, more channels per
layer, or larger images. Before EfficientNet, a paper usually picked one. **EfficientNet's claim is
that the three should grow together**, by fixed proportions: if a network gets more layers it also
needs more channels to carry what they find, and a larger image needs both to cover it. Its authors
searched for a good small network, B0, then scaled all three at once by one coefficient to get B1 to
B7. Save as `~/dl/scaling.py`:

```schooling-example
{
  "language": "python",
  "file": "scaling.py",
  "parts": [
    {
      "code": "\"\"\"scaling: EfficientNet-B0 to B7, built empty, and the three things that grow together.\"\"\"\nfrom torchvision import models\n\nprint(f\"{'model':16s} {'blocks':>6s} {'width':>6s} {'image':>6s} {'parameters':>12s}\")"
    },
    {
      "code": "for i in range(8):\n    name = f\"efficientnet_b{i}\"\n    model = getattr(models, name)(weights=None)\n    blocks = sum(len(stage) for stage in model.features[1:-1])\n    width = model.features[-1][0].in_channels",
      "note": "Depth is the number of blocks between the first convolution and the last one, and width is the channel count the blocks end on. Both are read off the built network."
    },
    {
      "code": "    image = models.get_model_weights(name).IMAGENET1K_V1.transforms().crop_size[0]\n    params = sum(p.numel() for p in model.parameters())\n    print(f\"{name:16s} {blocks:6d} {width:6d} {image:6d} {params:12,d}\")",
      "note": "Each model's trained weights come with the transform they were trained behind, and its crop size is the image resolution. Asking for the transform reads torchvision's own record and downloads nothing."
    }
  ]
}
```

```
PENDING scaling
```

**Read down the columns: all three grow at every step.** From B0 to B7 the blocks go from 16 to 55,
the final width from 320 channels to 640, and the image from 224 pixels to 600, and the parameters
from 5,288,548 to 66,347,960. None of them grows alone. The image column is the one people miss: B7
was trained on 600 by 600 images, and feeding it 224 by 224 throws away much of what it was scaled
for.

EfficientNet-B0 has fewer than half the parameters of ResNet-18, and the last section puts their
accuracy side by side.
