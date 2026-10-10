---
title: The training loop, written once
version: 1
---

Every lesson from here to the end trains through two small modules, the way lessons 5 to 8 trained
through `fit.py`. **They are short on purpose**: a training loop is about twenty lines, and a library
that hides them hides the five that decide whether training works.

The first turns lesson 1's digits into tensors. Save it as `~/dl/tdigits.py`:

```schooling-example
{
  "language": "python",
  "file": "tdigits.py",
  "parts": [
    {
      "code": "\"\"\"tdigits: lesson 1's digits as PyTorch tensors, flat for a dense network or as 1x8x8 images.\"\"\"\nimport torch\n\nimport digits",
      "note": "The digits split by lesson 1's `digits.py`, so the same 1,077, 360 and 360 images, now as tensors."
    },
    {
      "code": "def load(images=False, seed=0):\n    \"\"\"Train, validation and test sets as (inputs, labels) pairs of tensors.\"\"\"\n    sets = []\n    for x, y in digits.load(seed):\n        x = torch.from_numpy(x)\n        if images:\n            x = x.reshape(-1, 1, 8, 8)\n        sets.append((x, torch.from_numpy(y)))\n    return sets",
      "note": "`from_numpy` shares memory with the arrays, so nothing is copied. `images=True` lays each row of 64 out as one channel of 8 by 8, the shape a convolution reads in lesson 11; a dense network takes the flat rows."
    }
  ]
}
```

The second is the loop itself, with an evaluation beside it. Save it as `~/dl/loop.py`:

```schooling-example
{
  "language": "python",
  "file": "loop.py",
  "parts": [
    {
      "code": "\"\"\"loop: the PyTorch training loop every lesson from 9 on runs, written out once.\"\"\"\nimport torch\nimport torch.nn.functional as F",
      "note": "`torch.nn.functional`, imported as `F`, holds the operations that have no weights of their own, the loss among them."
    },
    {
      "code": "def evaluate(model, x, y):\n    \"\"\"Mean loss and accuracy on a whole set, in evaluation mode and without gradients.\"\"\"\n    model.eval()\n    with torch.no_grad():\n        logits = model(x)\n        loss = F.cross_entropy(logits, y).item()\n        acc = (logits.argmax(dim=1) == y).float().mean().item()\n    model.train()\n    return loss, acc",
      "note": "`model.eval()` switches layers that behave differently in training, such as dropout and batch normalisation, to their evaluation behaviour, and `torch.no_grad()` stops the recording. `.item()` turns a one-number tensor into a Python float. The model goes back to training mode before returning."
    },
    {
      "code": "def fit(model, opt, train, val, epochs, batch_size=32, seed=0, every=1):\n    \"\"\"Shuffle, cut into batches, one optimiser step per batch; report every `every` epochs.\"\"\"\n    x, y = train\n    g = torch.Generator().manual_seed(seed)\n    history = []\n    model.train()\n    for epoch in range(1, epochs + 1):\n        order = torch.randperm(len(y), generator=g)\n        total = 0.0\n        for start in range(0, len(y), batch_size):\n            idx = order[start:start + batch_size]\n            loss = F.cross_entropy(model(x[idx]), y[idx])\n            opt.zero_grad()\n            loss.backward()\n            opt.step()\n            total += loss.item() * len(idx)\n        val_loss, val_acc = evaluate(model, *val)\n        history.append((epoch, total / len(y), val_loss, val_acc))\n        if epoch % every == 0:\n            print(f\"epoch {epoch:3d}  train loss {total / len(y):.4f}  \"\n                  f\"val loss {val_loss:.4f}  val acc {val_acc:.3f}\")\n    return history",
      "note": "The same shape as lesson 5's `fit.py`: shuffle with a seeded generator, cut into batches of 32, one step per batch. Inside, the five lines every PyTorch training loop has: forward and loss, `zero_grad` to empty the `.grad` of every parameter, `backward` to fill them, `step` to move the weights. The running total uses `.item()`, so it holds a number and not a tensor with its record attached."
    }
  ]
}
```

## The five lines

Inside the batch loop of `fit` sit the lines that every PyTorch training program has, in some
arrangement:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 210\" role=\"img\" aria-label=\"The five lines of a training step as a cycle, with what each one changes: the forward pass builds the record of operations, the loss reduces the batch to one number, zero_grad empties every parameter&#x27;s .grad, backward fills them from the record, and step moves the weights using .grad. Then the next batch starts again at the forward pass.\"><rect x=\"10\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"71.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">logits = model(x)</text><text x=\"71.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">builds the record</text><path d=\"M132 75 L146 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M138.6 78.1 L146 75 L138.6 71.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"148\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"209.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">F.cross_entropy(…)</text><text x=\"209.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">one number</text><path d=\"M270 75 L284 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M276.6 78.1 L284 75 L276.6 71.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"286\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"347.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">opt.zero_grad()</text><text x=\"347.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">empty every .grad</text><path d=\"M408 75 L422 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M414.6 78.1 L422 75 L414.6 71.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"424\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"485.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">loss.backward()</text><text x=\"485.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">fill every .grad</text><path d=\"M546 75 L560 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M552.6 78.1 L560 75 L552.6 71.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"562\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"623.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">opt.step()</text><text x=\"623.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">move the weights</text><text x=\"71.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1</text><text x=\"209.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2</text><text x=\"347.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3</text><text x=\"485.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4</text><text x=\"623.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">5</text><path d=\"M623.0 110 L623.0 150 L71.0 150 L71.0 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M71.0 120 L71.0 112\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M74.1 119.4 L71.0 112 L67.9 119.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"350\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">next batch</text></svg>", "caption": "One training step, five lines. Leave out the third and the fourth adds this batch's gradients to every batch before it."}
```

**Their order is the whole difficulty.** `zero_grad` has to come before `backward`, because
`backward` adds into `.grad`; and `step` has to come after it, because `step` reads `.grad`. Where
`zero_grad` goes before that is free: `loop.py` calls it after the loss, and many programs call it
first. What the optimiser does in `step` is lesson 5's subject. `torch.optim.SGD` subtracts the rate
times the gradient, as `optim.SGD` did, and keeps a reference to the parameters it was handed, so
nothing is passed to it per step.

## The first run

Save as `~/dl/train.py` and run it:

```schooling-example
{
  "language": "python",
  "file": "train.py",
  "parts": [
    {
      "code": "\"\"\"train: the MLP on the digits, with PyTorch's own SGD and the loop from loop.py.\"\"\"\nimport torch\n\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\ntorch.manual_seed(0)\ntrain, val, _ = tdigits.load()\nmodel = make_mlp()\nopt = torch.optim.SGD(model.parameters(), lr=0.1)",
      "note": "The seed fixes the initial weights, so the run is the same every time on one machine. The optimiser receives the parameters once and keeps a reference to them; `torch.optim.Adam` would go in the same place with the same call."
    },
    {
      "code": "loop.fit(model, opt, train, val, epochs=30, every=5)\ntorch.save(model.state_dict(), \"mlp.pt\")",
      "note": "Thirty epochs, a line every five. The last line writes the trained weights to a file, and the section on saving reads them back."
    }
  ]
}
```

```
ana@vm:~/dl$ python train.py
epoch   5  train loss 0.7931  val loss 0.6755  val acc 0.872
epoch  10  train loss 0.3170  val loss 0.3068  val acc 0.922
epoch  15  train loss 0.2154  val loss 0.2290  val acc 0.933
epoch  20  train loss 0.1661  val loss 0.2004  val acc 0.936
epoch  25  train loss 0.1374  val loss 0.1638  val acc 0.944
epoch  30  train loss 0.1205  val loss 0.1461  val acc 0.950
```

**The validation accuracy reaches 0.950 after 30 epochs**, and the training loss falls on every line,
from 0.7931 at epoch 5 to 0.1205. That is a plain SGD at a rate of 0.1 on a network of 2,410
parameters, so the number is a baseline and not a ceiling: the optimisers of lesson 5 and a wider
hidden layer would both move it.

The run also left `mlp.pt` in `~/dl`, the file the last section reads. Lesson 10 replaces the
slicing of `order` with a `DataLoader`, and lesson 11 trains a convolutional network with this same
`fit`.
