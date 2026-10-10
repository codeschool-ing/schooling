---
title: Vanishing gradients
version: 1
---

From the 1980s until about 2010, the hidden layers of most networks used the sigmoid, and networks
deeper than a few layers were known to train badly. The usual explanation was that deep networks were simply too
hard. **The chain rule says exactly what was wrong, and it is a product.** The gradient that
reaches the first layer has been multiplied by one local derivative for every layer above it, and a
sigmoid's local derivative is at most 0.25. Ten factors that small multiply to almost nothing.

The program builds two ten-layer networks that differ only in the function between the layers,
runs one backward pass through each before any training, and prints how large the weight gradient
of each layer is. Then it trains both. Save as `~/dl/vanish.py`:

```schooling-example
{
  "language": "python",
  "file": "vanish.py",
  "parts": [
    {
      "code": "\"\"\"vanish: the gradient reaching each layer of a ten-layer net, sigmoid against ReLU.\"\"\"\nimport numpy as np\n\nimport digits\nimport tinynet"
    },
    {
      "code": "class Sigmoid:\n    \"\"\"1 / (1 + e^-x) on the way forward; its slope, never above 0.25, on the way back.\"\"\"\n\n    def forward(self, x):\n        self.out = 1 / (1 + np.exp(-x))\n        return self.out\n\n    def backward(self, grad):\n        return grad * self.out * (1 - self.out)",
      "note": "A sigmoid layer written to `tinynet`'s interface: `forward` keeps what `backward` needs. Its slope `out·(1−out)` is 0.25 at the centre and smaller everywhere else."
    },
    {
      "code": "def deep(activation, rng):\n    layers = [tinynet.Linear(64, 32, rng), activation()]\n    for _ in range(8):\n        layers += [tinynet.Linear(32, 32, rng), activation()]\n    return tinynet.Net(*layers, tinynet.Linear(32, 10, rng))",
      "note": "Ten `Linear` layers of 32 units with an activation between each pair. The two networks differ only in that function: same widths, same seed, same starting weights."
    },
    {
      "code": "(x, y), (x_val, y_val), _ = digits.load()\nnorms = {}\nfor name, activation in ((\"sigmoid\", Sigmoid), (\"relu\", tinynet.ReLU)):\n    net = deep(activation, np.random.default_rng(0))\n    _, grad = tinynet.softmax_cross_entropy(net.forward(x[:64]), y[:64])\n    net.backward(grad)\n    norms[name] = [np.linalg.norm(layer.dW) for layer in net.layers[::2]]\n\nprint(\"layer   sigmoid      relu\")\nfor i, (s, r) in enumerate(zip(norms[\"sigmoid\"], norms[\"relu\"]), start=1):\n    print(f\"{i:5d}  {s:9.2e}  {r:9.2e}\")",
      "note": "One backward pass on 64 images, before any training. The norm of a layer's weight gradient is one number for how hard that layer is being pushed to change. Layer 1 is next to the input and layer 10 next to the loss."
    },
    {
      "code": "for name, activation in ((\"sigmoid\", Sigmoid), (\"relu\", tinynet.ReLU)):\n    rng = np.random.default_rng(0)\n    net = deep(activation, rng)\n    for epoch in range(10):\n        order = rng.permutation(len(y))\n        for start in range(0, len(order), 32):\n            rows = order[start:start + 32]\n            _, grad = tinynet.softmax_cross_entropy(net.forward(x[rows]), y[rows])\n            net.backward(grad)\n            for value, gradient in net.params():\n                value -= 0.1 * gradient\n    accuracy = (net.forward(x_val).argmax(axis=1) == y_val).mean()\n    print(f\"{name:7s} after 10 epochs: val accuracy {accuracy:.3f}\")",
      "note": "And what that does to training: `train.py`'s loop, ten epochs, the same rate for both."
    }
  ]
}
```

```
ana@vm:~/dl$ python vanish.py
layer   sigmoid      relu
    1   2.05e-05   1.21e+00
    2   4.32e-05   7.12e-01
    3   1.33e-04   5.92e-01
    4   4.27e-04   1.10e+00
    5   1.53e-03   8.41e-01
    6   4.41e-03   7.24e-01
    7   2.00e-02   7.71e-01
    8   7.27e-02   7.34e-01
    9   2.94e-01   9.00e-01
   10   8.44e-01   5.89e-01
sigmoid after 10 epochs: val accuracy 0.106
relu    after 10 epochs: val accuracy 0.850
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 330\" role=\"img\" aria-label=\"Gradient norm of each of the ten layers before training, on a log scale. The ReLU network&#x27;s ten values stay between about 0.6 and 1.2. The sigmoid network&#x27;s fall in an almost straight line on the log scale, from 0.844 at layer 10 to 0.0000205 at layer 1.\"><path d=\"M90 260.0 L560 260.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-5</text><path d=\"M90 223.33333333333334 L560 223.33333333333334\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"223.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-4</text><path d=\"M90 186.66666666666666 L560 186.66666666666666\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"186.66666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-3</text><path d=\"M90 150.0 L560 150.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-2</text><path d=\"M90 113.33333333333333 L560 113.33333333333333\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"113.33333333333333\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e-1</text><path d=\"M90 76.66666666666666 L560 76.66666666666666\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"76.66666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e0</text><path d=\"M90 40.0 L560 40.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1e1</text><text x=\"90.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"142.22222222222223\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"194.44444444444446\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"246.66666666666666\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"298.8888888888889\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"351.1111111111111\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><text x=\"403.3333333333333\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><text x=\"455.55555555555554\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><text x=\"507.77777777777777\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><text x=\"560.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M90 40 L90 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 260 L560 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90.0 248.6 L142.2 236.7 L194.4 218.8 L246.7 200.2 L298.9 179.9 L351.1 163.0 L403.3 139.0 L455.6 118.4 L507.8 96.2 L560.0 79.4\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"248.6\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"142.2\" cy=\"236.7\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"194.4\" cy=\"218.8\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"246.7\" cy=\"200.2\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"298.9\" cy=\"179.9\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"351.1\" cy=\"163.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"403.3\" cy=\"139.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"455.6\" cy=\"118.4\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"507.8\" cy=\"96.2\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"560.0\" cy=\"79.4\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"365.1111111111111\" y=\"177.0372517195126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">sigmoid</text><path d=\"M90.0 73.6 L142.2 82.1 L194.4 85.0 L246.7 75.1 L298.9 79.4 L351.1 81.8 L403.3 80.8 L455.6 81.6 L507.8 78.3 L560.0 85.1\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"73.6\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"142.2\" cy=\"82.1\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"194.4\" cy=\"85.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"246.7\" cy=\"75.1\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"298.9\" cy=\"79.4\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"351.1\" cy=\"81.8\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"403.3\" cy=\"80.8\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"455.6\" cy=\"81.6\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"507.8\" cy=\"78.3\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"560.0\" cy=\"85.1\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"168.33333333333331\" y=\"57.63120308839683\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">ReLU</text><text x=\"325.0\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">layer: 1 is next to the input, 10 next to the loss</text><text x=\"30\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">gradient norm, log scale</text></svg>", "caption": "Before any training, the gradient reaching each layer. Through sigmoids it shrinks at every layer it crosses; through ReLUs it keeps its size."}
```

**Through sigmoids, layer 1 receives a gradient of 2.05e-05, where layer 10 receives 8.44e-01**:
some 41,000 times smaller, and smaller again at every layer on the way down. With the same rate for
every layer, the first layers barely move, and they are the ones that turn pixels into features.
**After ten epochs the sigmoid network scores 0.106, which is chance for ten classes.** It has
learnt nothing.

**Through ReLUs, every layer's gradient stays between 5.89e-01 and 1.21e+00.** ReLU's local
derivative is exactly 1 wherever the unit is on, so it passes the gradient down without shrinking
it. The same ten layers reach 0.850 in the same ten epochs. That is still below the 0.939 that
`train.py`'s two layers had reached at epoch 10. Depth is not free even when the gradient arrives,
and lesson 12 shows a deeper network training worse than a shallow one, and what fixed it.

**The mirror image is the exploding gradient.** If the factors are above 1, because the weights are
large, the product grows layer by layer instead, and a step can throw the weights so far that
training diverges, often all the way to `nan`. The usual guard is gradient clipping, which caps the size of the gradient
before the step.

Most of what made deep networks trainable after 2010 is aimed at keeping that product near 1:

| | what it does | where |
| --- | --- | --- |
| **ReLU** | a local derivative of 1 on the active side | this lesson |
| **initialisation** | starting weights scaled so a signal keeps its size through a layer; `tinynet`'s `Linear` uses the spread √(2/n_in), chosen for ReLU | this lesson's `tinynet.py` |
| **normalisation** | rescaling each layer's outputs as training goes | lesson 8 |
| **residual connections** | a path around each block, along which the gradient arrives unmultiplied | lesson 12 |

Recurrent networks meet the same product along time rather than depth, one factor per step of the
sequence, and lesson 14 measures it there.
