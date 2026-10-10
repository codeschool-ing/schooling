---
title: Reading a training curve
version: 1
---

A training curve is usually read in one glance: going down is good, the last number is the result.
**Most of what a curve says is in the details that glance skips**: which line is measured when, how
much of the movement is noise, and where the improvement stopped being worth the time. This section
reads one run line by line.

Save this as `~/dl/curve.py`. It trains the usual network for forty epochs with `fit` printing every
one, then summarises the run:

```schooling-example
{
  "language": "python",
  "file": "curve.py",
  "parts": [
    {
      "code": "\"\"\"curve: one training run, every epoch printed, and the numbers that say where to stop.\"\"\"\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\ntrain, val, _ = digits.load()\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 64, rng), ReLU(), Linear(64, 10, rng))\nhistory = fit(net, SGD(net.params(), 0.3), train, val, epochs=40)",
      "note": "Forty epochs at a rate of 0.3, with `fit` printing every one of them. The rate is higher than the rest of this lesson uses so that the run reaches its plateau inside forty epochs."
    },
    {
      "code": "epoch, train_loss, val_loss, val_acc = (np.array(column) for column in zip(*history))\nprint(f\"lowest val loss  {val_loss.min():.4f} at epoch {epoch[val_loss.argmin()]}\")\nprint(f\"highest val acc  {val_acc.max():.3f} at epoch {epoch[val_acc.argmax()]}\")\nfor first in range(1, 41, 10):\n    window = slice(first - 1, first + 9)\n    print(f\"epochs {first:2d}-{first + 9:2d}  mean val loss {val_loss[window].mean():.4f}  \"\n          f\"mean val acc {val_acc[window].mean():.3f}\")",
      "note": "`history` holds one tuple per epoch, and `zip(*history)` turns it into four columns. The best single epoch is printed, and so is the mean over each block of ten, which reads past the noise of any one epoch."
    }
  ]
}
```

```
PENDING curve
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Training and validation loss for the 40 epochs of curve.py, on a logarithmic scale. Training loss starts at 1.29, above the validation loss of 0.60, and falls steadily to about 0.02. Validation loss falls quickly to about 0.11 by epoch 12, then flattens and wobbles between about 0.08 and 0.11 up and down from epoch to epoch, with its lowest point, 0.0774, at epoch 38.\"><path d=\"M80 270 L600 270\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 270 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M76 270.0 L600 270.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.01</text><path d=\"M76 238.60223504452495 L600 238.60223504452495\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"238.60223504452495\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.02</text><path d=\"M76 197.0966474332126 L600 197.0966474332126\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"197.0966474332126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.05</text><path d=\"M76 165.69888247773753 L600 165.69888247773753\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"165.69888247773753\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M76 134.30111752226247 L600 134.30111752226247\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"134.30111752226247\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M76 92.79552991095014 L600 92.79552991095014\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"92.79552991095014\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M76 61.39776495547508 L600 61.39776495547508\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"61.39776495547508\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M76 30.0 L600 30.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"80.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"200.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"333.33333333333337\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"466.6666666666667\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">30</text><text x=\"600.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">40</text><text x=\"340.0\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">epoch</text><text x=\"88\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">loss (log scale)</text><path d=\"M612 40 L636 40\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"612\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">train loss</text><path d=\"M612 86 L636 86\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"612\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">val loss</text></svg>", "caption": "The 40 epochs of `curve.py`, drawn from the lines it printed. Training loss keeps falling; validation loss stops following it after about epoch 20 and wobbles inside a band."}
```

## The first epoch: train loss above val loss

In epoch 1 the training loss is **1.2885 and the validation loss 0.6048**, less than half. The
network has not met an easier set. The two numbers are measured at different moments: `fit` averages
the training loss over the 34 batches of the epoch, while the weights were still changing, and
measures the validation loss once, at the end of the epoch, with the weights after all 34 steps. The
first batches of epoch 1 were scored by a network that knew nothing, and they pull the average up.

So the training loss lags by about half an epoch. It matters while the loss falls fast and stops
mattering as the curve flattens: by epoch 7 the two are 0.1492 and 0.1508. **Early on, a training
loss above the validation loss is the loop's bookkeeping, not a fact about the data.**

## How much of the movement is noise

The validation loss went from 0.1361 at epoch 9 to **0.1854 at epoch 10**, and back to 0.1248 at
epoch 11. Nothing happened at epoch 10. With a rate of 0.3 and batches of 32, each epoch ends at a
slightly different place, and 360 validation images are a small sample to measure it on.

Accuracy is coarser still. One validation image is 1/360 of the set, 0.0028, so **0.969 and 0.972
differ by one image**. The highest accuracy of the run, 0.981 at epoch 29, is followed by 0.967 at
epoch 30: five images gained, then five lost. Reading the best epoch as the best network reads a
lucky draw as a result.

The cure is to average. The blocks of ten epochs at the end of the output say what the single
epochs cannot:

| epochs | mean val loss | improvement on the block before |
| --- | --- | --- |
| 1–10 | 0.2497 | |
| 11–20 | 0.1133 | 0.1364 |
| 21–30 | 0.0975 | 0.0158 |
| 31–40 | 0.0868 | 0.0107 |

## Where to stop

**The training loss never stops falling**: 0.0198 at epoch 40, and it would keep going. It measures
how well the network fits the images it trains on, and with enough epochs it fits almost all of
them. Stopping is decided by the validation loss, and here it improved by 0.0107 over the last ten
epochs, while a single epoch moved it by more than that: from 0.0774 at epoch 38 to 0.0946 at
epoch 39. **When the improvement over a
block is smaller than the wobble inside it, more epochs are buying little**, and this run is at that
point somewhere between epoch 30 and 40.

The two validation measures also disagree about the best moment: the lowest loss is at epoch 38 and
the highest accuracy at epoch 29. That is ordinary, and it is why the rule for choosing an epoch has
to be decided before the run, not picked afterwards from whichever column looks better. Keeping the
weights of the best epoch, rather than the last, is early stopping, and lesson 7 writes it.

The gap between the two lines, 0.0198 against 0.0808 at epoch 40, is the network doing better on
images it has seen than on images it has not. **A gap on its own is normal.** A validation loss
that turns and climbs while the training loss keeps falling is the shape to worry about, and the
next section produces it.
