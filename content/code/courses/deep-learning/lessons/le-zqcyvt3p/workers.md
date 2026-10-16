---
title: Workers, and reading in parallel
version: 1
---

With the default `num_workers=0`, the loader builds every batch in the training program's own
process: the program asks for a batch, waits while 32 images are warped one after another, and only
then gets on with the step. **`num_workers=n` starts n extra processes that build batches on their
own**, each a whole batch at a time, and send them back to the main process. While the model works
on one batch, the workers are already warping the next ones.

How many workers make sense depends on how many processors there are. The lab has four:

```
ana@vm:~/dl$ nproc
4
```

Save this as `~/dl/workers.py`. It reads the warped training set three times with each setting and
trains nothing, so what it measures is the loader alone:

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

```
ana@vm:~/dl$ python workers.py
num_workers=0  epochs 2.06 s  2.10 s  1.97 s   fastest 1.0x the speed of 0 workers
num_workers=2  epochs 1.14 s  1.01 s  1.02 s   fastest 2.0x the speed of 0 workers
num_workers=4  epochs 0.64 s  0.59 s  0.56 s   fastest 3.5x the speed of 0 workers
```

**Two workers read an epoch 2.0 times as fast as none, and four workers 3.5 times**: from 1.97
seconds at best to 1.01 and to 0.56. Each worker warps its own batches on its own processor, so
the reading divides between them. Four are not quite four times as fast, because the main process
needs some processor time too, to receive the batches, and on a four-processor machine there is no
fifth one to give it. Past the number of free processors, an extra worker only takes turns with the
others. These are this machine's times at the moment of the run; on yours the seconds will differ,
and the shape, more workers faster until the processors run out, is what to expect.

**With workers, the first epoch is the slowest of its row**: 1.14 seconds against 1.01 and 1.02,
and 0.64 against 0.59 and 0.56. It includes starting the processes and handing each a copy of the
dataset. `persistent_workers=True` keeps them alive after that; without it, every epoch would pay
the start-up again, which is a real cost when epochs are short.

**The loader alone is a floor.** A training epoch cannot be shorter than the time it takes to build
its batches, however fast the model is, so this number is the first one to know about any training
setup. And on a machine with no graphics card, workers compete with the model for the same
processors, which the next section measures.

## Each worker is a copy

A worker is a separate process with its own copy of the dataset and of the transform inside it.
PyTorch seeds the random generators it knows about differently in each worker: its own, Python's
`random` module, and NumPy's global one. That is why `Warp`, which draws with `torch.rand`, needed
nothing. **A generator object of your own is a different matter**: it is copied into every worker in
the state it was in, and every worker then draws the same numbers. Save as `~/dl/twins.py`:

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

```
ana@vm:~/dl$ python twins.py
worker_init_fn=None
  batch 0, from worker 0, noise begins [0.0126, -0.0132, 0.064]
  batch 1, from worker 1, noise begins [0.0126, -0.0132, 0.064]
  the same noise: True
worker_init_fn=reseed
  batch 0, from worker 0, noise begins [0.1064, 0.0871, 0.0789]
  batch 1, from worker 1, noise begins [-0.0058, -0.0862, -0.1132]
  the same noise: False
```

Without help, the noise in batch 0 and in batch 1 begins with the same three numbers: two workers,
one sequence of noise, and an augmentation that repeats itself across the batches. Nothing fails
and nothing warns. `reseed`, passed as `worker_init_fn`, gives each worker's copy a generator of its
own from the seed PyTorch chose for that worker, and the two batches part ways.
