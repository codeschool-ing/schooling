---
title: An RNN, written out by hand
version: 1
---

A recurrent network sounds like a new kind of machine. **It is the layer of lesson 1 inside a `for`
loop**, with one extra input: what the loop computed at the step before. At step *t* it reads the
input `x_t` and the previous state `h_{t-1}`, and writes a new state:

`h_t = tanh(x_t W_ih + h_{t-1} W_hh + b)`

The state is a vector of a fixed size, five numbers in the program below, and it is the network's
whole memory. Whatever the sequence said before step *t* reaches step *t* only through it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 240\" role=\"img\" aria-label=\"An RNN unrolled over four steps. Four identical boxes labelled RNN sit in a row, each reading one input from below, x0 to x3. An arrow carries the state from each box to the next, starting from a state of zero on the left, and each box hands its state up as an output, h0 to h3. The last state, h3, is what a model reading the whole sequence uses.\"><text x=\"320\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">the same cell, with the same weights, at every step</text><text x=\"40\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\">0</text><path d=\"M52 120 L92 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M84.6 123.1 L92 120 L84.6 116.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"95\" y=\"95\" width=\"80\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">RNN</text><path d=\"M135 195 L135 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M138.1 155.4 L135 148 L131.9 155.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"135\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">x0</text><path d=\"M135 95 L135 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M138.1 69.4 L135 62 L131.9 69.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"135\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h0</text><path d=\"M175 120 L227 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M219.6 123.1 L227 120 L219.6 116.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"230\" y=\"95\" width=\"80\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">RNN</text><path d=\"M270 195 L270 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M273.1 155.4 L270 148 L266.9 155.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"270\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">x1</text><path d=\"M270 95 L270 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M273.1 69.4 L270 62 L266.9 69.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"270\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h1</text><path d=\"M310 120 L362 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M354.6 123.1 L362 120 L354.6 116.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"365\" y=\"95\" width=\"80\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">RNN</text><path d=\"M405 195 L405 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M408.1 155.4 L405 148 L401.9 155.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"405\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">x2</text><path d=\"M405 95 L405 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M408.1 69.4 L405 62 L401.9 69.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"405\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h2</text><path d=\"M445 120 L497 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M489.6 123.1 L497 120 L489.6 116.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500\" y=\"95\" width=\"80\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">RNN</text><path d=\"M540 195 L540 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M543.1 155.4 L540 148 L536.9 155.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">x3</text><path d=\"M540 95 L540 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M543.1 69.4 L540 62 L536.9 69.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"540\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">h3</text><text x=\"201\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">state</text><text x=\"125\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">input</text></svg>", "caption": "An RNN is one cell applied once per step. Unrolled, it looks like a deep network whose layers all share the same weights."}
```

The program builds PyTorch's `nn.RNN`, runs it, and then computes the same thing with the formula in
a loop. Save as `~/dl/rnn_by_hand.py`:

```schooling-example
{
  "language": "python",
  "file": "rnn_by_hand.py",
  "parts": [
    {
      "code": "\"\"\"rnn_by_hand: what nn.RNN computes, written as a loop over time.\"\"\"\nimport torch\nimport torch.nn as nn\n\ntorch.manual_seed(0)\nrnn = nn.RNN(input_size=3, hidden_size=5, batch_first=True)\nx = torch.randn(2, 4, 3)\nout, h_last = rnn(x)\nprint(\"out\", tuple(out.shape), \" h_last\", tuple(h_last.shape))",
      "note": "Two sequences of four steps, three features a step. `batch_first=True` asks for the batch on the first axis; without it, PyTorch's recurrent layers expect time first. The layer returns two things: the state after every step, and the state after the last one."
    },
    {
      "code": "W_ih, W_hh = rnn.weight_ih_l0, rnn.weight_hh_l0\nb = rnn.bias_ih_l0 + rnn.bias_hh_l0\nh = torch.zeros(2, 5)\nsteps = []\nfor t in range(4):\n    h = torch.tanh(x[:, t] @ W_ih.T + h @ W_hh.T + b)\n    steps.append(h)\nmine = torch.stack(steps, dim=1)",
      "note": "The whole RNN is the line inside the loop. The new state mixes this step's input and the previous state, each through its own matrix, and passes the sum through `tanh`. The state starts at zero, and the same two matrices serve every step."
    },
    {
      "code": "print(\"the loop equals nn.RNN:\", torch.allclose(mine, out, atol=1e-6))\nprint(\"the last output is the final state:\", torch.equal(out[:, -1], h_last[0]))\nprint(\"parameters:\", sum(p.numel() for p in rnn.parameters()),\n      \"=\", W_ih.numel(), \"+\", W_hh.numel(), \"+ 2 biases of\", b.numel())\nprint(\"the same 50 parameters read a sequence of 40:\", tuple(rnn(torch.randn(2, 40, 3))[0].shape))",
      "note": "PyTorch keeps two biases where one would do, which is why the count has two of five. The last line gives the layer a sequence ten times longer and nothing has to change: the weights belong to the step, not to a position."
    }
  ]
}
```

```
PENDING rnn
```

**The loop and `nn.RNN` agree**, so there is nothing else hidden inside the layer: two matrix
products, a bias and a `tanh`, once per step. PyTorch's version is a compiled loop over the same
steps, which is faster and does the same arithmetic.

`out` has a state for every step, `(2, 4, 5)`, and `h_last` only the final one, with a leading axis of
1 that counts layers. **The final state is the summary of the whole sequence**, and a model that has to
answer one question about a sequence, such as which class it belongs to, usually reads that and nothing
else. A model that labels every step, such as a tagger marking each word as a noun or a verb, reads all
of `out`.

The layer has 50 parameters: 15 in `W_ih`, 25 in `W_hh`, and two biases of 5. **None of them depends on
the length**, which is why the last line reads a sequence of 40 steps with the same weights that read 4.
That fixes the dense layer's problem from the previous section. It also makes the unrolled drawing above
literally true: four steps of an RNN are a four-layer network whose layers share their weights, and
training it means backpropagating through all four, which is the next section.
