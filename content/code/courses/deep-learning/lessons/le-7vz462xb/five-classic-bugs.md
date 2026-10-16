---
title: Five classic bugs, each one run
version: 1
---

A training loop with a mistake in it rarely stops. **Most of the mistakes below run to the end and
print numbers**, and the numbers are what has to be read. Each one below is common, and each
was run, so its symptom is a transcript rather than a description. Save as `~/dl/bugs.py`:

```schooling-example
{
  "language": "python",
  "file": "bugs.py",
  "parts": [
    {
      "code": "\"\"\"bugs: the training loop with one classic mistake in it, named on the command line.\"\"\"\nimport sys\n\nimport numpy as np\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\n\nimport tdigits\nfrom mlp import make_mlp\n\nbug = sys.argv[1]\ntorch.manual_seed(0)\n(x, y), (x_val, y_val), _ = tdigits.load()\nmodel = make_mlp()\nif bug == \"eval\":\n    model = nn.Sequential(model[0], model[1], nn.Dropout(0.5), model[2])\nif bug == \"labels\":\n    y = y.reshape(-1, 1)\nopt = torch.optim.SGD(model.parameters(), lr=0.1)",
      "note": "The same network, data and rate as `train.py`. Two mistakes need something set up first: the `eval` case puts dropout in the network, because evaluation mode only changes a network that has a layer it affects, and the `labels` case gives every label a dimension of its own."
    },
    {
      "code": "for epoch in range(1, 11):\n    order = torch.randperm(len(y))\n    losses = []\n    for start in range(0, len(y), 32):\n        idx = order[start:start + 32]\n        logits = model(x[idx])\n        if bug == \"softmax\":\n            logits = F.softmax(logits, dim=1)\n        loss = F.cross_entropy(logits, y[idx])\n        if bug != \"zero_grad\":\n            opt.zero_grad()\n        loss.backward()\n        opt.step()\n        losses.append(loss if bug == \"item\" else loss.item())\n    if epoch % 5 == 0:\n        print(f\"epoch {epoch:2d}  train loss {np.mean(losses):.4f}\")",
      "note": "The loop of `loop.py`, written inline for ten epochs, with an `if` where each mistake goes in. Any other name on the command line, `none` for instance, runs it correctly."
    },
    {
      "code": "if bug == \"eval\":\n    for _ in range(2):\n        logits = model(x_val)\n        acc = (logits.argmax(dim=1) == y_val).float().mean().item()\n        print(f\"no eval(), no no_grad():  val acc {acc:.3f}  recorded {logits.requires_grad}\")\nmodel.eval()\nwith torch.no_grad():\n    logits = model(x_val)\nacc = (logits.argmax(dim=1) == y_val).float().mean().item()\nprint(f\"eval() and no_grad():  val acc {acc:.3f}  recorded {logits.requires_grad}\")",
      "note": "The validation accuracy, measured the right way at the end of every run. In the `eval` case it is measured twice the wrong way first, in training mode and with the record running."
    }
  ]
}
```

First the correct loop, to have something to compare with:

```
ana@vm:~/dl$ python bugs.py none
epoch  5  train loss 0.7894
epoch 10  train loss 0.3120
eval() and no_grad():  val acc 0.914  recorded False
```

## 1. Forgetting `zero_grad`

```
ana@vm:~/dl$ python bugs.py zero_grad
epoch  5  train loss 2.6018
epoch 10  train loss 3.8694
eval() and no_grad():  val acc 0.200  recorded False
```

**The loss goes up, from 2.6018 at epoch 5 to 3.8694 at epoch 10, and the accuracy ends at 0.200.**
Without `zero_grad`, every `backward` adds to the gradients of every batch before it, so `step` moves
the weights by the sum of all the gradients so far. The step grows with every batch until training
is thrown about rather than guided. With a smaller rate the same bug can look like a slow,
almost normal curve, which is the harder case to spot.

## 2. Softmax before the loss

```
ana@vm:~/dl$ python bugs.py softmax
epoch  5  train loss 2.2955
epoch 10  train loss 2.2804
eval() and no_grad():  val acc 0.194  recorded False
```

**The loss stays near 2.3, at 2.2955 and then 2.2804, and the accuracy ends at 0.194.** `F.cross_entropy` takes raw scores, the
logits, and applies the softmax itself. Given probabilities instead, it applies a second softmax to
numbers that all lie between 0 and 1, and the result is close to even across the ten classes
whatever the network says. The gradient that reaches the weights is squeezed accordingly, and
training barely moves. A last layer with `nn.Softmax` in it does the same damage less visibly.

## 3. Evaluating in training mode, with the record running

```
ana@vm:~/dl$ python bugs.py eval
epoch  5  train loss 1.2932
epoch 10  train loss 0.8318
no eval(), no no_grad():  val acc 0.742  recorded True
no eval(), no no_grad():  val acc 0.728  recorded True
eval() and no_grad():  val acc 0.908  recorded False
```

This network has dropout, which lesson 7 wrote by hand: in training mode it zeroes half the hidden
units at random. **Measured twice in training mode, the same network on the same images scored 0.742
and then 0.728**, and both are below the 0.908 it scores in evaluation mode. A score that changes
when nothing changed is the symptom. A network with batch normalisation, lesson 8's subject, gets it
worse, since every evaluation in training mode also moves its running statistics.

The second half of the mistake prints `recorded True`. Without `torch.no_grad()` every operation of
the evaluation was recorded, for a backward pass that never comes. It costs memory and time and
nothing else, so it shows up only when the validation set is large.

## 4. Keeping the loss as a tensor

```
ana@vm:~/dl$ python bugs.py item
Traceback (most recent call last):
  File "/home/ana/dl/bugs.py", line 38, in <module>
    print(f"epoch {epoch:2d}  train loss {np.mean(losses):.4f}")
                                          ^^^^^^^^^^^^^^^
  File "/home/ana/dl/.venv/lib/python3.12/site-packages/numpy/_core/fromnumeric.py", line 3862, in mean
    return _methods._mean(a, axis=axis, dtype=dtype,
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/dl/.venv/lib/python3.12/site-packages/numpy/_core/_methods.py", line 116, in _mean
    arr = asanyarray(a)
          ^^^^^^^^^^^^^
  File "/home/ana/dl/.venv/lib/python3.12/site-packages/torch/_tensor.py", line 1255, in __array__
    return self.numpy()
           ^^^^^^^^^^^^
RuntimeError: Can't call numpy() on Tensor that requires grad. Use tensor.detach().numpy() instead.
```

`losses.append(loss)` kept each batch's loss as a tensor, together with its record. The training
ran, and it was the first report, at epoch 5, that failed: NumPy cannot turn a tensor that requires a gradient into an
array, and says to `detach()` it first. **Write `loss.item()` wherever a loss is kept for
reporting.** The error is the lucky version. `total += loss` raises nothing, adds every batch's
record to one growing chain, and holds all of them in memory until the epoch ends.

## 5. Labels in the wrong shape

```
ana@vm:~/dl$ python bugs.py labels
Traceback (most recent call last):
  File "/home/ana/dl/bugs.py", line 31, in <module>
    loss = F.cross_entropy(logits, y[idx])
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/dl/.venv/lib/python3.12/site-packages/torch/nn/functional.py", line 3561, in cross_entropy
    return torch._C._nn.cross_entropy_loss(
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
RuntimeError: 0D or 1D target tensor expected, multi-target not supported
```

`F.cross_entropy` wants one class number per example, shape `[32]`, and the labels were `[32, 1]`.
This one stops at the first batch, with a message naming the target. **The silent version of this
bug lives in regression**, where predictions come out as a column and targets as a row:

```
ana@vm:~/dl$ python -c "import torch, torch.nn.functional as F; y = torch.arange(4.0); print(F.mse_loss(y.reshape(-1, 1), y), F.mse_loss(y, y))"
<string>:1: UserWarning: Using a target size (torch.Size([4])) that is different to the input size (torch.Size([4, 1])). This will likely lead to incorrect results due to broadcasting. Please ensure they have the same size.
tensor(2.5000) tensor(0.)
```

The four predictions equal the four targets, so the loss should be 0, and it is 2.5. `F.mse_loss`
broadcast `[4, 1]` against `[4]` to `[4, 4]`, compared every prediction with every target, and only
warned. Training on that loss runs to the end and learns the wrong thing. Printing the shapes of both
arguments of a loss the first time it runs costs one line and rules out the whole family.
