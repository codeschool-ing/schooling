---
title: What the filters learnt
version: 1
---

`filter.py` used a filter somebody wrote. The network's first layer has sixteen, and **nobody wrote
any of them**: they started as small random numbers and the gradient moved them, step by step, towards
whatever made the loss fall. `compare.py` saved the trained weights in `cnn.pt`. This program reads
them back and prints the first layer. Save as `~/dl/filters.py`:

```schooling-example
{
  "language": "python",
  "file": "filters.py",
  "parts": [
    {
      "code": "\"\"\"filters: the sixteen 3x3 filters of the first layer, before and after training.\"\"\"\nimport torch\n\nimport cnn\n\ntorch.manual_seed(0)\nstart = cnn.make_cnn()[0].weight.detach()\nnet = cnn.make_cnn()\nnet.load_state_dict(torch.load(\"cnn.pt\"))\nw = net[0].weight.detach()\nprint(f\"largest weight: {start.abs().max():.2f} at the start, {w.abs().max():.2f} after training\")",
      "note": "The same seed as `compare.py` rebuilds the network exactly as training found it, so `start` holds the filters before the first step. `net` gets the saved weights, and `net[0]` is the first convolution."
    },
    {
      "code": "w = w.reshape(16, 3, 3)\nfor first in range(0, 16, 4):\n    group = range(first, first + 4)\n    print(\"   \".join(f\"filter {i}\".ljust(17) for i in group).rstrip())\n    for row in range(3):\n        print(\"   \".join(\" \".join(f\"{v:5.2f}\" for v in w[i, row]) for i in group))",
      "note": "The weight is 16 by 1 by 3 by 3; dropping the channel of 1 leaves sixteen 3x3 grids, printed four side by side."
    }
  ]
}
```

```
PENDING filters
```

**The filters moved a long way from where they started.** PyTorch starts a layer whose units each
read 9 inputs with weights between -1/3 and 1/3, which is the 0.33 on the first line; after training
the largest is 0.57. Drawn as grids, with one colour for weights above zero and another for weights
below, the printed numbers look like this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The sixteen 3 by 3 filters of the first layer after training, drawn as grids of squares in two rows of eight. Each square is coloured by its weight: one colour for positive weights and another for negative ones, stronger for larger values. Several filters have a band of one sign beside a band of the other, which is an edge at some angle.\"><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">PENDING</text></svg>", "caption": "The first layer's sixteen filters after 30 epochs, drawn from the printed weights. Nobody chose these patterns; the gradient did."}
```

Several of them are edge detectors of the kind `filter.py` used, at angles nobody asked for. **Filter
8 is positive along its top and left and negative in its bottom right corner**: it responds where a
stroke's ink sits up and to the left of a blank, a diagonal edge. Filter 15 is near zero along its top
row and positive below it, so it answers for the top edge of a horizontal stroke. Filter 6 has its most
negative weights across the middle row and its largest positive ones in the corners and along the
bottom: a blank line between two strokes, like the middle of a loop, would fit it.

**Read that as a guess, not a finding.** On 8 by 8 images a 3 by 3 filter covers a large piece of the
digit, and some of the sixteen look like nothing in particular. The second layer combines all sixteen
maps through 4,640 weights, and what the network uses is that combination, not any one filter. On
large photographs the first layer's filters are much tidier: the network of Krizhevsky, Sutskever and
Hinton in 2012 drew its 96 first-layer filters, and they are oriented edges and patches of colour,
learnt from images alone.
