---
title: Autograd, checked against lesson 3
version: 1
---

Lesson 3 computed the gradients of a 2-2-1 network by hand: forward, then the chain rule written out
one weight at a time, then `tinynet.py` doing the same for any stack of layers. **PyTorch does that
part for you**, and the way to trust it is to give it the same network and compare. Save as
`~/dl/autograd.py`:

```schooling-example
{
  "language": "python",
  "file": "autograd.py",
  "parts": [
    {
      "code": "\"\"\"autograd: lesson 3's 2-2-1 network again, with PyTorch working out the gradients.\"\"\"\nimport torch\n\nx = torch.tensor([1.0, 2.0])\ny = 1.0\nW1 = torch.tensor([[0.5, -0.5],\n                   [0.25, 0.25]], requires_grad=True)\nb1 = torch.tensor([0.0, -1.0], requires_grad=True)\nW2 = torch.tensor([1.5, 1.0], requires_grad=True)\nb2 = torch.tensor(0.25, requires_grad=True)",
      "note": "The same input, target and weights as lesson 3's `byhand.py`. `requires_grad=True` marks the four tensors whose gradients are wanted; the input and the target are data and carry no mark."
    },
    {
      "code": "out = torch.relu(x @ W1 + b1) @ W2 + b2\nL = (out - y) ** 2\nprint(\"out\", out.item(), \" L\", L.item())\nprint(\"recorded:\", L.grad_fn.name(), \"<-\", L.grad_fn.next_functions[0][0].name())",
      "note": "The forward pass is written as ordinary arithmetic. Because some of its inputs are marked, every operation also records itself, and `grad_fn` is the last entry of that record: the square, which points back at the subtraction before it."
    },
    {
      "code": "L.backward()\nprint(\"dW2\", W2.grad.tolist(), \" db2\", b2.grad.item())\nprint(\"dW1\", W1.grad.tolist(), \" db1\", b1.grad.tolist())",
      "note": "One call walks the record backwards, applying the chain rule at every step, and leaves each marked tensor's gradient in its `.grad`. Nothing here was written by hand."
    },
    {
      "code": "L = (torch.relu(x @ W1 + b1) @ W2 + b2 - y) ** 2\nL.backward()\nprint(\"again, not zeroed: dW2\", W2.grad.tolist())",
      "note": "A second forward and backward on the same weights. `backward` adds into `.grad` rather than replacing it, so the gradient comes out doubled."
    },
    {
      "code": "with torch.no_grad():\n    out = torch.relu(x @ W1 + b1) @ W2 + b2\nprint(\"under no_grad:\", out.requires_grad, out.grad_fn)",
      "note": "Inside `torch.no_grad()` nothing is recorded: the result has no `grad_fn` and cannot be differentiated. It is how a prediction is made when no training step will follow."
    }
  ]
}
```

```
ana@vm:~/dl$ python autograd.py
out 1.75  L 0.5625
recorded: PowBackward0 <- SubBackward0
dW2 [1.5, 0.0]  db2 1.5
dW1 [[2.25, 0.0], [4.5, 0.0]]  db1 [2.25, 0.0]
again, not zeroed: dW2 [3.0, 0.0]
under no_grad: False None
```

**The numbers are lesson 3's.** The output is 1.75 against a target of 1, the loss 0.5625, the
gradient of `W2` is `[1.5, 0.0]` and that of `W1` is `[[2.25, 0.0], [4.5, 0.0]]`, with the right
column zero because the second hidden unit's ReLU was off. Nothing in the program says how to
differentiate a product, a ReLU or a square.

## What it records

Autograd is not symbolic differentiation and it does not read the program. **It watches the
arithmetic as it runs.** Every operation on a tensor that requires a gradient creates a small record
of itself, holding what it needs for its own backward step: the matrix product keeps its inputs,
the ReLU keeps which elements were positive. The records point at the ones before them, and
`grad_fn` is the last: `PowBackward0`, the square, pointing at `SubBackward0`, the subtraction.

`backward()` walks that chain from the end, which is exactly what `Net.backward` did by walking the
layers in reverse. Because the record is made while the code runs, an `if` or a loop in a forward
pass needs nothing special: whatever ran is what gets differentiated.

## Two consequences

**Gradients add up.** The second `backward` left `W2.grad` at `[3.0, 0.0]`, twice the first. It
adds rather than replaces, which is useful when one step is split over several batches, and it is
why a training loop empties every `.grad` before each `backward`. Three sections on, the
first of five bugs shows what happens when it does not.

**Recording costs memory, so it can be switched off.** Inside `torch.no_grad()` the result has no
`grad_fn` and `requires_grad` is `False`. Measuring a network on a validation set is done that way,
because nothing will be differentiated and the records would be built for nobody.

`.item()` and `.tolist()` in the program turn tensors into plain Python numbers for printing. A
tensor that requires a gradient refuses to become a NumPy array directly, for a reason the fourth of
those bugs shows.
