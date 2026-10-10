---
title: Early stopping, and keeping the best weights
version: 1
---

The cheapest cure needs no new layer and no new term in the loss. `overfit.py` already printed it:
the validation loss was lowest at epoch 40, and every epoch after that made the network worse at the
thing it is for. **Early stopping keeps the weights from the best epoch and stops training once it is
clear the best is behind.**

Both halves matter, and the second is the one people forget. Stopping when the loss has not improved
for a while ends the run late, by definition, after the "while" has passed. If you then keep the
network as it is, you keep the weights from those last worse epochs. The best ones have to be saved
when they happen, as a copy, and put back at the end.

Save as `~/dl/early.py`:

```schooling-example
{
  "language": "python",
  "file": "early.py",
  "parts": [
    {
      "code": "\"\"\"early: one epoch at a time, keeping the weights of the best one.\"\"\"\nimport small\nfrom fit import evaluate, fit\nfrom optim import SGD\n\ntrain, val = small.data()\nnet = small.wide()\nopt = SGD(net.params(), lr=0.2)\nbest_loss, best_epoch, patience = float(\"inf\"), 0, 20",
      "note": "The same network, data and optimiser as `overfit.py`. `patience` is how many epochs without a new best the loop will wait."
    },
    {
      "code": "for epoch in range(1, 301):\n    _, _, loss, acc = fit(net, opt, train, val, epochs=1, seed=epoch, every=2)[0]\n    if loss < best_loss:\n        best_loss, best_epoch = loss, epoch\n        best = [p.copy() for p, _ in net.params()]\n    elif epoch - best_epoch == patience:\n        print(f\"stopped at epoch {epoch}: no improvement for {patience} epochs\")\n        break\nprint(f\"last epoch {epoch}  val loss {loss:.4f}  val acc {acc:.3f}\")",
      "note": "`fit` for one epoch at a time, each with its own shuffling seed, so the loop can look at the validation loss after every epoch. Its history has one row, and the third and fourth fields are the validation loss and accuracy. `every=2` on a one-epoch run prints nothing. A new best is copied, because `net.params()` hands back the arrays the optimiser keeps changing."
    },
    {
      "code": "for (p, _), saved in zip(net.params(), best):\n    p[...] = saved\nloss, acc = evaluate(net, *val)\nprint(f\"best epoch {best_epoch}  val loss {loss:.4f}  val acc {acc:.3f}\")",
      "note": "Stopping is half of it. The other half puts the saved arrays back, in place, so the network you keep is the one from the best epoch and not the last."
    }
  ]
}
```

```
PENDING early
```

The run trains epoch by epoch with its own shuffling seeds, so its epochs are not the same as
`overfit.py`'s, and its lowest loss came at epoch 33 rather than 40. It waited the 20 epochs of
patience and stopped at 53, where the validation loss was 0.2996. Putting the saved weights back gives
0.2926, with 0.911 accuracy, against 0.3281 and 0.903 for the network that trained all 300 epochs.
It also took 53 epochs of work instead of 300.

**Patience is a trade.** Validation loss is noisy from one epoch to the next, so a patience of 1 stops at
the first unlucky epoch; a patience of 100 here would have run to the end. Twenty is a common first
choice for a run of a few hundred epochs.

**The copy is the line that is easy to get wrong.** `best = [p for p, _ in net.params()]` without
`.copy()` keeps references to the very arrays the optimiser keeps changing, so at the end "the best
weights" are the last ones and the restore does nothing, silently. The numbers would then match the
last epoch's exactly, which is the way to tell.

Early stopping uses the validation set to choose when to stop, so it is one more decision fitted to
those 360 images. The test set that `digits.py` set aside in lesson 1 is still untouched, and is what
measures the network you finally keep.
