---
title: where-the-time-goes
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "waiting.py",
  "parts": [
    {
      "code": "\"\"\"waiting: training on the warped digits, each epoch split into waiting for a batch and computing on it.\"\"\"\nimport time\n\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\nfrom torch.utils.data import DataLoader\n\nfrom dset import Digits\nfrom warp import Warp"
    },
    {
      "code": "def one_epoch(model, opt, loader):\n    wait = compute = 0.0\n    start = time.perf_counter()\n    for xb, yb in loader:\n        got = time.perf_counter()\n        loss = F.cross_entropy(model(xb), yb)\n        opt.zero_grad()\n        loss.backward()\n        opt.step()\n        done = time.perf_counter()\n        wait += got - start\n        compute += done - got\n        start = done\n    return wait, compute",
      "note": "Três relógios por lote. Do fim do último passo até o momento em que o `for` entrega um lote é espera; dali até o fim do `opt.step()` é cálculo. Os dois somados dão a época."
    },
    {
      "code": "if __name__ == \"__main__\":\n    torch.manual_seed(0)\n    train = Digits(\"train\", transform=Warp())\n    for workers in (0, 2):\n        model = nn.Sequential(nn.Flatten(), nn.Linear(1024, 256), nn.ReLU(), nn.Linear(256, 10))\n        opt = torch.optim.SGD(model.parameters(), lr=0.05)\n        loader = DataLoader(train, batch_size=32, shuffle=True, num_workers=workers,\n                            persistent_workers=workers > 0)\n        for e in (1, 2):\n            wait, compute = one_epoch(model, opt, loader)\n            print(f\"workers {workers}  epoch {e}  waiting {wait:.2f} s  computing {compute:.2f} s  \"\n                  f\"waiting share {wait / (wait + compute):.0%}\")",
      "note": "Uma rede densa para as imagens 32x32: o `nn.Flatten` transforma cada imagem 1x32x32 numa linha de 1.024, depois vem uma camada oculta de 256 unidades. Duas épocas sem workers, depois duas com dois workers."
    }
  ]
}
```
