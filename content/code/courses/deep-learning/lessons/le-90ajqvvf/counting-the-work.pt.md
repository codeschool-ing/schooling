---
title: stub
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "work.py",
  "parts": [
    {
      "code": "\"\"\"work: parameters, arithmetic per example, and time, for lesson 9's MLP and lesson 11's CNN.\"\"\"\nimport time\n\nimport torch\nimport torch.nn.functional as F\nfrom torch.utils.flop_counter import FlopCounterMode\n\nimport cnn\nimport tdigits\nfrom mlp import make_mlp",
      "note": "`FlopCounterMode` é o contador do próprio PyTorch: enquanto está ativo, ele soma as operações de ponto flutuante de cada produto de matrizes e cada convolução que rodam. Ele conta uma multiplicação e uma adição como duas."
    },
    {
      "code": "def flops(step):\n    \"\"\"Floating-point operations PyTorch counts while `step` runs.\"\"\"\n    with FlopCounterMode(display=False) as counter:\n        step()\n    return counter.get_total_flops()\n\n\ndef ms_per_batch(model, x, y, repeat=20):\n    \"\"\"The fastest of `repeat` training steps on one batch, in milliseconds.\"\"\"\n    best = float(\"inf\")\n    for _ in range(repeat):\n        start = time.perf_counter()\n        F.cross_entropy(model(x), y).backward()\n        best = min(best, time.perf_counter() - start)\n    return best * 1000",
      "note": "A mais rápida de vinte execuções, porque qualquer outra coisa rodando na máquina só pode deixar um passo mais lento, nunca mais rápido. Um passo aqui é a passada para a frente, a perda e a passada para trás; a atualização do otimizador fica de fora, porque é uma subtração por parâmetro."
    },
    {
      "code": "measured = {}\nfor name, make, images in ((\"MLP\", make_mlp, False), (\"CNN\", cnn.make_cnn, True)):\n    torch.manual_seed(0)\n    model = make()\n    (x, y), _, _ = tdigits.load(images=images)\n    xb, yb = x[:32], y[:32]\n    n = sum(p.numel() for p in model.parameters())\n    forward = flops(lambda: model(xb)) / 32\n    train = flops(lambda: F.cross_entropy(model(xb), yb).backward()) / 32\n    ms = ms_per_batch(model, xb, yb)\n    print(f\"{name}: {n} parameters\")\n    print(f\"  forward {forward:,.0f} FLOPs per example, {forward / n:.1f} per parameter\")\n    print(f\"  training step {train:,.0f} per example, {train / forward:.2f} times the forward, {train / n:.1f} per parameter\")\n    print(f\"  30 epochs of 1,077 images: {30 * 1077 * train / 1e9:.2f} GFLOPs\")\n    print(f\"  {ms:.2f} ms per batch of 32, {32 * train / ms / 1e6:.2f} GFLOP/s\")\n    measured[name] = (train, ms)\n\n(mlp_flops, mlp_ms), (cnn_flops, cnn_ms) = measured[\"MLP\"], measured[\"CNN\"]\nprint(f\"CNN against MLP: {cnn_flops / mlp_flops:.0f} times the arithmetic, {cnn_ms / mlp_ms:.1f} times the time\")",
      "note": "As duas redes recebem o mesmo lote de 32 dígitos, achatado para o MLP e como grades de 1 por 8 por 8 para a CNN. Cada contagem é dividida por 32 para dar um custo por exemplo. As duas últimas linhas dividem a aritmética e o tempo da CNN pelos do MLP."
    }
  ]
}
```
