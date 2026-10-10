---
title: Scaling the inputs
version: 1
---

A common belief is that the scale of the inputs is a detail the network absorbs: if the pixels are
16 times larger, the first layer learns weights 16 times smaller and nothing else changes. **The
weights would get there in the end, but the scale decides how training gets there, and it can stop
it from arriving at all.** The gradient of a first-layer weight is its input times the gradient
arriving from above, so inputs 16 times larger make every step on those weights 16 times larger, and
each of those steps moves the layer's sums 16 times as far again.

`digits.py` from lesson 1 divides the ink levels by 16. The program below undoes that and also tries
a third version, standardised, in which every pixel has mean 0 and standard deviation 1 over the
training set. It uses the `tinynet.py` from lesson 3 and the `optim.py` and `fit.py` from lesson 5,
which should be beside it in `~/dl`. Save it as `~/dl/scale.py`:

```schooling-example
{
  "language": "python",
  "file": "scale.py",
  "parts": [
    {
      "code": "\"\"\"scale: the same network and the same rates, on the digits at three scales.\"\"\"\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU, softmax_cross_entropy\n\n(x, y), (xv, yv), _ = digits.load()\nmean, std = x.mean(axis=0), x.std(axis=0)\nstd[std == 0] = 1\nscales = {\"0 to 16\": (x * 16, xv * 16),\n          \"0 to 1\": (x, xv),\n          \"standardised\": ((x - mean) / std, (xv - mean) / std)}",
      "note": "Three versions of the same images. `digits.py` divides by 16, so multiplying by 16 gives back the raw ink levels. Standardising moves each pixel to mean 0 and standard deviation 1, using statistics from the training set only. A few pixels are blank in every training image and have a deviation of 0, so they are divided by 1 instead."
    },
    {
      "code": "def make():\n    rng = np.random.default_rng(0)\n    return Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))",
      "note": "The same seed every time, so the three runs start from identical weights. Only the inputs differ."
    },
    {
      "code": "for name, (a, _) in scales.items():\n    net = make()\n    loss, _ = softmax_cross_entropy(net.forward(a), y)\n    print(f\"{name:13s} first-layer sums: std {net.layers[0].forward(a).std():6.2f}\"\n          f\"   loss before training {loss:.2f}\")",
      "note": "Before any training: how spread out the first layer's sums are, and the loss the untrained network scores."
    },
    {
      "code": "print(\"\\nval accuracy after 20 epochs of SGD\")\nprint(\"rate   \" + \"\".join(f\"{name:>14s}\" for name in scales))\nfor lr in (0.01, 0.1, 0.3, 1.0):\n    row = []\n    for a, b in scales.values():\n        net = make()\n        with np.errstate(all=\"ignore\"):\n            history = fit(net, SGD(net.params(), lr), (a, y), (b, yv), epochs=20, every=1000)\n        row.append(history[-1][3])\n    print(f\"{lr:<7}\" + \"\".join(f\"{acc:14.3f}\" for acc in row))",
      "note": "Twelve runs of lesson 5's `fit`, four rates by three scales. `every=1000` keeps it from printing each epoch, and `errstate` silences NumPy's warnings when a run overflows. The table keeps the last epoch's validation accuracy."
    }
  ]
}
```

```
ana@vm:~/dl$ python scale.py
0 to 16       first-layer sums: std  11.09   loss before training 15.42
0 to 1        first-layer sums: std   0.69   loss before training 2.45
standardised  first-layer sums: std   1.39   loss before training 2.77

val accuracy after 20 epochs of SGD
rate          0 to 16        0 to 1  standardised
0.01            0.947         0.897         0.900
0.1             0.942         0.956         0.958
0.3             0.089         0.969         0.969
1.0             0.111         0.978         0.978
```

**The raw pixels do damage before the first step.** The first layer's sums spread with a standard
deviation of 11.09 instead of 0.69, and the untrained network scores a loss of 15.42. A network that
guessed evenly among ten classes would score ln 10, about 2.30, so this one starts out confident and
wrong. tinynet's `Linear` draws its starting weights for inputs of about unit size, and inputs of 16
break that assumption at once.

The table needs reading with care. At rate 0.01 the raw pixels reach 0.947 against 0.897 for the
pixels between 0 and 1, which looks like a win for doing nothing. It is the larger steps: at a small
rate, the run whose steps are 16 times bigger gets further in 20 epochs. At 0.3 and 1.0 the raw run
ends at 0.089 and 0.111, about one right answer in ten, while the scaled one climbs to 0.969 and
0.978. **The scale of the inputs is part of the learning rate.** A rate tuned for one scale is wrong
for another, and the range of rates that work is narrower for the larger one.

The standardised column is close to the 0-to-1 column at every rate, because every pixel here is
measured in the same unit and dividing by 16 was already enough. Standardising earns its place when
the features come in different units, an amount in reais beside an age in years, where no single
rate suits both. Two rules from `machine-learning` carry over unchanged. The mean and the deviation
come from the training set and are applied as they are to validation and test, and they are saved
with the model, because a prediction made a month later needs the same transformation.

**Scaling the inputs fixes the first layer and nothing after it.** The inputs of the second layer are
the outputs of the first, their scale is whatever the weights make it, and it changes at every step.
The next section applies the same fix to every layer, during training.
