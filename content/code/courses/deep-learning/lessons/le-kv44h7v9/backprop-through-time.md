---
title: Backpropagation through time, and the gradient that fades
version: 1
---

Training an RNN needs no new algorithm. **Unroll it, and it is a deep network; lesson 3's
backpropagation runs through it unchanged.** The name for this, backpropagation through time, says
only that the layers of the unrolled network are the steps of the sequence. The weights are shared, so
each weight's gradient is the sum of what every step contributes.

The trouble is in the word *deep*. A sequence of 50 steps unrolls into 50 layers, and lesson 3 showed
what happens to a gradient on its way down a deep stack of sigmoids: it shrinks layer by layer. The same
happens here. To find out how much the last output depends on each input, the program below asks
autograd for the gradient with respect to the input itself. Save as `~/dl/bptt.py`:

```schooling-example
{
  "language": "python",
  "file": "bptt.py",
  "parts": [
    {
      "code": "\"\"\"bptt: how much the last output of a recurrent layer depends on each input before it.\"\"\"\nimport sys\n\nimport torch\nimport torch.nn as nn\n\ncell = sys.argv[1]\ntorch.manual_seed(0)\nif cell == \"rnn\":\n    layer = nn.RNN(8, 32, batch_first=True)\nelse:\n    layer = nn.LSTM(8, 32, batch_first=True)\n    if len(sys.argv) > 2:\n        with torch.no_grad():\n            layer.bias_hh_l0[32:64] += float(sys.argv[2])",
      "note": "The first argument picks the layer, `rnn` or `lstm`; the second, for an LSTM, is a number added to one of its biases. That second argument is for the next section, and this one runs only `rnn`."
    },
    {
      "code": "x = torch.randn(1, 50, 8, requires_grad=True)\nout, _ = layer(x)\nout[0, -1].sum().backward()\nsize = x.grad[0].norm(dim=1)",
      "note": "One sequence of 50 steps, with `requires_grad` on the input itself. After `backward`, `x.grad` holds, for every step, how much the last output would move if that step's input moved: its gradient, summed up as one length per step."
    },
    {
      "code": "for back in (0, 1, 2, 5, 10, 20, 30, 49):\n    print(f\"{cell}  {back:2d} steps back  gradient {size[49 - back]:.1e}\")"
    }
  ]
}
```

```
PENDING bptt-rnn
```

**The input at the last step moves the output with a gradient of 1.6; the input 49 steps back, with
2.9e-14.** Ten steps back it is 3.4e-03, nearly five hundred times smaller than at the end, and
twenty steps back it is 6.2e-06. Whatever the first symbol of a sequence said, the update it sends to the weights
is too small to change anything.

The reason is a product. Going back one step multiplies the gradient by `W_hh` and by the slope of
`tanh`, which is at most 1 and smaller wherever the unit is far from zero. Fifty such factors, each a
little below 1 in size, make a number very close to zero. Had the weights been large, the same product
would have grown instead, and an exploding gradient sends the weights flying in one step. That case has
a blunt and effective cure, cutting the gradient's length to a ceiling before the step, which PyTorch
provides as `torch.nn.utils.clip_grad_norm_`. **The shrinking case has no such cure**, because a
gradient of 1e-14 carries no direction worth scaling up.

So a plain RNN learns what sits a few steps back and is blind to what sits fifty steps back, not
because it lacks the memory to hold it but because training never tells it to. The fix was not a better
optimiser. It was a different cell.
