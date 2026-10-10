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

To compare it fairly with lesson 9's dense network, train both in the same way: the same split, the
same seed, Adam at 0.001, batches of 32, 30 epochs. The program needs the `digits.py` from lesson 1
and the `tdigits.py` and `loop.py` from lesson 9 beside it. `tdigits.load(images=True)` hands over
the same images as 1 by 8 by 8 grids instead of rows of 64. Save as `~/dl/compare.py`:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "\"\"\"compare: lesson 9's dense network against cnn.py, trained the same way on the same digits.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n\ndef count(model):\n    return sum(p.numel() for p in model.parameters())"
    },
    {
      "code": "torch.manual_seed(0)\nmlp = nn.Sequential(nn.Linear(64, 64), nn.ReLU(), nn.Linear(64, 10))\ntrain, val, _ = tdigits.load()\nprint(f\"dense: {count(mlp)} parameters\")\nloop.fit(mlp, torch.optim.Adam(mlp.parameters(), lr=1e-3), train, val, epochs=30, every=10)",
      "note": "Lesson 9's network as it was: 64 pixels in a row, 64 hidden units, 10 outputs, Adam at 0.001."
    },
    {
      "code": "torch.manual_seed(0)\nnet = cnn.make_cnn()\ntrain, val, _ = tdigits.load(images=True)\nprint(f\"convolutional: {count(net)} parameters, {count(net[:4])} of them in the two convolutions\")\nloop.fit(net, torch.optim.Adam(net.parameters(), lr=1e-3), train, val, epochs=30, every=10)\ntorch.save(net.state_dict(), \"cnn.pt\")",
      "note": "The same images as 1 by 8 by 8 grids, the same seed, optimiser, rate, batch size and epochs. `net[:4]` is the first four layers, the two convolutions and their ReLUs. The trained weights are saved for the last section."
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

**The convolutional network ends at 0.983 on the validation set, against 0.953 for the dense one**,
and it was already at 0.953 by epoch 10. Its validation loss, 0.0633, is less than half the dense
network's 0.1471.

The parameter counts deserve a careful reading, because the convolutional network has 38,282 and the
dense one 4,810, nearly eight times fewer. **Most of the difference is not in the convolutions.** The
two convolutions hold 4,800 parameters, about the dense network's whole budget; the other 33,482 sit
in the dense layers after `Flatten`, mostly in `Linear(512, 64)`. The gain came from where the
parameters look, not from having more of them.

Two cautions before reading more into it. **This is one seed for each network**, and a gap of three
points between single runs can shrink or grow with another; lesson 18 asks whether a difference is
larger than the spread between seeds. And the convolutional network's training loss fell to 0.0070,
far below its validation loss: it has nearly memorised the 1,077 training images, which is lesson
7's subject.
