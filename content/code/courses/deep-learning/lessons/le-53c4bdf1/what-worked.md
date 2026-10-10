---
title: What worked, run side by side
version: 1
---

Each section measured one cure against the run of `overfit.py`, but with a different loop, so the
numbers are not quite comparable. This program runs them all through the same loop, adds a control
that changes nothing but the seed, and then puts the four cures together. Save as `~/dl/compare.py`:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "\"\"\"compare: every cure on the same 100 images, alone and together, and then more data.\"\"\"\nimport small\nfrom decay import SGDDecay\nfrom dropout import wide_dropout\nfrom fit import evaluate, fit\nfrom shift import shifted",
      "note": "This lesson's own files, imported. The `if __name__ == \"__main__\":` in each of them is what stops their experiments running again here."
    },
    {
      "code": "def run(net, decay=0.0, shift=False, early=False, seed=0, n=100):\n    \"\"\"300 epochs of SGD at 0.2; the final weights, or the best epoch's with early stopping.\"\"\"\n    train, val = small.data(n)\n    if shift:\n        train = shifted(*train)\n    opt = SGDDecay(net.params(), lr=0.2, decay=decay)\n    best_loss, best_epoch = float(\"inf\"), 0\n    for epoch in range(1, 301):\n        loss = fit(net, opt, train, val, epochs=1, seed=seed * 1000 + epoch, every=2)[0][2]\n        if loss < best_loss:\n            best_loss, best_epoch = loss, epoch\n            best = [p.copy() for p, _ in net.params()]\n        elif early and epoch - best_epoch == 20:\n            break\n    if early:\n        for (p, _), saved in zip(net.params(), best):\n            p[...] = saved\n        epoch = best_epoch\n    return epoch, *evaluate(net, *val)",
      "note": "One function for every run: SGD with an optional decay, an optional fivefold training set, and the best-epoch loop of `early.py`, which stops and restores only when `early` is set. Without it the run goes the full 300 epochs and keeps the last weights."
    },
    {
      "code": "runs = [\n    (\"nothing\", lambda: run(small.wide())),\n    (\"nothing, seed 1\", lambda: run(small.wide(seed=1), seed=1)),\n    (\"weight decay 0.001\", lambda: run(small.wide(), decay=0.001)),\n    (\"dropout 0.5\", lambda: run(wide_dropout(0.5))),\n    (\"early stopping\", lambda: run(small.wide(), early=True)),\n    (\"shifted images\", lambda: run(small.wide(), shift=True)),\n    (\"all four\", lambda: run(wide_dropout(0.5), decay=0.001, shift=True, early=True)),\n    (\"all 1,077 images\", lambda: run(small.wide(), n=1077)),\n]\nprint(f\"{'':20s} {'epoch':>5s} {'val loss':>9s} {'val acc':>8s}\")\nfor name, go in runs:\n    epoch, loss, acc = go()\n    print(f\"{name:20s} {epoch:5d} {loss:9.4f} {acc:8.3f}\", flush=True)",
      "note": "Eight runs. The second changes nothing but the seed, which sets the starting weights and the order of the batches: it measures how far chance alone moves these numbers. The last uses no cure at all and the whole training set of `digits.py`, ten times the images."
    }
  ]
}
```

```
PENDING compare
```

**Read the control first.** Changing only the seed moved accuracy from 0.900 to 0.908 and loss from
0.3305 to 0.3112. Any single cure that moves the numbers by less than that has not shown it did
anything, because chance alone moves them that far. Lesson 18 measures that spread over five seeds, and
it is the habit this table asks for.

| run | what it changed | against `nothing` |
| --- | --- | --- |
| weight decay 0.001 | weights pulled towards zero | loss 0.3006 and accuracy 0.906, both inside what the seed moves |
| dropout 0.5 | half the hidden units off at each step | accuracy 0.919, but loss up to 0.3766 |
| early stopping | the weights of epoch 33 | loss 0.2926 and accuracy 0.911, in 53 epochs |
| shifted images | five times the training images | accuracy 0.933, the best alone, with loss 0.3441 |
| all four | all of the above | **loss 0.2439 and accuracy 0.944**, kept from epoch 53 |

**Together they did what none did alone.** The combination has the lowest loss and the highest
accuracy in the table, 0.944 against 0.900, which is 16 more images out of 360 and four times what the
seed moved. The cures act on different things: augmentation gives more examples, dropout and decay
make the network less able to memorise them, and early stopping keeps the moment before the confidence
grows.

**What does not carry over is the ranking.** On this problem, with 100 images, augmentation did the most
and weight decay the least. With a million images, a different network or another learning rate, the
order can change, and the values chosen here, 0.001 and 0.5 and a patience of 20, were tried rather
than known. What carries over is the method: one baseline, one change at a time, one control for
chance, and the validation set as the judge.

**And the strongest cure is not in the table:** more real data. With all 1,077 training images, every
lesson so far has reached validation accuracy well above anything here, with no cure at all. Every
technique in this lesson is a way of doing with less data what more data does on its own.
