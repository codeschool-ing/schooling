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
      "note": "Nenhum modelo: este programa mede só o carregador, que é o mínimo que uma época pode durar."
    },
    {
      "code": "if __name__ == \"__main__\":\n    train = Digits(\"train\", transform=Warp())\n    fastest = {}\n    for workers in (0, 2, 4):\n        loader = DataLoader(train, batch_size=32, shuffle=True, num_workers=workers,\n                            persistent_workers=workers > 0)",
      "note": "O `num_workers` é o número de processos extras que leem itens e montam lotes. `persistent_workers=True` os mantém vivos entre épocas; sem isso, eles são iniciados de novo a cada época. A proteção `if __name__` importa onde os workers são iniciados do zero, e não copiados do programa em execução, como no macOS e no Windows."
    },
    {
      "code": "        times = []\n        for epoch in range(3):\n            start = time.perf_counter()\n            for xb, yb in loader:\n                pass\n            times.append(time.perf_counter() - start)\n        fastest[workers] = min(times)\n        print(f\"num_workers={workers}  epochs \" + \"  \".join(f\"{t:.2f} s\" for t in times)\n              + f\"   fastest {fastest[0] / fastest[workers]:.1f}x the speed of 0 workers\")",
      "note": "Três épocas cada, todo lote recebido e jogado fora. A comparação usa a época mais rápida de cada configuração, a menos perturbada pelo que mais a máquina estivesse fazendo."
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
      "note": "Uma transformação que soma ruído sorteado pelo seu próprio gerador do NumPy, criado uma vez no `__init__`. Num processo só, não há nada de errado com ela."
    },
    {
      "code": "def reseed(worker_id):\n    info = get_worker_info()\n    info.dataset.transform.rng = np.random.default_rng(info.seed)",
      "note": "Uma `worker_init_fn` roda uma vez dentro de cada worker quando ele começa. O `get_worker_info()` dá a cópia do dataset daquele worker e uma semente que o PyTorch escolheu para ele, diferente em cada worker."
    },
    {
      "code": "if __name__ == \"__main__\":\n    torch.manual_seed(0)\n    clean = Digits(\"train\")\n    for init in (None, reseed):\n        loader = DataLoader(Digits(\"train\", transform=Jitter()), batch_size=4,\n                            num_workers=2, worker_init_fn=init)\n        batches = iter(loader)\n        first, second = next(batches)[0], next(batches)[0]\n        noise0 = first - clean.x[0:4]\n        noise1 = second - clean.x[4:8]\n        print(f\"worker_init_fn={getattr(init, '__name__', None)}\")\n        print(\"  batch 0, from worker 0, noise begins\", [round(v, 4) for v in noise0[0, :3].tolist()])\n        print(\"  batch 1, from worker 1, noise begins\", [round(v, 4) for v in noise1[0, :3].tolist()])\n        print(\"  the same noise:\", torch.allclose(noise0, noise1, atol=1e-6))",
      "note": "Sem embaralhar, o lote 0 é montado pelo worker 0 e o lote 1 pelo worker 1. Subtrair as imagens limpas deixa o ruído que cada worker somou, comparado com e sem o `reseed`."
    }
  ]
}
```
