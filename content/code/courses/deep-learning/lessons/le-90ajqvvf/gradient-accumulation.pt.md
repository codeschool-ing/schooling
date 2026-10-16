---
title: stub
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "accumulate.py",
  "parts": [
    {
      "code": "\"\"\"accumulate: one batch of 128, or four of 32 whose gradients add up before the step.\"\"\"\nimport torch\nimport torch.nn.functional as F\n\nimport cnn\nimport tdigits\n\n(x, y), _, _ = tdigits.load(images=True)\nxb, yb = x[:128], y[:128]\n\n\ndef grads(model):\n    return torch.cat([p.grad.flatten() for p in model.parameters()])",
      "note": "`grads` estende o `.grad` de cada parâmetro num único vetor comprido, para que dois gradientes possam ser comparados com uma subtração."
    },
    {
      "code": "torch.manual_seed(0)\nmodel = cnn.make_cnn()\nopt = torch.optim.SGD(model.parameters(), lr=0.1)\n\nopt.zero_grad()\nF.cross_entropy(model(xb), yb).backward()\none = grads(model)",
      "note": "A referência: uma passada para trás sobre um lote de 128 imagens."
    },
    {
      "code": "opt.zero_grad()\nfor i in range(4):\n    part = slice(32 * i, 32 * (i + 1))\n    loss = F.cross_entropy(model(xb[part]), yb[part]) / 4\n    loss.backward()\nfour = grads(model)",
      "note": "As mesmas 128 imagens em quatro lotes de 32, sem `zero_grad` entre eles, então cada `backward` soma em `.grad`, o comportamento que a aula 9 chamou de bug. Cada perda é dividida por 4: `cross_entropy` devolve a média do lote, e quatro médias de 32 somam quatro vezes a média de 128. Num laço de treino, `opt.step()` e `opt.zero_grad()` viriam aqui, depois do quarto lote."
    },
    {
      "code": "print(f\"{one.numel()} gradient entries, the largest {one.abs().max().item():.6f}\")\nprint(f\"largest difference, one batch of 128 against four of 32: {(one - four).abs().max().item():.2e}\")\nprint(\"equal to float32 rounding:\", torch.allclose(one, four, atol=1e-6))\n\nopt.zero_grad()\nfor i in range(4):\n    part = slice(32 * i, 32 * (i + 1))\n    F.cross_entropy(model(xb[part]), yb[part]).backward()\nprint(f\"without the / 4: {(grads(model).norm() / one.norm()).item():.4f} times the gradient\")",
      "note": "A comparação, e depois o mesmo acúmulo sem a divisão."
    }
  ]
}
```
