---
title: Making a network overfit, on purpose
version: 1
---

Overfitting is usually pictured as a curve that turns: training goes well, then the validation
accuracy starts to fall. **On these digits the accuracy barely moves, and the loss is what turns.**
To see that clearly you need a network that overfits hard, so this section builds one on purpose and
every later section tries to cure it.

The recipe is the one `machine-learning` warned about: far more parameters than examples. Take only
the first 100 of the 1,077 training images, keep all 360 validation images so the measurement stays
honest, and give the network two hidden layers of 512 units. Save as `~/dl/small.py`:

```schooling-example
{
  "language": "python",
  "file": "small.py",
  "parts": [
    {
      "code": "\"\"\"small: 100 training images, and a network far too big for them.\"\"\"\nimport numpy as np\n\nimport digits\nfrom tinynet import Linear, Net, ReLU",
      "note": "Everything else in this lesson imports this file, so every run starts from the same data and the same network."
    },
    {
      "code": "def data(n=100):\n    \"\"\"The first n training images, and the whole validation set.\"\"\"\n    (x, y), val, _ = digits.load()\n    return (x[:n], y[:n]), val",
      "note": "The first 100 of the 1,077 training images from the `digits.py` of lesson 1, about ten of each digit. The validation set stays whole at 360, so the measurement is as good as before and only the training is starved."
    },
    {
      "code": "def wide(seed=0):\n    \"\"\"64 inputs, two hidden layers of 512 units, 10 outputs.\"\"\"\n    rng = np.random.default_rng(seed)\n    return Net(Linear(64, 512, rng), ReLU(),\n               Linear(512, 512, rng), ReLU(),\n               Linear(512, 10, rng))",
      "note": "Two hidden layers of 512 units, built from the `tinynet.py` of lesson 3. The seed fixes the starting weights, so a run with the same seed starts from the same network."
    }
  ]
}
```

Then train it for 300 epochs with the `fit` and `SGD` of lesson 5. Save as `~/dl/overfit.py`:

```schooling-example
{
  "language": "python",
  "file": "overfit.py",
  "parts": [
    {
      "code": "\"\"\"overfit: the wide network on 100 images, for 300 epochs.\"\"\"\nimport small\nfrom fit import evaluate, fit\nfrom optim import SGD\n\ntrain, val = small.data()\nnet = small.wide()\nprint(\"parameters:\", sum(p.size for p, _ in net.params()))",
      "note": "The network and the data from `small.py`, and a count of every weight and bias in it."
    },
    {
      "code": "history = fit(net, SGD(net.params(), lr=0.2), train, val, epochs=300, every=20)\nprint(\"train acc\", evaluate(net, *train)[1])\nbest = min(history, key=lambda h: h[2])\nprint(f\"lowest val loss {best[2]:.4f} at epoch {best[0]}\")",
      "note": "Plain SGD at a rate of 0.2 through the `fit` of lesson 5, printing every 20 epochs. At the end, accuracy on the training images themselves, and the epoch whose validation loss was lowest, read from the history `fit` returns."
    }
  ]
}
```

```
PENDING overfit
```

**301,066 parameters for 100 images** is about three thousand numbers per example, enough to store
every picture rather than learn what a 3 looks like. And it does: train accuracy is 1.0, and the
training loss ends at 0.0010, three hundred times smaller than at epoch 20.

The validation loss tells a different story. It is lowest at epoch 40, at 0.2942, and from there it
climbs almost every time it is printed, to 0.3281 at epoch 300. The validation accuracy, over the same
260 epochs, wanders between 0.900 and 0.908 and ends where it was.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Two plots of the run printed above, at every twentieth epoch. On the left the training loss falls from 0.0300 at epoch 20 to 0.0010 at epoch 300. On the right, on its own scale, the validation loss falls to 0.3100 at epoch 20 and then climbs to 0.3300 at epoch 300.\"><text x=\"210\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">train loss</text><path d=\"M90 240 L330 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 40 L90 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"84\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.000</text><path d=\"M90 240.0 L330 240.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.018</text><path d=\"M90 140.0 L330 140.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.035</text><path d=\"M90 40.0 L330 40.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"90.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"170.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"250.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"330.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><text x=\"210.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">epoch</text><path d=\"M106.0 68.6 L330.0 234.3\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"106.0\" cy=\"68.6\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"330.0\" cy=\"234.3\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><text x=\"550\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">validation loss</text><path d=\"M430 240 L670 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M430 40 L430 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"424\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.290</text><path d=\"M430 240.0 L670 240.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"424\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.310</text><path d=\"M430 140.0 L670 140.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"424\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.330</text><path d=\"M430 40.0 L670 40.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"430.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"510.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"590.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"670.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><text x=\"550.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">epoch</text><path d=\"M446.0 140.0 L670.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"446.0\" cy=\"140.0\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"670.0\" cy=\"40.0\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"446.0\" cy=\"140.0\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"446.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lowest: 20</text></svg>", "caption": "The same run on two scales. The training loss keeps falling to almost nothing; the validation loss bottoms out early and spends the rest of the run climbing."}
```

**Both numbers are right, and they measure different things.** Accuracy asks only whether the
largest output is the right digit. Cross-entropy, the loss of lesson 4, also asks how much probability
went to the right digit. After epoch 40 the network keeps pushing its outputs towards certainty, on the
training images it has memorised and on the validation images it gets wrong alike, and a confident
wrong answer costs more loss than an unsure one. The roughly 35 validation images it misses do not
change, but it misses them with more conviction every epoch.

That is the overfitting this lesson works on: a training loss heading to zero, a gap of about ten
points between training and validation accuracy, and a validation loss that rose after epoch 40. Lesson 6
showed how to read that shape from a curve. The next four sections are four ways to change it, each
measured against this run.
