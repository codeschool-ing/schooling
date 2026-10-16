---
title: stub
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "precision.py",
  "parts": [
    {
      "code": "\"\"\"precision: three ways to store a number in 16 or 32 bits, and what each one loses.\"\"\"\nimport torch\n\nfor dtype in (torch.float32, torch.bfloat16, torch.float16):\n    f = torch.finfo(dtype)\n    one = torch.tensor(1.0, dtype=dtype)",
      "note": "`torch.finfo` descreve um tipo de ponto flutuante: o tamanho em bits, o maior número que ele guarda, o menor que guarda com precisão total, e `eps`, a distância entre 1 e o próximo número que ele consegue representar."
    },
    {
      "code": "    print(f\"{str(dtype):15} {f.bits} bits  largest {f.max:.3g}  smallest {f.tiny:.3g}  \"\n          f\"step after 1: {f.eps:.3g}\")\n    print(f\"{'':15} 1 + 0.001 = {(one + 0.001).item():.6g}   \"\n          f\"70000 -> {torch.tensor(70000.0, dtype=dtype).item():.6g}   \"\n          f\"1e-6 * 1e-3 -> {(torch.tensor(1e-6, dtype=dtype) * 1e-3).item():.3g}\")",
      "note": "Três testes pequenos em cada tipo. Uma atualização pequena num peso de 1, um valor grande demais para um dos tipos, e um produto tão pequeno quanto os gradientes no fundo de uma rede podem ser."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "mixed.py",
  "parts": [
    {
      "code": "\"\"\"mixed: lesson 11's CNN trained in float32, then with bfloat16 autocast, on the processor.\"\"\"\nimport time\n\nimport torch\nimport torch.nn.functional as F\n\nimport cnn\nimport loop\nimport tdigits\n\ntrain, val, _ = tdigits.load(images=True)"
    },
    {
      "code": "def fit(model, low, epochs=10, batch_size=32):\n    \"\"\"loop.fit's recipe, with the forward pass and the loss under autocast when `low` is set.\"\"\"\n    x, y = train\n    opt = torch.optim.SGD(model.parameters(), lr=0.1)\n    g = torch.Generator().manual_seed(0)\n    for epoch in range(epochs):\n        order = torch.randperm(len(y), generator=g)\n        for start in range(0, len(y), batch_size):\n            idx = order[start:start + batch_size]\n            with torch.autocast(\"cpu\", dtype=torch.bfloat16, enabled=low):\n                logits = model(x[idx])\n                loss = F.cross_entropy(logits, y[idx])\n            opt.zero_grad()\n            loss.backward()\n            opt.step()\n    return logits.dtype",
      "note": "O laço do `loop.py` da aula 9, com uma mudança: a passada para a frente e a perda rodam dentro de `torch.autocast`, um novo a cada lote. Dentro dele, o PyTorch faz os produtos de matrizes e as convoluções em bfloat16 e mantém em float32 as operações que precisam do alcance ou da precisão, como o softmax dentro da perda. `backward`, `zero_grad` e `step` ficam do lado de fora."
    },
    {
      "code": "for name, low in ((\"float32\", False), (\"bfloat16\", True)):\n    torch.manual_seed(0)\n    model = cnn.make_cnn()\n    start = time.perf_counter()\n    computed = fit(model, low)\n    seconds = time.perf_counter() - start\n    val_loss, val_acc = loop.evaluate(model, *val)\n    print(f\"{name:8}  {seconds:5.1f} s  val loss {val_loss:.4f}  val acc {val_acc:.3f}  \"\n          f\"weights {next(model.parameters()).dtype}, outputs {computed}\")",
      "note": "A mesma semente, a mesma rede e dez épocas em cada modo. As duas são avaliadas depois em float32 com o `evaluate` da aula 9, então a comparação é entre os pesos que os dois treinos produziram. A linha também diz em que tipo os pesos ficaram guardados e em que tipo as saídas da rede saíram."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "trap.py",
  "parts": [
    {
      "code": "\"\"\"trap: autocast wrapped around the whole training loop, on lesson 9's MLP.\"\"\"\nimport torch\n\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\ntrain, val, _ = tdigits.load()\ntorch.manual_seed(0)\nmodel = make_mlp()\nbefore = model[0].weight.detach().clone()\nopt = torch.optim.SGD(model.parameters(), lr=0.1)",
      "note": "O MLP e a receita da aula 9, e uma cópia dos pesos da primeira camada antes do treino, para ver depois se eles se mexeram."
    },
    {
      "code": "with torch.autocast(\"cpu\", dtype=torch.bfloat16):\n    loop.fit(model, opt, train, val, epochs=3)\nprint(f\"largest change in a first-layer weight: {(model[0].weight - before).abs().max().item():.4f}\")",
      "note": "O atalho tentador: um único `autocast` em volta de todo o `loop.fit`, para que nada dentro do laço precise mudar."
    }
  ]
}
```
