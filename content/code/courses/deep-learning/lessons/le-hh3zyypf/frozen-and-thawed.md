---
title: Frozen and thawed, one tensor at a time
version: 1
---

Lesson 13 froze the whole body of `base.pt` and trained a new head on top. **Fine-tuning is the
same start with some of the body allowed to learn as well**, and the decision this lesson is about
is how much. Before any of it is trained, it is worth seeing exactly what "frozen" means in
PyTorch, because two common beliefs about it are wrong.

The first is that `model.eval()` freezes a model. It does not: evaluation mode changes how a few
layers behave, dropout and batch normalisation among them, and has nothing to say about
gradients. The second is that a frozen layer is something the optimiser knows about. It is not:
**freezing is one flag on each parameter tensor, `requires_grad`, and the optimiser only ever sees
the tensors it was handed.** The program below shows both. It needs `base.pt` from lesson 13 in
`~/dl`; if you have deleted it, run lesson 13's `pretrain.py` again, which writes the same file.
Save as `~/dl/freeze.py`:

```schooling-example
{
  "language": "python",
  "file": "freeze.py",
  "parts": [
    {
      "code": "\"\"\"freeze: which parameters of base.pt learn, and how the optimiser is told.\"\"\"\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\n\nimport cnn\nimport tdigits\n\nmodel = cnn.make_cnn(5)\nmodel.load_state_dict(torch.load(\"base.pt\"))\nmodel[8] = nn.Linear(64, 5)\nfor p in model[:6].parameters():\n    p.requires_grad = False",
      "note": "`base.pt` from lesson 13, poured into the `cnn.make_cnn(5)` of lesson 11, with a new head for the digits 5 to 9. `model[:6]` is the first six layers: the two convolutions, their ReLUs, the pooling and the flatten. Only the convolutions hold parameters, and each of their tensors gets the flag."
    },
    {
      "code": "for name, p in model.named_parameters():\n    print(f\"{name:9s} {str(tuple(p.shape)):15s} {p.numel():6d}  requires_grad={p.requires_grad}\")\nprint(\"learns\", sum(p.numel() for p in model.parameters() if p.requires_grad),\n      \"of\", sum(p.numel() for p in model.parameters()))",
      "note": "`named_parameters` gives each tensor with its name, which is the layer's position in the `Sequential` and then `weight` or `bias`. These are the same names `base.pt` stores."
    },
    {
      "code": "(x, y), _, _ = tdigits.load(images=True)\nfive = y >= 5\nmodel.eval()\nloss = F.cross_entropy(model(x[five][:32]), y[five][:32] - 5)\nloss.backward()\nprint(\"gradients after backward, in eval mode:\",\n      [name for name, p in model.named_parameters() if p.grad is not None])",
      "note": "One batch of 32 images of 5 to 9, forward and backward, with the model in evaluation mode on purpose. The list names every tensor that received a gradient."
    },
    {
      "code": "opt = torch.optim.Adam([\n    {\"params\": model[6].parameters(), \"lr\": 1e-4},\n    {\"params\": model[8].parameters(), \"lr\": 1e-3},\n])\nfor i, group in enumerate(opt.param_groups):\n    print(f\"group {i}: {len(group['params'])} tensors, lr {group['lr']}\")\nbefore = [p.clone() for p in model.parameters()]\nopt.step()\nprint(\"changed by one step:\",\n      [not torch.equal(b, p) for b, p in zip(before, model.parameters())])",
      "note": "An optimiser given two parameter groups instead of one list: the 512-to-64 layer at 1e-4 and the new head at 1e-3. The frozen convolutions are in neither. One step, then each of the eight tensors is compared with its copy from before."
    }
  ]
}
```

```
PENDING freeze
```

## Reading the output

**The table is the network as the optimiser could see it.** Every tensor has a name, a shape and a
count, and the four belonging to the convolutions say `requires_grad=False`. Together they hold
4,800 of the 37,957 parameters; the 512-to-64 layer and the new head hold the other 33,157, which
is the line `learns 33157 of 37957`.

**Backward skips a frozen tensor completely.** After one batch the list of tensors with a gradient
names `6.weight`, `6.bias`, `8.weight` and `8.bias`, and nothing else. The convolutions were used
in the forward pass, so the gradient still flowed *through* them on its way back, but nothing was
stored *for* them. That is the whole saving: no gradient for a frozen tensor, and so no memory for
one and nothing for the optimiser to move. The model was in evaluation mode the whole time and the
gradients arrived regardless, which settles the first belief.

**An optimiser can hold several parameter groups, each with its own rate.** Instead of one list,
`torch.optim.Adam` was given two dictionaries, and `param_groups` reports them back: two tensors
at `0.0001` and two at `0.001`. The step then changed exactly those four tensors and left the
first four as `base.pt` had them, which is the last line.

Two habits follow from that, and every program in this lesson keeps them:

- **Give the optimiser only the tensors that learn**, with
  `[p for p in model.parameters() if p.requires_grad]` or explicit groups. Adam would skip a tensor
  whose gradient is `None` anyway, but a list that says what learns is one you can check by
  reading it.
- **Set the flags before building the optimiser**, and replace a layer before setting them: a
  layer created with `nn.Linear` starts with `requires_grad=True`, which is why the new head learns
  without anybody switching it on.

Evaluation mode does matter in one case, and it is the mirror of the first belief. Batch
normalisation, which lesson 8 built, keeps a running mean and variance that are buffers rather
than parameters, and in training mode it updates them whatever `requires_grad` says. **So freezing
a body that contains batch normalisation also means keeping those layers in evaluation mode**, or
the statistics learnt on the old data drift towards the new batches. `cnn.make_cnn` has no such
layer, so nothing in this lesson depends on it, but the ResNet of lesson 12 puts one after every
convolution.
