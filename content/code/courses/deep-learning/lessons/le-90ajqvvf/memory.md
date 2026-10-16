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
      "note": "The count by hand, from two facts: a float32 is 4 bytes, and Adam keeps two numbers of its own for every parameter. The activations come from the shapes in `cnn.py`'s comments: the 64 pixels coming in, 16 and 32 maps of 8 by 8 out of the first two ReLUs, 32 of 4 by 4 out of the pooling, 64 out of the last ReLU and 10 log-probabilities from the loss. Max pooling also remembers which of the four values was the largest, as an 8-byte integer."
    },
    {
      "code": "def nbytes(tensors):\n    return sum(t.numel() * t.element_size() for t in tensors)\n\n\nkept = {}\nown = {p.untyped_storage().data_ptr() for p in model.parameters()}\n\n\ndef keep(t):\n    if t.untyped_storage().data_ptr() not in own:\n        kept[t.untyped_storage().data_ptr()] = t.untyped_storage()\n    return t",
      "note": "`keep` is called by autograd for every tensor the forward pass saves for the backward pass. It notes each block of memory once, since several operations can save the same tensor, and it skips the weights, which are counted apart."
    },
    {
      "code": "for batch in (32, 1077):\n    kept.clear()\n    xb, yb = x[:batch].clone(), y[:batch].clone()\n    with torch.autograd.graph.saved_tensors_hooks(keep, lambda t: t):\n        loss = F.cross_entropy(model(xb), yb)\n    opt.zero_grad()\n    loss.backward()\n    opt.step()\n    held = sum(s.nbytes() for s in kept.values())\n    print(f\"batch {batch:4d}: activations kept for backward {held:,} bytes, {held // batch:,} per example\")",
      "note": "`saved_tensors_hooks` hands every saved tensor to `keep` during the forward pass. The batch is copied with `clone` so that it owns its memory; a slice of `x` would share the memory of all 1,077 images and count them all. Then one ordinary Adam step, which creates the optimiser's buffers."
    },
    {
      "code": "grads = nbytes(p.grad for p in model.parameters())\nbuffers = nbytes(s[k] for s in opt.state.values() for k in (\"exp_avg\", \"exp_avg_sq\"))\nprint(f\"measured: weights {nbytes(model.parameters()):,}  gradients {grads:,}  Adam's two buffers {buffers:,}  bytes\")\nprint(f\"a model of 7 billion parameters, by the same rule: {16 * 7e9 / 1e9:.0f} GB before one activation\")",
      "note": "`exp_avg` and `exp_avg_sq` are the names PyTorch's Adam gives the two running averages of lesson 5, one of the gradient and one of its square. The last line applies the 16 bytes per parameter to a model the size of a small language model."
    }
  ]
}
```
