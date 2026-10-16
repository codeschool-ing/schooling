---
title: Mixed precision
version: 1
---

Storing a number in 16 bits instead of 32 sounds like halving its accuracy, and halving the accuracy of
every weight sounds like a worse network. **Neither is how it works.** A 16-bit number loses something
specific, which depends on the format, and mixed precision keeps in 32 bits exactly the numbers that
cannot afford the loss.

There are two 16-bit formats in use, and they lose different things. Save as `~/dl/precision.py`:

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

```
PENDING precision
```

**bfloat16 keeps float32's range and gives up precision.** Its largest number is 3.39e+38, as large as
float32's, but the step from 1 to the next number it can hold is 0.00781, so 1 + 0.001 comes back as 1.
A weight of 1 that receives an update of 0.001 does not move at all. That is why the weights themselves
stay in float32, and only the arithmetic of the forward and backward passes runs in 16 bits.

**float16 keeps more precision and gives up range.** It rounds 1 + 0.001 to 1.00098, but its largest
number is 6.55e+04, so 70000 becomes `inf`, and 1e-6 × 1e-3 becomes 0. Gradients deep in a network can be
that small, and in float16 they vanish. The cure is a scaler, shown at the end of this section.

## bfloat16 on the processor

`torch.autocast` decides, operation by operation, which runs in 16 bits: matrix products and
convolutions do, and operations that need the range or the precision, the softmax and the logarithm in
the loss among them, stay in float32. The program below trains lesson 11's CNN for ten epochs both ways.
Save as `~/dl/mixed.py`:

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

```
PENDING mixed
```

**The accuracy is the same, 0.969 both ways**, and the validation loss moved in the third decimal,
from 0.1291 to 0.1322. The weights stayed `torch.float32` in both runs, while the network's outputs came
out in `torch.bfloat16` under autocast. The seconds were measured while other programs shared the
processors, so read them as an ordering: TIMESENTENCE

On a graphics card the answer is different, and it is the reason mixed precision exists. Recent NVIDIA
cards have units that multiply 16-bit matrices several times faster than 32-bit ones, and every number
in 16 bits is half the bytes to move between the card's memory and those units. A large model trained in
float32 on such a card leaves most of that speed unused. That was not run for this course.

## The trap: autocast around the whole loop

It is tempting to wrap one `autocast` around the existing training loop, so that `loop.py` does not
have to change. Save as `~/dl/trap.py`:

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

```
PENDING trap
```

**The training loss is 2.3230 in all three epochs, to the fourth decimal**, and the accuracy stays at
0.039, while the last line shows the weights did move. The network learnt nothing that its forward pass
could see. Autocast keeps the 16-bit copy it makes of each weight for as long as its block lasts, so that
a weight used twice is converted once. Around the whole loop the block never ends, and every forward pass
for three epochs runs on copies of the initial weights. **Autocast belongs around the forward pass and
the loss of one batch**, as `mixed.py` puts it, so that each batch starts a fresh block.

## float16 on a graphics card, with a scaler

On an NVIDIA card the usual 16-bit format has been float16, which runs fast on older cards that lack
bfloat16. Its small range is handled by a `GradScaler`. It multiplies the loss by a large factor before
`backward`, so that small gradients stay above the point where float16 rounds them to 0, and divides the
gradients by the same factor before the step. If a gradient has overflowed to `inf`, it skips that step
and lowers the factor. This needs an NVIDIA card and was not run for this course:

```python
scaler = torch.amp.GradScaler("cuda")
for x, y in batches:
    x, y = x.to("cuda"), y.to("cuda")
    with torch.autocast("cuda", dtype=torch.float16):
        loss = F.cross_entropy(model(x), y)
    opt.zero_grad()
    scaler.scale(loss).backward()
    scaler.step(opt)
    scaler.update()
```

With bfloat16 the scaler is not needed, because its range is float32's.
