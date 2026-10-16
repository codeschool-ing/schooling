---
title: When a deeper network trains worse
version: 1
---

VGG went from 11 layers to 19 and improved at each step, so the obvious next move was 30, then 50.
**It did not work, and the reason was not overfitting.** Overfitting is a network that learns its
training set too well and fails on new data. What happened past about twenty layers was the
opposite: the deeper network did worse **on its own training images**. A deeper network can always
copy a shallower one, with the extra layers passing their input through unchanged, so a worse
training loss means the optimiser could not find a solution that exists. The ResNet paper called it
the degradation problem.

It shows up on the digits. The module below builds the same kind of network at any depth: a first
convolution, a stack of VGG-style blocks of two 3x3 convolutions, and a small head. Save it as
`~/dl/deep.py`:

```schooling-example
{
  "language": "python",
  "file": "deep.py",
  "parts": [
    {
      "code": "\"\"\"deep: plain and residual convolutional networks of any depth, for 1x8x8 digits.\"\"\"\nimport torch.nn as nn\n\n\nclass Plain(nn.Module):\n    \"\"\"Two 3x3 convolutions, each followed by ReLU.\"\"\"\n\n    def __init__(self, width):\n        super().__init__()\n        self.conv1 = nn.Conv2d(width, width, 3, padding=1)\n        self.conv2 = nn.Conv2d(width, width, 3, padding=1)\n        self.relu = nn.ReLU()\n\n    def forward(self, x):\n        return self.relu(self.conv2(self.relu(self.conv1(x))))",
      "note": "A block of two convolutions, VGG's pattern at the size of the digits. Padding 1 keeps every map at 8 by 8, and the width stays 16 channels throughout, so blocks can be stacked as deep as you like."
    },
    {
      "code": "def make(layers, block=Plain, width=16, classes=10):\n    \"\"\"A stem convolution, (layers - 2) / 2 blocks, and a linear head: `layers` weight layers in all.\"\"\"\n    blocks = [block(width) for _ in range((layers - 2) // 2)]\n    return nn.Sequential(\n        nn.Conv2d(1, width, 3, padding=1), nn.ReLU(),\n        *blocks,\n        nn.AdaptiveAvgPool2d(1), nn.Flatten(),\n        nn.Linear(width, classes),\n    )",
      "note": "Depth is counted the way papers count it, in layers that hold weights. A first convolution takes the one channel of ink to 16, the blocks follow, and the head averages each map to one number and reads the 16 numbers with a linear layer. Only `layers` changes between the runs."
    }
  ]
}
```

And a program that trains it at 4, 8, 12 and 20 layers with everything else held fixed. Save it as
`~/dl/depth.py`:

```schooling-example
{
  "language": "python",
  "file": "depth.py",
  "parts": [
    {
      "code": "\"\"\"depth: the same network at four depths, trained the same way, with or without skips.\"\"\"\nimport sys\n\nimport torch\n\nimport deep\nimport loop\nimport tdigits\n\nblock = getattr(deep, sys.argv[1])\ntrain, val, _ = tdigits.load(images=True)",
      "note": "The block's name comes from the command line, `Plain` here and `Residual` in the next section. The digits arrive as 1x8x8 images through the `tdigits.py` of lesson 9."
    },
    {
      "code": "for layers in (4, 8, 12, 20):\n    torch.manual_seed(0)\n    model = deep.make(layers, block)\n    opt = torch.optim.Adam(model.parameters(), lr=0.003)\n    history = loop.fit(model, opt, train, val, epochs=20, every=20)",
      "note": "Four depths, each from the same seed, with the same optimiser, rate and number of epochs. The `loop.py` of lesson 9 trains them and prints the last epoch."
    },
    {
      "code": "    print(f\"{layers} layers, {sum(p.numel() for p in model.parameters())} parameters\")\n    print(\"  train loss by epoch:\", \" \".join(f\"{h[1]:.2f}\" for h in history))",
      "note": "The training loss of every epoch on one line. It is the loss on the images the network learns from, which is the number that tells you whether the optimiser is getting anywhere."
    }
  ]
}
```

```
ana@vm:~/dl$ python depth.py Plain
epoch  20  train loss 0.2585  val loss 0.3467  val acc 0.894
4 layers, 4970 parameters
  train loss by epoch: 2.31 2.29 2.22 1.95 1.63 1.33 1.07 0.97 0.77 0.66 0.57 0.51 0.43 0.40 0.38 0.33 0.32 0.32 0.28 0.26
epoch  20  train loss 0.0783  val loss 0.1454  val acc 0.944
8 layers, 14250 parameters
  train loss by epoch: 2.31 2.17 1.86 1.68 1.46 1.24 1.06 0.81 0.71 0.53 0.39 0.32 0.29 0.27 0.23 0.11 0.12 0.14 0.08 0.08
epoch  20  train loss 0.3691  val loss 0.6342  val acc 0.828
12 layers, 23530 parameters
  train loss by epoch: 2.32 2.31 2.30 2.30 2.21 2.02 1.69 1.50 1.23 1.15 1.24 0.92 0.86 0.77 0.70 0.61 0.55 0.48 0.45 0.37
epoch  20  train loss 2.3013  val loss 2.3078  val acc 0.086
20 layers, 42090 parameters
  train loss by epoch: 2.31 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30
```

Read the parameter counts first. Going from 4 layers to 20 multiplies them by more than eight, from
4,970 to 42,090, so the deep network has every chance to fit the training set.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 320\" role=\"img\" aria-label=\"A line chart of training loss against epoch, 1 to 20, for the plain network at 4, 8, 12 and 20 layers. 4 layers: from 2.31 to 0.26; 8 layers: from 2.31 to 0.08; 12 layers: from 2.32 to 0.37; 20 layers: from 2.31 to 2.30.\"><path d=\"M70 260 L510 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 30 L70 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M66 260.0 L70 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M66 212.08333333333331 L70 212.08333333333331\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"212.08333333333331\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M66 164.16666666666666 L70 164.16666666666666\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"164.16666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.0</text><path d=\"M66 116.25 L70 116.25\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"116.25\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.5</text><path d=\"M66 68.33333333333331 L70 68.33333333333331\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"68.33333333333331\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2.0</text><path d=\"M70.0 260 L70.0 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M162.6315789473684 260 L162.6315789473684 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"162.6315789473684\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M278.42105263157896 260 L278.42105263157896 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"278.42105263157896\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M394.2105263157895 260 L394.2105263157895 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"394.2105263157895\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">15</text><path d=\"M510.0 260 L510.0 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"510.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"290.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">epoch</text><text x=\"30\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">training loss</text><path d=\"M70.0 38.6 L93.2 40.5 L116.3 47.2 L139.5 73.1 L162.6 103.8 L185.8 132.5 L208.9 157.5 L232.1 167.0 L255.3 186.2 L278.4 196.8 L301.6 205.4 L324.7 211.1 L347.9 218.8 L371.1 221.7 L394.2 223.6 L417.4 228.4 L440.5 229.3 L463.7 229.3 L486.8 233.2 L510.0 235.1\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M70.0 38.6 L93.2 52.0 L116.3 81.8 L139.5 99.0 L162.6 120.1 L185.8 141.2 L208.9 158.4 L232.1 182.4 L255.3 192.0 L278.4 209.2 L301.6 222.6 L324.7 229.3 L347.9 232.2 L371.1 234.1 L394.2 238.0 L417.4 249.5 L440.5 248.5 L463.7 246.6 L486.8 252.3 L510.0 252.3\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70.0 37.7 L93.2 38.6 L116.3 39.6 L139.5 39.6 L162.6 48.2 L185.8 66.4 L208.9 98.0 L232.1 116.2 L255.3 142.1 L278.4 149.8 L301.6 141.2 L324.7 171.8 L347.9 177.6 L371.1 186.2 L394.2 192.9 L417.4 201.5 L440.5 207.3 L463.7 214.0 L486.8 216.9 L510.0 224.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M70.0 38.6 L93.2 39.6 L116.3 39.6 L139.5 39.6 L162.6 39.6 L185.8 39.6 L208.9 39.6 L232.1 39.6 L255.3 39.6 L278.4 39.6 L301.6 39.6 L324.7 39.6 L347.9 39.6 L371.1 39.6 L394.2 39.6 L417.4 39.6 L440.5 39.6 L463.7 39.6 L486.8 39.6 L510.0 39.6\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M524 50 L546 50\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"570\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">4</text><text x=\"576\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">layers</text><path d=\"M524 74 L546 74\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"570\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">8</text><text x=\"576\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">layers</text><path d=\"M524 98 L546 98\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"570\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">12</text><text x=\"576\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">layers</text><path d=\"M524 122 L546 122\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"570\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"576\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">layers</text></svg>", "caption": "Training loss per epoch for the plain network at four depths, from the capture above."}
```

**Up to 8 layers, depth helps.** The 8-layer network ends at a training loss of 0.08 against 0.26
for the 4-layer one, and reaches 0.944 on validation against 0.894. **Past 8, it gets worse.** The
12-layer network sits at 2.30 for its first four epochs before it starts to move, and it ends at
0.37, a worse training loss than the 4-layer network, which has less than a quarter of its parameters. The
20-layer network never starts. Its loss stays at 2.30, the loss of a network that gives each of the
ten digits the same probability, and its accuracy is 0.086, one fixed guess for every image.

Two things about this run:

- **It is the training loss that fails**, so neither more data nor regularisation, lesson 7's cures,
  can help. Those fight a gap between training and validation, and the 20-layer network has no gap
  to close: both losses are stuck.
- **These networks have no normalisation**, and that makes the failure extreme. In the ResNet paper
  the plain networks had batch normalisation (lesson 8) and still trained, only worse: the 34-layer
  plain network ended with a higher training error than the 18-layer one. The shape is the same, and
  the next section shows what was stopping the optimiser.
