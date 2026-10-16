---
title: workers
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "workers.py",
  "parts": [
    {
      "code": "\"\"\"workers: three epochs of reading the warped digits, with 0, 2 and 4 worker processes.\"\"\"\nimport time\n\nfrom torch.utils.data import DataLoader\n\nfrom dset import Digits\nfrom warp import Warp",
      "note": "No model at all: this program measures the loader alone, which is the shortest an epoch can ever be."
    },
    {
      "code": "if __name__ == \"__main__\":\n    train = Digits(\"train\", transform=Warp())\n    fastest = {}\n    for workers in (0, 2, 4):\n        loader = DataLoader(train, batch_size=32, shuffle=True, num_workers=workers,\n                            persistent_workers=workers > 0)",
      "note": "`num_workers` is the number of extra processes that read items and build batches. `persistent_workers=True` keeps them alive between epochs; without it they are started again at every epoch. The `if __name__` guard matters wherever workers are started fresh rather than copied from the running program, as on macOS and Windows."
    },
    {
      "code": "        times = []\n        for epoch in range(3):\n            start = time.perf_counter()\n            for xb, yb in loader:\n                pass\n            times.append(time.perf_counter() - start)\n        fastest[workers] = min(times)\n        print(f\"num_workers={workers}  epochs \" + \"  \".join(f\"{t:.2f} s\" for t in times)\n              + f\"   fastest {fastest[0] / fastest[workers]:.1f}x the speed of 0 workers\")",
      "note": "Three epochs each, every batch taken and thrown away. The comparison uses each setting's fastest epoch, the one least disturbed by whatever else the machine was doing."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "twins.py",
  "parts": [
    {
      "code": "\"\"\"twins: a transform holding a NumPy generator, read by two workers, before and after reseeding them.\"\"\"\nimport numpy as np\nimport torch\nfrom torch.utils.data import DataLoader, get_worker_info\n\nfrom dset import Digits\n\n\nclass Jitter:\n    def __init__(self):\n        self.rng = np.random.default_rng(0)\n\n    def __call__(self, img):\n        return img + torch.from_numpy(self.rng.normal(0, 0.1, img.shape).astype(np.float32))",
      "note": "A transform that adds noise drawn from its own NumPy generator, created once in `__init__`. Nothing is wrong with it in a single process."
    },
    {
      "code": "def reseed(worker_id):\n    info = get_worker_info()\n    info.dataset.transform.rng = np.random.default_rng(info.seed)",
      "note": "A `worker_init_fn` runs once inside each worker as it starts. `get_worker_info()` gives that worker's copy of the dataset and a seed PyTorch chose for it, different in every worker."
    },
    {
      "code": "if __name__ == \"__main__\":\n    torch.manual_seed(0)\n    clean = Digits(\"train\")\n    for init in (None, reseed):\n        loader = DataLoader(Digits(\"train\", transform=Jitter()), batch_size=4,\n                            num_workers=2, worker_init_fn=init)\n        batches = iter(loader)\n        first, second = next(batches)[0], next(batches)[0]\n        noise0 = first - clean.x[0:4]\n        noise1 = second - clean.x[4:8]\n        print(f\"worker_init_fn={getattr(init, '__name__', None)}\")\n        print(\"  batch 0, from worker 0, noise begins\", [round(v, 4) for v in noise0[0, :3].tolist()])\n        print(\"  batch 1, from worker 1, noise begins\", [round(v, 4) for v in noise1[0, :3].tolist()])\n        print(\"  the same noise:\", torch.allclose(noise0, noise1, atol=1e-6))",
      "note": "Without shuffling, batch 0 is built by worker 0 and batch 1 by worker 1. Subtracting the clean images leaves the noise each worker added, compared with and without `reseed`."
    }
  ]
}
```
