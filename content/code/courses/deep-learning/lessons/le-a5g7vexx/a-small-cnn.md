---
title: A small convolutional network against lesson 9's
version: 1
---

The pieces now fit together in a dozen lines. **This is `cnn.py`**, the network the rest of this
lesson trains and that lessons 12, 13, 17 and 19 come back to. Save it as `~/dl/cnn.py`:

```schooling-example
{
  "language": "python",
  "file": "cnn.py",
  "parts": [
    {
      "code": "\"\"\"cnn: a small convolutional network for 1x8x8 digits.\"\"\"\nimport torch.nn as nn",
      "note": "The network lessons 12, 13, 17 and 19 start from. It is a function that builds a fresh one, so every lesson gets new weights."
    },
    {
      "code": "def make_cnn(classes=10):\n    return nn.Sequential(\n        nn.Conv2d(1, 16, kernel_size=3, padding=1),   # 16 x 8 x 8\n        nn.ReLU(),\n        nn.Conv2d(16, 32, kernel_size=3, padding=1),  # 32 x 8 x 8\n        nn.ReLU(),\n        nn.MaxPool2d(2),                              # 32 x 4 x 4\n        nn.Flatten(),                                 # 512\n        nn.Linear(512, 64),\n        nn.ReLU(),\n        nn.Linear(64, classes),\n    )",
      "note": "Two convolutions with a ReLU after each, then one max pooling, and the comments say the shape of what leaves each line. `Flatten` lays the 32 maps of 4 by 4 out as 512 numbers in a row, and from there it is lesson 9's dense network with a wider input. `classes` is 10 for the digits and changes when lesson 13 trains on five of them."
    }
  ]
}
```

PyTorch describes a model when it is printed, and the description is a quick check that the layers are
the ones you meant:

```
ana@vm:~/dl$ python -c "import cnn; print(cnn.make_cnn())"
Sequential(
  (0): Conv2d(1, 16, kernel_size=(3, 3), stride=(1, 1), padding=(1, 1))
  (1): ReLU()
  (2): Conv2d(16, 32, kernel_size=(3, 3), stride=(1, 1), padding=(1, 1))
  (3): ReLU()
  (4): MaxPool2d(kernel_size=2, stride=2, padding=0, dilation=1, ceil_mode=False)
  (5): Flatten(start_dim=1, end_dim=-1)
  (6): Linear(in_features=512, out_features=64, bias=True)
  (7): ReLU()
  (8): Linear(in_features=64, out_features=10, bias=True)
)
```

A comparison with lesson 9's dense network is only worth something if both are trained the same way,
and if the size of the network is not doing the work. So the program below trains three: lesson 9's,
a dense one widened to about as many parameters as the convolutional one, and `cnn.py`. It needs the
`digits.py` from lesson 1 and the `tdigits.py` and `loop.py` from lesson 9 beside it.
`tdigits.load(images=True)` hands over the same images as 1 by 8 by 8 grids instead of rows of 64.
Save as `~/dl/compare.py`:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "\"\"\"compare: lesson 9's dense network, a wider one, and cnn.py, trained the same way on the same digits.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits"
    },
    {
      "code": "def run(name, make, images):\n    torch.manual_seed(0)\n    model = make()\n    train, val, _ = tdigits.load(images=images)\n    print(f\"{name}: {sum(p.numel() for p in model.parameters())} parameters\")\n    loop.fit(model, torch.optim.Adam(model.parameters(), lr=1e-3), train, val, epochs=30, every=10)\n    return model",
      "note": "One recipe for all three: the same seed before the weights are made, the same split, Adam at 0.001, batches of 32, 30 epochs. `images` says whether the digits arrive as rows of 64 or as 1 by 8 by 8 grids."
    },
    {
      "code": "run(\"dense, lesson 9\", lambda: nn.Sequential(nn.Linear(64, 64), nn.ReLU(), nn.Linear(64, 10)), False)\nrun(\"dense, 512 wide\", lambda: nn.Sequential(nn.Linear(64, 512), nn.ReLU(), nn.Linear(512, 10)), False)",
      "note": "Lesson 9's network as it was, and the same shape with 512 hidden units instead of 64, which gives it about as many parameters as the convolutional network."
    },
    {
      "code": "net = run(\"convolutional\", cnn.make_cnn, True)\nprint(sum(p.numel() for p in net[:4].parameters()), \"of them in the two convolutions\")\ntorch.save(net.state_dict(), \"cnn.pt\")",
      "note": "`net[:4]` is the first four layers, the two convolutions and their ReLUs. The trained weights are saved for the last section."
    }
  ]
}
```

```
ana@vm:~/dl$ python compare.py
dense: 4810 parameters
epoch  10  train loss 0.3627  val loss 0.3510  val acc 0.922
epoch  20  train loss 0.1724  val loss 0.1889  val acc 0.944
epoch  30  train loss 0.1177  val loss 0.1471  val acc 0.953
convolutional: 38282 parameters, 4800 of them in the two convolutions
epoch  10  train loss 0.0985  val loss 0.1518  val acc 0.953
epoch  20  train loss 0.0180  val loss 0.0757  val acc 0.978
epoch  30  train loss 0.0070  val loss 0.0633  val acc 0.983
```

**Against lesson 9's network the convolutional one wins clearly**: 0.983 on the validation set
against 0.953, and it was already at 0.953 by epoch 10. But it has 38,282 parameters to the dense
network's 4,810, and that difference alone could explain the result.

**The wider dense network answers that, and it takes most of the gap away.** With 38,410 parameters, about
the same budget, it reaches 0.978. On these digits most of the three points came from size, and what
is left for the convolution is half a point, from one run each. Its validation loss is still the
lowest of the three, 0.0633 against 0.0742, so the convolutional network is also the more confident
when it is right; but a gap that small is within what another seed could move, and lesson 18 is
about telling the two apart.

The reason is the size of the image. **An 8 by 8 digit is 64 pixels, few enough for a dense layer to
afford a weight from each of them to each unit**, and the shapes it has to learn have only a few
places to sit. The section on channels showed where that stops: on a 224 by 224 photograph the dense
layer costs 120,847,089,664 parameters and the convolution 448. Convolution earns its place as images
grow, which is why the networks of lesson 12 are convolutional, and here it already does as well as a
dense network of its size with only 4,800 parameters in the part that looks at the image.

One more thing to notice in the transcript: the convolutional network's training loss fell to 0.0070,
far below its validation loss. It has nearly memorised the 1,077 training images, which is lesson 7's
subject.
