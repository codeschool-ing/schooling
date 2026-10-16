---
title: dataloader
version: 1
---

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
