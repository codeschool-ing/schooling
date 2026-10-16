---
title: Choosing one
version: 1
---

The newest architecture is not automatically the right one, and **the best one on ImageNet is not
automatically the best one on your data**. The numbers that decide it are on record: torchvision
stores, beside every set of trained weights, how many parameters the network has, how many operations
one image costs and the accuracy those weights reached. Reading them downloads nothing. Save as
`~/dl/card.py`:

```schooling-example
{
  "language": "python",
  "file": "card.py",
  "parts": [
    {
      "code": "\"\"\"card: five architectures as torchvision records them, read without downloading a weight.\"\"\"\nfrom torchvision import models\n\nprint(f\"{'model':20s} {'parameters':>12s} {'GFLOPs':>7s} {'image':>6s} {'top-1 %':>8s}\")"
    },
    {
      "code": "for name in (\"vgg16\", \"resnet18\", \"resnet50\", \"efficientnet_b0\", \"mobilenet_v3_small\"):\n    weights = models.get_model_weights(name).IMAGENET1K_V1\n    meta = weights.meta\n    print(f\"{name:20s} {meta['num_params']:>12,d} {meta['_ops']:>7.2f} \"\n          f\"{weights.transforms().crop_size[0]:>6d} {meta['_metrics']['ImageNet-1K']['acc@1']:>8.1f}\")",
      "note": "`meta` is what torchvision records about each set of weights: the parameter count, the billions of operations one image costs, and the top-1 accuracy those weights reached on ImageNet's validation set. They are torchvision's figures, not measured here."
    }
  ]
}
```

```
ana@vm:~/dl$ python card.py
model                  parameters  GFLOPs  image  top-1 %
vgg16                 138,357,544   15.47    224     71.6
resnet18               11,689,512    1.81    224     69.8
resnet50               25,557,032    4.09    224     76.1
efficientnet_b0         5,288,548    0.39    224     77.7
mobilenet_v3_small      2,542,856    0.06    224     67.7
```

GFLOPs are billions of floating-point operations for one image, and top-1 is the percentage of
ImageNet's validation photographs whose first guess was right. **These are torchvision's figures for
its own trained weights, not measurements made for this course**, which never ran one of these
networks on a real photograph.

Three things to read off it:

- **VGG-16 is the worst deal on the card**: the most parameters and the most work per image, for a
  top-1 below EfficientNet-B0's, which has 26 times fewer parameters. It survives in teaching and
  in old code.
- **EfficientNet-B0 beats ResNet-50 on accuracy** with a fifth of the parameters and less than a tenth
  of the operations. Operations are not time, though: a depthwise convolution does little arithmetic
  per byte it reads, and on a graphics card a ResNet often finishes sooner than its operation count
  suggests. How long a network takes on your machine is something to measure, and lesson 19 does.
- **MobileNet-V3-Small is built for a budget**, 0.06 GFLOPs, and gives up about ten points of
  accuracy to EfficientNet-B0 to meet it.

**And on small images, none of them may be the right choice.** All five were designed for photographs
of 224 by 224 pixels, and their stems shrink the image fast. The digits are 8 by 8. This program
trains ResNet-18 against the `cnn.py` of lesson 11 on them, with the stem changed to take one channel.
Save as `~/dl/small.py`:

```schooling-example
{
  "language": "python",
  "file": "small.py",
  "parts": [
    {
      "code": "\"\"\"small: ResNet-18 against lesson 11's small CNN, on the 8x8 digits.\"\"\"\nimport time\n\nimport torch\nimport torch.nn as nn\nfrom torchvision.models import resnet18\n\nimport cnn\nimport loop\nimport tdigits\n\n\ndef resnet():\n    model = resnet18(weights=None, num_classes=10)\n    model.conv1 = nn.Conv2d(1, 64, 7, stride=2, padding=3, bias=False)\n    return model",
      "note": "ResNet-18 with ten outputs and a stem that takes one channel of ink instead of three of colour. Everything else is torchvision's, stride and pooling included."
    },
    {
      "code": "train, val, _ = tdigits.load(images=True)\nfor name, build in ((\"cnn.make_cnn\", cnn.make_cnn), (\"resnet18\", resnet)):\n    torch.manual_seed(0)\n    model = build()\n    print(name, sum(p.numel() for p in model.parameters()), \"parameters\")\n    start = time.perf_counter()\n    loop.fit(model, torch.optim.Adam(model.parameters(), lr=0.001), train, val, epochs=10, every=5)\n    print(f\"  {time.perf_counter() - start:.0f} s\")",
      "note": "The `cnn.py` of lesson 11 and ResNet-18, the same seed, optimiser, rate and ten epochs, through lesson 9's `loop.py`. The time is wall-clock on this machine."
    }
  ]
}
```

```
ana@vm:~/dl$ python small.py
cnn.make_cnn 38282 parameters
epoch   5  train loss 0.3023  val loss 0.2438  val acc 0.939
epoch  10  train loss 0.0985  val loss 0.1518  val acc 0.953
  1 s
resnet18 11175370 parameters
epoch   5  train loss 0.2078  val loss 0.2733  val acc 0.931
epoch  10  train loss 0.1344  val loss 0.2077  val acc 0.939
  23 s
```

ResNet-18 has 11,175,370 parameters against the small network's 38,282, about 290 times as many, and
it ends at 0.939 on validation against 0.953. It took 23 seconds to get there, against 1. Its stem divides
the side by four, as the 224 to 56 of the ResNet-18 section showed, so the digits reach the first residual
block as 2 by 2 maps and most of the machinery works on four pixels. An architecture carries assumptions about its input, and the size of the image is the
first of them.

A practical order of choice, for images:

1. **Start from what has trained weights for a task like yours.** Training from random weights is
   what this lesson did, and it is the exception; lesson 13 starts from weights already trained, and
   that matters more than the architecture.
2. **A ResNet is the baseline**: well understood, supported by every tool, and with no unusual
   layers to go wrong when it is exported.
3. **EfficientNet when accuracy per parameter matters**, and the image size it was scaled for can be
   given to it.
4. **MobileNet when the model runs on a phone** or anything else with a budget in milliseconds.
5. **For small or unusual inputs, a small network of your own**, as the digits show.

Vision transformers, which treat an image as a sequence of patches, now compete with all of these when
there is a lot of data to train on. They need the transformer of lesson 15 first.
