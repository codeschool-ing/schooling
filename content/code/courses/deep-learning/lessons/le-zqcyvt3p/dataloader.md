---
title: The DataLoader: batches, shuffling and collate
version: 1
---

A `DataLoader` takes a dataset and turns it into something a `for` loop can walk through, one batch
at a time. **Everything `fit` did with `randperm` and slicing in lesson 9 is now its job**: picking
the order, cutting it into batches, asking the dataset for each item, and stacking the items into
tensors. Save this as `~/dl/batches.py`:

```schooling-example
{
  "language": "python",
  "file": "batches.py",
  "parts": [
    {
      "code": "\"\"\"batches: what a DataLoader hands out, how many times, and in what order.\"\"\"\nimport torch\nfrom torch.utils.data import DataLoader, default_collate\n\nfrom dset import Digits\n\ntrain = Digits(\"train\")\nloader = DataLoader(train, batch_size=32, shuffle=True)\nxb, yb = next(iter(loader))\nprint(\"one batch:\", tuple(xb.shape), tuple(yb.shape), \" first labels:\", yb[:6].tolist())",
      "note": "A `DataLoader` wraps a dataset and is iterated like a list of batches. `iter` starts an epoch and `next` takes its first batch: 32 images stacked into one tensor, and 32 labels."
    },
    {
      "code": "sizes = [len(yb) for _, yb in loader]\nprint(\"batches:\", len(loader), \" first\", sizes[0], \" last\", sizes[-1], \" images:\", sum(sizes))\nprint(\"with drop_last:\", len(DataLoader(train, batch_size=32, drop_last=True)), \"batches\")",
      "note": "A whole epoch, counted. `len(loader)` is the number of batches, and `drop_last=True` throws away the short batch at the end."
    },
    {
      "code": "xb, yb = default_collate([train[0], train[1], train[2]])\nprint(\"collate of 3 items:\", tuple(xb.shape), yb.tolist())",
      "note": "`default_collate` is the function that turns a list of items into a batch. The loader calls it for every batch; here it is called by hand on three items."
    },
    {
      "code": "for seed in (0, 0, 1):\n    loader = DataLoader(train, batch_size=32, shuffle=True, generator=torch.Generator().manual_seed(seed))\n    first, second = [next(iter(loader))[1][:6].tolist() for epoch in range(2)]\n    print(f\"seed {seed}: epoch 1 starts {first}, epoch 2 starts {second}\")",
      "note": "Each new `iter` is a new epoch with a new shuffle. A generator with a fixed seed makes the sequence of shuffles the same from one run to the next."
    }
  ]
}
```

```
ana@vm:~/dl$ python batches.py
one batch: (32, 64) (32,)  first labels: [2, 4, 8, 4, 0, 5]
batches: 34  first 32  last 21  images: 1077
with drop_last: 33 batches
collate of 3 items: (3, 64) [6, 6, 6]
seed 0: epoch 1 starts [6, 3, 2, 1, 4, 9], epoch 2 starts [7, 6, 4, 2, 6, 3]
seed 0: epoch 1 starts [6, 3, 2, 1, 4, 9], epoch 2 starts [7, 6, 4, 2, 6, 3]
seed 1: epoch 1 starts [4, 3, 6, 2, 2, 5], epoch 2 starts [0, 7, 2, 4, 9, 2]
```

## Batches, and the short one at the end

**A batch is 32 items stacked along a new first dimension**: `(32, 64)` images and `(32,)` labels,
the shapes `fit` used to cut by hand. One epoch is 34 batches, 33 of 32 images and a last one of
21, which adds back up to 1,077. `drop_last=True` throws the short batch away and leaves 33.

The short batch is harmless for the digits, since the loss is a mean over whatever the batch
holds. `drop_last` matters where a layer needs a full batch, or where a batch of one would break
something, as batch normalisation from lesson 8 does when it has a single example to average over.
With `shuffle=True` the images it drops are different in each epoch.

## Collate

The loader asks the dataset for 32 items one by one, gets a list of 32 `(image, label)` pairs, and
hands the list to a **collate function**. The default, `default_collate`, stacks the images into
one tensor and the labels into another, which is what the three-item call printed: `(3, 64)` and
three labels. It only works when every item has the same shape. Photographs of different sizes,
or sentences of different lengths, need a `collate_fn` of your own that pads or crops them to one
size before stacking.

## Order

Each new `iter(loader)` is a new epoch with a new shuffle: epoch 2 starts with other labels than
epoch 1. **A generator with a fixed seed makes the sequence of shuffles repeat** from one run to
the next, as the two `seed 0` lines show, and a different seed gives a different sequence. That is
the same job lesson 9's `fit` gave its own generator.

## Lesson 9's run, with a loader

The training loop barely changes. Save as `~/dl/ltrain.py`; it uses `mlp.py` and `loop.py` from
lesson 9:

```schooling-example
{
  "language": "python",
  "file": "ltrain.py",
  "parts": [
    {
      "code": "\"\"\"ltrain: lesson 9's training run again, with a DataLoader doing the batching.\"\"\"\nimport torch\nimport torch.nn.functional as F\nfrom torch.utils.data import DataLoader\n\nimport loop\nimport tdigits\nfrom dset import Digits\nfrom mlp import make_mlp\n\ntorch.manual_seed(0)\n_, val, _ = tdigits.load()\nloader = DataLoader(Digits(\"train\"), batch_size=32, shuffle=True,\n                    generator=torch.Generator().manual_seed(0))\nmodel = make_mlp()\nopt = torch.optim.SGD(model.parameters(), lr=0.1)",
      "note": "The same network, rate and batch size as lesson 9's `train.py`, with `mlp.py` and `loop.py` from that lesson. Only the batching moves into the loader."
    },
    {
      "code": "for epoch in range(1, 31):\n    for xb, yb in loader:\n        loss = F.cross_entropy(model(xb), yb)\n        opt.zero_grad()\n        loss.backward()\n        opt.step()\n    if epoch % 5 == 0:\n        print(f\"epoch {epoch:3d}  val loss %.4f  val acc %.3f\" % loop.evaluate(model, *val))",
      "note": "The `for` over the loader replaces the `randperm` and the slicing of `loop.fit`. The five lines inside are lesson 9's, unchanged."
    }
  ]
}
```

```
ana@vm:~/dl$ python ltrain.py
epoch   5  val loss 0.6784  val acc 0.889
epoch  10  val loss 0.3138  val acc 0.922
epoch  15  val loss 0.2261  val acc 0.928
epoch  20  val loss 0.1948  val acc 0.939
epoch  25  val loss 0.1679  val acc 0.950
epoch  30  val loss 0.1464  val acc 0.956
```

**The five lines inside the loop are lesson 9's, untouched**; only where the batches come from has
moved. The run lands at a validation accuracy of 0.956 and a loss of 0.1464, against lesson 9's
0.950 and 0.1461. Close, and not equal, because the loader draws its shuffles from the generator in
its own way, so the same seed gives a different sequence of batches. Both runs are equally
correct. Neither number means more than the other, and lesson 18 measures how far apart two seeds
of one configuration land.
