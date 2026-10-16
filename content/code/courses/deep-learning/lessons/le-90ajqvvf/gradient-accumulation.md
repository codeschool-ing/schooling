---
title: Gradient accumulation
version: 1
---

The memory section showed the activations growing with the batch, so the batch is the first thing a
graphics card refuses. Lesson 6 showed that the batch size is not free to change either: the learning
rate and the number of steps were tuned with it. **When a batch does not fit, the gradient of that batch
can still be computed, a piece at a time.**

The gradient of a mean loss over 128 examples is the mean of their gradients. Four batches of 32 hold the
same 128 examples, and `backward` adds into `.grad` rather than replacing it, the behaviour lesson 9's
missing `zero_grad` turned into a bug. Here it is the tool. Save as `~/dl/accumulate.py`:

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

```
PENDING accumulate
```

**The two gradients are the same.** Out of 38,282 entries, the largest difference is 5.12e-09, against a
largest gradient of 0.032093. That is the rounding of float32 adding the same numbers in a different
order, and `allclose` accepts it. Without the division by 4 the gradient comes out 4.0000 times too
large, which is a learning rate four times too high under another name.

In a training loop, the step and `zero_grad` move out of the batch loop and run once every four batches:

```python
for i, (x, y) in enumerate(batches):
    loss = F.cross_entropy(model(x), y) / 4
    loss.backward()
    if (i + 1) % 4 == 0:
        opt.step()
        opt.zero_grad()
```

These lines are the pattern, not a program to run; `accumulate.py` above is their run.

## What it costs, and where it differs

**Accumulation saves memory and nothing else.** The arithmetic is the same as for the batch of 128, and
the time is four batches of 32, which is at least the time of one batch of 128 and usually more, because
each small batch pays the fixed costs of a step on its own. What is saved is the activations: the
backward pass of each piece needs only that piece's 32 examples.

It is exact for `cnn.py`, because nothing in that network looks across the examples of a batch. Lesson
8's batch normalisation does: it normalises with the mean and the variance of the batch it is given, so
four pieces of 32 are normalised with four different statistics, and the gradient is no longer the
gradient of a batch of 128. Layer normalisation, which works inside each example, has no such problem.
