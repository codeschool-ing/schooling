---
title: Moving the model and the batches to the device
version: 1
---

On a machine with a graphics card, the model's weights and every batch have to be in the card's
memory before the card can compute with them. **The pattern is the same in nearly every training
program**: choose the device once, move the model once, and move each batch as it arrives. Save
this as `~/dl/todevice.py`; it trains lesson 9's MLP for one epoch and runs on this machine, where
the device is the processor:

```schooling-example
{
  "language": "python",
  "file": "todevice.py",
  "parts": [
    {
      "code": "\"\"\"todevice: the device pattern of a training program, run on a machine with no graphics card.\"\"\"\nimport torch\nimport torch.nn.functional as F\nfrom torch.utils.data import DataLoader\n\nfrom dset import Digits\nfrom mlp import make_mlp\n\ndevice = torch.device(\"cuda\" if torch.cuda.is_available() else \"cpu\")\ntorch.manual_seed(0)\nmodel = make_mlp().to(device)\nopt = torch.optim.SGD(model.parameters(), lr=0.1)\nloader = DataLoader(Digits(\"train\"), batch_size=32, shuffle=True,\n                    pin_memory=device.type == \"cuda\")",
      "note": "The device is chosen once, at the top. The model moves before the optimiser is made, so the optimiser holds the parameters where they will live. Pinned memory is asked for only when there is a card to copy to."
    },
    {
      "code": "for xb, yb in loader:\n    xb, yb = xb.to(device, non_blocking=True), yb.to(device, non_blocking=True)\n    loss = F.cross_entropy(model(xb), yb)\n    opt.zero_grad()\n    loss.backward()\n    opt.step()\nprint(\"device:\", device, \" batch on\", xb.device, \" pinned:\", xb.is_pinned(),\n      \" model on\", next(model.parameters()).device, \" last loss %.4f\" % loss.item())",
      "note": "Each batch is moved as it arrives, and the result is assigned back. `non_blocking=True` lets a copy from pinned memory to the card run while the processor goes on to the next line; on the processor it changes nothing."
    },
    {
      "code": "x = torch.zeros(3)\nx.to(torch.float64)\nprint(\"tensor after x.to(float64), result not kept:\", x.dtype)\nlayer = torch.nn.Linear(3, 2)\nlayer.to(torch.float64)\nprint(\"module after layer.to(float64), result not kept:\", layer.weight.dtype)",
      "note": "`.to` behaves differently on the two things it is called on. A dtype stands in for a device here, because this machine has only one device and the rule is the same."
    }
  ]
}
```

```
PENDING todevice
```

## The model once, the batches every time

**`.to` on a module moves the module itself**; `.to` on a tensor returns a new tensor and leaves the
original where it was. The last two lines show the difference with a dtype standing in for a
device: the tensor is still `float32` after `x.to(float64)`, and the layer became `float64`. So
`model.to(device)` on a line of its own works, and `xb.to(device)` on a line of its own does
nothing that lasts. On a card, the next line then hands the model a batch that is still in the
processor's memory, and PyTorch stops with an error naming two devices.

The model is moved before the optimiser is made. PyTorch's documentation of `Module.cuda` asks for
that order: it warns that the move makes the parameters different objects, and an optimiser made
first would be holding the old ones.

## Pinned memory and non_blocking

A copy from the processor's memory to the card goes fastest from **pinned** memory: pages the
operating system has promised not to move, which the card can read directly. `pin_memory=True`
makes the loader put each batch there. On this machine there is no card to copy to, and PyTorch
says so:

```
PENDING pinned
```

The warning and `pinned: False` are the whole effect. That is why `todevice.py` asks for pinning
with `pin_memory=device.type == "cuda"`, which is `False` here and `True` on a card.

`non_blocking=True` lets the processor start the copy and go on to the next line without waiting
for it to finish. That is safe because the card runs the work it is given in order: the forward
pass is queued behind the copy and reads a complete batch. **The processor uses the time it saved
to ask the loader for the next batch**, which is the same overlap the workers bought, one level
down. On the processor, both arguments change nothing, and the run above trained as it would have
without them.

## What changes on a card

Nothing in the program. With a card and its driver, `torch.cuda.is_available()` answers `True`,
the device becomes `cuda`, the model's 2,410 parameters go to the card's memory, pinning is asked
for, and every batch is copied as it arrives. That run was not done for this course, which has no
card; the program is written so that the same file runs on both.
