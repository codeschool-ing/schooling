---
title: Batch size, compared fairly
version: 1
---

A larger batch gives a better estimate of the gradient, as lesson 5 measured, so it is easy to
expect a larger batch to train better. **Whether it does depends on what is held equal**: the
number of epochs, or the number of steps. The two comparisons give opposite answers, and both are
true.

Save this as `~/dl/batchsize.py`. It trains the same network from the same starting weights at
batch sizes of 1, 32 and 1,077, the whole training set at once, with the rate fixed at 0.1:

```schooling-example
{
  "language": "python",
  "file": "batchsize.py",
  "parts": [
    {
      "code": "\"\"\"batchsize: one network trained at three batch sizes, for equal epochs or for equal steps.\"\"\"\nimport math\nimport sys\n\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nPLANS = {\"epochs\": [(1, 10), (32, 10), (1077, 10)],\n         \"steps\": [(1, 1), (32, 32), (1077, 1077)]}",
      "note": "Two plans, chosen on the command line. `epochs` gives every batch size ten passes over the data. `steps` gives each about 1,077 updates, which takes one epoch at a batch of 1 and 1,077 epochs at a batch of 1,077."
    },
    {
      "code": "for batch, epochs in PLANS[sys.argv[1]]:\n    rng = np.random.default_rng(0)\n    net = Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))\n    history = fit(net, SGD(net.params(), 0.1), train, val, epochs, batch_size=batch, every=epochs + 1)",
      "note": "The same starting weights and the same rate, 0.1, in every run, so the batch size is the only thing that changes. `every=epochs + 1` keeps `fit` quiet."
    },
    {
      "code": "    steps = epochs * math.ceil(len(train[1]) / batch)\n    val_losses = [h[2] for h in history]\n    rises = sum(later > earlier for earlier, later in zip(val_losses, val_losses[1:]))\n    _, _, val_loss, val_acc = history[-1]\n    print(f\"batch {batch:4d}  {epochs:4d} epochs  {steps:5d} steps  {epochs * len(train[1]):7d} images  \"\n          f\"val loss {val_loss:.4f}  val acc {val_acc:.3f}  val loss rose {rises}/{epochs - 1}\")",
      "note": "Two counts beside the result. `images` is how many images went through a forward and a backward pass, which is the work. `rose` counts the epochs whose validation loss came out higher than the epoch before, a rough measure of how noisy the curve is."
    }
  ]
}
```

## Equal epochs

```
PENDING by-epochs
```

Every run processed the same 10,770 images. **Per epoch, the small batch wins by a distance**:
0.969 at a batch of 1, 0.933 at 32, and 0.436 at 1,077. The reason is in the steps column. Ten
epochs at a batch of 1 are 10,770 updates of the weights; at 1,077 they are 10, and ten steps at a
rate of 0.1 is not enough to get anywhere, however good each gradient is.

## Equal steps

```
PENDING by-steps
```

Now every run moved the weights about 1,077 times, and **per step the large batch wins**: 0.967 at
1,077 against 0.958 at 32 and 0.936 at 1. Each step of the full batch followed the true gradient of
the whole training set, and each step of the batch of 1 followed one image's opinion of it. The
price is in the images column: **the full batch did 1,077 times the work of the batch of 1**, over a
million images through the network to beat it by three points.

So neither size wins both comparisons. A small batch extracts more from each image, a large batch
more from each step, and the useful question is which one a step costs. On real hardware a batch is
one matrix product, as lesson 1 showed, and a processor or a graphics card works through 32 rows in
far less than 32 times the time of one. That is why nobody trains at a batch of 1, and why the
batch is usually set by the memory of the device rather than by the learning. Lessons 10 and 19
measure the time on this machine. This section counts images rather than seconds because a count
comes out the same on every computer.

## The noise you can see

The last column counts how often the validation loss went up from one epoch to the next. At a batch
of 1 it rose in **4 of 9** epochs, at 32 in 1 of 9, and at the full batch in none: and over the 1,077
epochs of the full-batch run it rose **0 times in 1,076**. With the whole training set in every
step, gradient descent at a small rate goes downhill every time and the curve is smooth. With one
image per step, every step is aimed a little wrong and the curve is jagged.

**A jagged curve is not a broken one.** At a batch of 1 the wobbles came with the best result of
the equal-epoch table. When the curve of a real run is noisy, the batch size is one of the first
things to look at, before concluding that training is unstable.
