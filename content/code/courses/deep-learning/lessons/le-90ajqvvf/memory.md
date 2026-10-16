---
title: What training keeps in memory
version: 1
---

A saved model is its weights and nothing else: lesson 9's `mlp.pt` held 2,410 numbers. So it is easy to
think that training needs about as much memory as the file takes on disk. **Training holds four things,
and the weights are only one of them.**

- The weights, 4 bytes each in float32.
- The gradients, one per weight, the same size again: `backward` fills them and `step` reads them.
- The optimiser's state. Plain SGD keeps none. SGD with momentum keeps one number per weight, and
  Adam keeps two, the running averages of the gradient and of its square that lesson 5 built.
- The activations: what the forward pass saves so that the backward pass can compute its products.
  Lesson 3's backward needed the input of every layer, and so does PyTorch's.

The first three grow with the number of parameters, and with Adam in float32 they come to 16 bytes per
parameter. **The activations grow with the batch**, because every example in it has its own. The program
below counts the four by hand for lesson 11's CNN and then measures them on the tensors PyTorch actually
holds. Save as `~/dl/memory.py`:

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

```
ana@vm:~/dl$ python memory.py
38282 parameters, 4 bytes each in float32
by hand:  weights 153,128  gradients 153,128  Adam's two buffers 306,256  bytes
by hand:  activations 18,992 bytes per example
batch   32: activations kept for backward 607,748 bytes, 18,992 per example
batch 1077: activations kept for backward 20,454,388 bytes, 18,992 per example
measured: weights 153,128  gradients 153,128  Adam's two buffers 306,256  bytes
a model of 7 billion parameters, by the same rule: 112 GB before one activation
```

**The count by hand and the measurement agree to the byte**: 153,128 bytes of weights, as many of
gradients, and 306,256 of Adam's buffers. The activations come to 18,992 bytes per example at both batch
sizes, which is the hand count exactly.

At a batch of 32 the activations take nearly as much as the weights, gradients and buffers together. At
a batch of 1,077 they take 20,454,388 bytes, against 153,128 for the weights. **For a network this small,
the memory of training is the batch.** For a large one the parameters weigh as much: the last line
applies the 16 bytes per parameter to a model of 7 billion and gets 112 GB before a single activation. A
model of that size is trained on several cards at once, with its weights, gradients and optimiser state
split between them.

## Making it fit

Four remedies are in common use, and the next two sections run two of them.

- Fewer bytes per number. The next section stores the activations of the forward pass in 16 bits
  instead of 32.
- A smaller batch that still behaves like a large one, by adding up the gradients of several small
  batches before a step: the section after it.
- Recomputing instead of keeping. `torch.utils.checkpoint` throws away the activations inside a
  block of layers and runs that block forward again during the backward pass. It trades extra arithmetic
  for memory. It was not run here, because nothing in this course is short of memory.
- A lighter optimiser. SGD with momentum keeps half of Adam's state; lesson 5 compared what each
  one does to the training.

On a graphics card the memory is the card's own, separate from the computer's, and it is the limit that
decides the batch size. PyTorch reports what it used at the peak. These lines need an NVIDIA card and
were not run for this course:

```python
torch.cuda.reset_peak_memory_stats()
# ... one training step, with the model and the batch on "cuda" ...
print(torch.cuda.max_memory_allocated() / 2**20, "MiB at the peak")
```

`nvidia-smi`, run in a terminal on such a machine, shows the same memory from outside the program, for
every process using the card.
