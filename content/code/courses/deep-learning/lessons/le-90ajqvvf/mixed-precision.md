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
      "note": "`torch.finfo` describes a floating-point type: its size in bits, the largest number it holds, the smallest it holds at full precision, and `eps`, the gap between 1 and the next number it can represent."
    },
    {
      "code": "    print(f\"{str(dtype):15} {f.bits} bits  largest {f.max:.3g}  smallest {f.tiny:.3g}  \"\n          f\"step after 1: {f.eps:.3g}\")\n    print(f\"{'':15} 1 + 0.001 = {(one + 0.001).item():.6g}   \"\n          f\"70000 -> {torch.tensor(70000.0, dtype=dtype).item():.6g}   \"\n          f\"1e-6 * 1e-3 -> {(torch.tensor(1e-6, dtype=dtype) * 1e-3).item():.3g}\")",
      "note": "Three small tests in each type. A small update to a weight of 1, a value too large for one of the types, and a product as small as the gradients deep in a network can be."
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
      "note": "The loop of lesson 9's `loop.py`, with one change: the forward pass and the loss run inside `torch.autocast`, a fresh one for every batch. Inside it, PyTorch runs the matrix products and convolutions in bfloat16 and keeps the operations that need the range or the precision, such as the softmax inside the loss, in float32. `backward`, `zero_grad` and `step` stay outside."
    },
    {
      "code": "for name, low in ((\"float32\", False), (\"bfloat16\", True)):\n    torch.manual_seed(0)\n    model = cnn.make_cnn()\n    start = time.perf_counter()\n    computed = fit(model, low)\n    seconds = time.perf_counter() - start\n    val_loss, val_acc = loop.evaluate(model, *val)\n    print(f\"{name:8}  {seconds:5.1f} s  val loss {val_loss:.4f}  val acc {val_acc:.3f}  \"\n          f\"weights {next(model.parameters()).dtype}, outputs {computed}\")",
      "note": "The same seed, the same network and ten epochs each way. Both are then evaluated in float32 with lesson 9's `evaluate`, so the comparison is between the weights the two trainings produced. The line also says what type the weights were kept in and what type the network's outputs came out in."
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
      "note": "Lesson 9's MLP and recipe, and a copy of the first layer's weights before training, to see afterwards whether they moved."
    },
    {
      "code": "with torch.autocast(\"cpu\", dtype=torch.bfloat16):\n    loop.fit(model, opt, train, val, epochs=3)\nprint(f\"largest change in a first-layer weight: {(model[0].weight - before).abs().max().item():.4f}\")",
      "note": "The tempting shortcut: one `autocast` around all of `loop.fit`, so that nothing inside the loop has to change."
    }
  ]
}
```
