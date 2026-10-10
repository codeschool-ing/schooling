---
title: Determinism, and where it ends
version: 1
---

Seed 0 twice gave the same network to the last bit. That held on one machine, with one set of
libraries, and with one number of threads, and **each of those is a condition, not a guarantee.**
The reason is arithmetic every program here relies on without saying so.

## Addition depends on the order

Floating-point addition rounds after every step, so the grouping of a sum changes its result.
Save as `~/dl/order.py`:

```schooling-example
{
  "language": "python",
  "file": "order.py",
  "parts": [
    {
      "code": "\"\"\"order: the same numbers, added in a different order.\"\"\"\nimport torch\n\nprint((0.1 + 0.2) + 0.3, 0.1 + (0.2 + 0.3))",
      "note": "Three numbers, two groupings. In exact arithmetic they are equal; in floating point each addition rounds, and the roundings differ."
    },
    {
      "code": "x = torch.randn(1_000_000, generator=torch.Generator().manual_seed(0))\nfor n in (1, 2, 4):\n    torch.set_num_threads(n)\n    print(f\"{n} thread(s): sum {x.sum().item()!r}\")",
      "note": "One million numbers, fixed by a seed, summed with one, two and four threads. More threads means the sum is cut into more pieces that are added up separately and then combined."
    }
  ]
}
```

```
PENDING order
```

`0.6000000000000001` against `0.6` is the whole story in one line. The million numbers then gave a
different sum on four threads from the one on one or two, differing in the fourth decimal of a
number around -1561. **Each thread adds its share, and the shares are combined afterwards**, so the
number of threads decides the grouping. Neither answer is wrong; they are two roundings of the same
exact sum.

## And training?

Save as `~/dl/threads.py`:

```schooling-example
{
  "language": "python",
  "file": "threads.py",
  "parts": [
    {
      "code": "\"\"\"threads: one seed, trained on one thread and on four.\"\"\"\nimport torch\n\nimport exp\n\nconfig = {\"hidden\": 32, \"lr\": 0.01, \"epochs\": 10, \"batch_size\": 32}\nmodels = {}\nfor n in (1, 4):\n    torch.set_num_threads(n)\n    models[n], acc = exp.run(config, 0)\n    print(f\"{n} thread(s): val acc {acc:.4f}\")",
      "note": "The same configuration and the same seed as `seeds.py`, trained twice. The only thing that changes is how many threads PyTorch may use."
    },
    {
      "code": "gap = max((p - q).abs().max().item()\n          for p, q in zip(models[1].parameters(), models[4].parameters()))\nprint(\"largest difference between the two sets of weights:\", gap)",
      "note": "The largest gap between any weight of one network and the same weight of the other. Zero means identical to the last bit."
    }
  ]
}
```

```
PENDING threads
```

On this network, **one thread and four gave identical weights**, a difference of `0.0`. Its
operations are small, 32 images by 64 inputs at a time, and none of them was grouped differently on
four threads. A wider network on a bigger batch is split, and a last-digit difference in one step
grows over thousands of steps into a different second decimal, which is what lesson 1 said to expect
between two machines. That is why `track.py` records `threads`.

## Asking PyTorch to refuse

`torch.use_deterministic_algorithms(True)` tells PyTorch to use only operations that give the same
result every time, and to raise an error for any operation that has no such version. **On the
processor it changes nothing here**: every operation this course uses already has one. It matters
on a graphics card, where some operations add their pieces in whatever order the hardware finishes
them, and the order differs from run to run even on the same machine.

The settings PyTorch documents for a reproducible run on a graphics card are these. **They were not
run for this course**, which has no card:

```python
import os
os.environ["CUBLAS_WORKSPACE_CONFIG"] = ":4096:8"   # before CUDA is first used

import torch
torch.manual_seed(0)
torch.use_deterministic_algorithms(True)
torch.backends.cudnn.benchmark = False
```

The first line fixes how the matrix library schedules its work. The last stops cuDNN from timing
several algorithms and picking the fastest, which can pick a different one on the next run. The
price is speed: the deterministic version of an operation is often slower, sometimes much slower.

What the settings never deliver is the same numbers on different hardware or different library
versions. Within one machine they make a run repeatable. Across machines, **the spread from the
earlier sections is the honest measure**: a result that only holds on seed 0 of one machine was
never a result.
