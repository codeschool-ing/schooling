---
title: stub
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "memory.py",
  "parts": [
    {
      "code": "\"\"\"memory: what training the CNN holds in memory, counted by hand and then measured.\"\"\"\nimport torch\nimport torch.nn.functional as F\n\nimport cnn\nimport tdigits\n\ntorch.manual_seed(0)\nmodel = cnn.make_cnn()\nopt = torch.optim.Adam(model.parameters(), lr=0.001)\n(x, y), _, _ = tdigits.load(images=True)\nn = sum(p.numel() for p in model.parameters())\nprint(f\"{n} parameters, 4 bytes each in float32\")\nprint(f\"by hand:  weights {4 * n:,}  gradients {4 * n:,}  Adam's two buffers {8 * n:,}  bytes\")\n# What backward needs per image: the input, the outputs of the three ReLUs, the pooled maps,\n# the 10 log-probabilities, all float32; where each maximum came from (int64); the label (int64).\nfloats = 64 + 16 * 8 * 8 + 32 * 8 * 8 + 32 * 4 * 4 + 64 + 10\nprint(f\"by hand:  activations {4 * floats + 8 * 32 * 4 * 4 + 8:,} bytes per example\")",
      "note": "A conta à mão, a partir de dois fatos: um float32 ocupa 4 bytes, e o Adam guarda dois números próprios para cada parâmetro. As ativações saem das formas nos comentários do `cnn.py`: os 64 pixels de entrada, 16 e 32 mapas de 8 por 8 saindo dos dois primeiros ReLUs, 32 de 4 por 4 saindo do pooling, 64 saindo do último ReLU e 10 log-probabilidades da perda. O max pooling também guarda qual dos quatro valores era o maior, como um inteiro de 8 bytes."
    },
    {
      "code": "def nbytes(tensors):\n    return sum(t.numel() * t.element_size() for t in tensors)\n\n\nkept = {}\nown = {p.untyped_storage().data_ptr() for p in model.parameters()}\n\n\ndef keep(t):\n    if t.untyped_storage().data_ptr() not in own:\n        kept[t.untyped_storage().data_ptr()] = t.untyped_storage()\n    return t",
      "note": "O autograd chama `keep` para cada tensor que a passada para a frente guarda para a passada para trás. Ela anota cada bloco de memória uma vez só, porque várias operações podem guardar o mesmo tensor, e pula os pesos, que são contados à parte."
    },
    {
      "code": "for batch in (32, 1077):\n    kept.clear()\n    xb, yb = x[:batch].clone(), y[:batch].clone()\n    with torch.autograd.graph.saved_tensors_hooks(keep, lambda t: t):\n        loss = F.cross_entropy(model(xb), yb)\n    opt.zero_grad()\n    loss.backward()\n    opt.step()\n    held = sum(s.nbytes() for s in kept.values())\n    print(f\"batch {batch:4d}: activations kept for backward {held:,} bytes, {held // batch:,} per example\")",
      "note": "`saved_tensors_hooks` entrega cada tensor guardado para `keep` durante a passada para a frente. O lote é copiado com `clone` para ter memória própria; uma fatia de `x` dividiria a memória das 1.077 imagens e contaria todas. Depois, um passo comum do Adam, que cria os buffers do otimizador."
    },
    {
      "code": "grads = nbytes(p.grad for p in model.parameters())\nbuffers = nbytes(s[k] for s in opt.state.values() for k in (\"exp_avg\", \"exp_avg_sq\"))\nprint(f\"measured: weights {nbytes(model.parameters()):,}  gradients {grads:,}  Adam's two buffers {buffers:,}  bytes\")\nprint(f\"a model of 7 billion parameters, by the same rule: {16 * 7e9 / 1e9:.0f} GB before one activation\")",
      "note": "`exp_avg` e `exp_avg_sq` são os nomes que o Adam do PyTorch dá às duas médias móveis da aula 5, uma do gradiente e outra do quadrado dele. A última linha aplica os 16 bytes por parâmetro a um modelo do tamanho de um modelo de linguagem pequeno."
    }
  ]
}
```
