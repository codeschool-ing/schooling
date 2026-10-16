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
      "note": "`grads` lays the `.grad` of every parameter out in one long vector, so that two gradients can be compared with one subtraction."
    },
    {
      "code": "torch.manual_seed(0)\nmodel = cnn.make_cnn()\nopt = torch.optim.SGD(model.parameters(), lr=0.1)\n\nopt.zero_grad()\nF.cross_entropy(model(xb), yb).backward()\none = grads(model)",
      "note": "The reference: one backward pass over a batch of 128 images."
    },
    {
      "code": "opt.zero_grad()\nfor i in range(4):\n    part = slice(32 * i, 32 * (i + 1))\n    loss = F.cross_entropy(model(xb[part]), yb[part]) / 4\n    loss.backward()\nfour = grads(model)",
      "note": "The same 128 images in four batches of 32, with no `zero_grad` between them, so each `backward` adds into `.grad`, the behaviour lesson 9 called a bug. Each loss is divided by 4: `cross_entropy` returns the mean over its batch, and four means of 32 add up to four times the mean of 128. In a training loop, `opt.step()` and `opt.zero_grad()` would come here, after the fourth batch."
    },
    {
      "code": "print(f\"{one.numel()} gradient entries, the largest {one.abs().max().item():.6f}\")\nprint(f\"largest difference, one batch of 128 against four of 32: {(one - four).abs().max().item():.2e}\")\nprint(\"equal to float32 rounding:\", torch.allclose(one, four, atol=1e-6))\n\nopt.zero_grad()\nfor i in range(4):\n    part = slice(32 * i, 32 * (i + 1))\n    F.cross_entropy(model(xb[part]), yb[part]).backward()\nprint(f\"without the / 4: {(grads(model).norm() / one.norm()).item():.4f} times the gradient\")",
      "note": "The comparison, then the same accumulation with the division left out."
    }
  ]
}
```
