---
title: What a layer actually computes
version: 1
---

A diagram of a network draws circles joined by lines, one line per weight, and it suggests the units
work one by one. **They do not. A layer is one matrix product**, for every unit and every input in a
batch at once, and that is why graphics cards, which do little else, train networks so well.

Sixteen units looking at 64 pixels have 64 × 16 weights. Arrange them as a matrix `W` with a row per
pixel and a column per unit, put five images in the rows of `x`, and `x @ W` is a 5 by 16 matrix: row
*i*, column *j* is image *i* seen by unit *j*. Add the bias of each unit, and apply the activation to
every element.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"A batch of 5 rows of 64 numbers is multiplied by a weight matrix of 64 rows and 16 columns, the bias of 16 is added to every row, and the result is 5 rows of 16 numbers, to which ReLU is applied element by element.\"><rect x=\"20\" y=\"80\" width=\"200\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M20 92 L220 92\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M20 104 L220 104\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M20 116 L220 116\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M20 128 L220 128\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">x  (5 × 64)</text><text x=\"120\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a batch of 5 images</text><text x=\"120\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">64 numbers each</text><text x=\"245\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">@</text><rect x=\"270\" y=\"30\" width=\"90\" height=\"160\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">W  (64 × 16)</text><text x=\"315\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">weights</text><text x=\"315\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">64 inputs × 16 units</text><text x=\"385\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">+</text><rect x=\"405\" y=\"103\" width=\"90\" height=\"14\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">b  (16)</text><text x=\"520\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">=</text><rect x=\"545\" y=\"80\" width=\"90\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M545 92 L635 92\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M545 104 L635 104\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M545 116 L635 116\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M545 128 L635 128\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"590\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">z  (5 × 16)</text><text x=\"590\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">16 outputs each</text><text x=\"590\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">then ReLU, element by element</text></svg>", "caption": "One layer, one matrix product: every image of the batch times every unit's weights, in a single operation."}
```

Save as `~/dl/layer.py`:

```schooling-example
{
  "language": "python",
  "file": "layer.py",
  "parts": [
    {
      "code": "\"\"\"layer: what one layer does to a batch of five digits.\"\"\"\nimport numpy as np\n\nimport digits\n\n(x, y), _, _ = digits.load()\nbatch = x[:5]\nrng = np.random.default_rng(0)\nW = rng.normal(0, 0.1, (64, 16))\nb = np.zeros(16)",
      "note": "Sixteen units, each with 64 weights, one per pixel. Stacked, the weights are a 64 by 16 matrix and the biases a vector of 16. They start small and random, which is where training starts too."
    },
    {
      "code": "z = batch @ W + b\nh = np.maximum(0, z)\nprint(\"batch\", batch.shape, \" W\", W.shape, \" b\", b.shape, \" z\", z.shape, \" h\", h.shape)\nprint(\"parameters:\", W.size + b.size)",
      "note": "The whole layer is these two lines: one matrix product for every unit and every image at once, then ReLU on each element. `b` is added to every row, which NumPy calls broadcasting."
    },
    {
      "code": "print(\"first image, first four units:\", np.round(h[0, :4], 3))\nprint(\"units at zero in the batch:\", int((h == 0).sum()), \"of\", h.size)",
      "note": "How many outputs ReLU set to zero. A unit at zero for a given image says nothing about it, and that is normal."
    },
    {
      "code": "# Two layers with no activation between them are one layer in disguise.\nW2 = rng.normal(0, 0.1, (16, 10))\ntwo = (batch @ W) @ W2\none = batch @ (W @ W2)\nprint(\"two linear layers equal one:\", np.allclose(two, one), \" merged W\", (W @ W2).shape)",
      "note": "Matrix products associate: `(x W) W2` is `x (W W2)`. Without a function between them, a second layer adds parameters and no ability at all."
    }
  ]
}
```

```
ana@vm:~/dl$ python layer.py
batch (5, 64)  W (64, 16)  b (16,)  z (5, 16)  h (5, 16)
parameters: 1040
first image, first four units: [0.    0.    0.053 0.034]
units at zero in the batch: 52 of 80
two linear layers equal one: True  merged W (64, 10)
```

**The shapes are the first thing to check in any network**, and most errors you will meet in
PyTorch are a shape that did not match. `(5, 64) @ (64, 16)` works because the inner numbers agree,
and the result takes the outer ones. The layer has 64 × 16 + 16 = 1,040 parameters, the number a
framework prints when it describes a model.

52 of the 80 outputs are zero. With random weights, about half the sums come out negative and ReLU
cuts them, so a sparse output is the expected state of a fresh layer, not a fault.

**The last line is the reason activations exist.** `(x @ W) @ W2` and `x @ (W @ W2)` are equal,
and `W @ W2` is a single 64 by 10 matrix. A stack of layers with nothing between them computes one
linear function, whatever its depth, and a linear function can only draw the one straight line the
perceptron was stuck with. The ReLU between two layers is what stops the product from merging.
