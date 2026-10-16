---
title: Where the time goes, and the card that waits
version: 1
---

An epoch of training is two kinds of time taken in turns. **Waiting**: the program has asked the
loader for a batch and cannot go on until it arrives. **Computing**: the forward pass, the loss, the
backward pass and the step. A program that only measures the epoch sees the sum and cannot tell
which half to fix. Save this as `~/dl/waiting.py`, which clocks the two apart:

```schooling-example
{
  "language": "python",
  "file": "waiting.py",
  "parts": [
    {
      "code": "\"\"\"waiting: training on the warped digits, each epoch split into waiting for a batch and computing on it.\"\"\"\nimport time\n\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\nfrom torch.utils.data import DataLoader\n\nfrom dset import Digits\nfrom warp import Warp"
    },
    {
      "code": "def one_epoch(model, opt, loader):\n    wait = compute = 0.0\n    start = time.perf_counter()\n    for xb, yb in loader:\n        got = time.perf_counter()\n        loss = F.cross_entropy(model(xb), yb)\n        opt.zero_grad()\n        loss.backward()\n        opt.step()\n        done = time.perf_counter()\n        wait += got - start\n        compute += done - got\n        start = done\n    return wait, compute",
      "note": "Three clocks per batch. From the end of the last step to the moment the `for` hands over a batch is waiting; from there to the end of `opt.step()` is computing. The two add up to the epoch."
    },
    {
      "code": "if __name__ == \"__main__\":\n    torch.manual_seed(0)\n    train = Digits(\"train\", transform=Warp())\n    for workers in (0, 2):\n        model = nn.Sequential(nn.Flatten(), nn.Linear(1024, 256), nn.ReLU(), nn.Linear(256, 10))\n        opt = torch.optim.SGD(model.parameters(), lr=0.05)\n        loader = DataLoader(train, batch_size=32, shuffle=True, num_workers=workers,\n                            persistent_workers=workers > 0)\n        for e in (1, 2):\n            wait, compute = one_epoch(model, opt, loader)\n            print(f\"workers {workers}  epoch {e}  waiting {wait:.2f} s  computing {compute:.2f} s  \"\n                  f\"waiting share {wait / (wait + compute):.0%}\")",
      "note": "A dense network for the 32x32 images: `nn.Flatten` turns each 1x32x32 image into a row of 1,024, then one hidden layer of 256 units. Two epochs with no workers, then two with two workers."
    }
  ]
}
```

```
PENDING waiting
```

**With no workers, 38% of the second epoch was spent waiting**: 0.87 seconds of waiting against
1.42 of computing. The 0.87 is the warping, done in the main process between steps, and it is
close to the 0.84 seconds `workers.py` needed to read an epoch with no model at all. **With two
workers the waiting fell to 0.13 seconds, 8% of the epoch**, because the workers built the next
batches while the step ran, and the program found most of them ready when it asked. The computing
barely moved, 1.42 seconds against 1.49, so the whole gain is on the waiting side.

The computing column is large here because the model runs on the same four processors as
everything else, workers included. The share is a property of one program on one machine, and the
quick way to know where yours stands is to put these two clocks into it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 236\" role=\"img\" aria-label=\"Two timelines of a training epoch at the same scale. With no workers the main process alternates between waiting 29 ms for each batch and computing for 29 ms. With two workers the wait per batch falls to 6 ms, while computing takes 29 ms.\"><text x=\"118\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">no workers</text><rect x=\"130\" y=\"40\" width=\"550\" height=\"28\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"221.7\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"313.3\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"405.0\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"496.7\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"588.3\" y=\"43\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"680\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">29 + 29</text><text x=\"625\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ms a batch</text><text x=\"118\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">two workers</text><rect x=\"130\" y=\"110\" width=\"550\" height=\"28\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"148.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"240.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"258.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"350.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"368.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"460.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"478.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"570.0\" y=\"113\" width=\"16.8\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"588.3\" y=\"113\" width=\"90.2\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"680\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6 + 29</text><text x=\"632\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ms a batch</text><rect x=\"130\" y=\"189\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"152\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">waiting for a batch</text><rect x=\"330\" y=\"189\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"352\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">computing</text><text x=\"130\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the same 34 batches, average per batch; time runs to the right</text></svg>", "caption": "Where an epoch's time goes, from the second epoch of each run of waiting.py. The amber is the processor waiting for the loader; with workers, the batches are built while the step runs."}
```

## On a graphics card

On a card, the computing column is what shrinks. The step runs on hardware built for exactly those
matrix products, while the warping still runs on the processor, image by image, as it did here.
**The waiting does not shrink with it.** With no workers, the card computes for a few milliseconds
and then sits idle for as long as the processor takes to warp the next 32 images. With workers, the
step is now too short to hide much of the building behind it, so the wait per batch grows back.
Whatever the card, an epoch cannot take less time than the loader alone took in `workers.py`.

That is the situation the title of this lesson describes, and it is common: an expensive card,
bought to train faster, doing nothing for most of every second because the processor cannot feed
it. The fix is on the loader's side, not the card's: more workers while processors are free, a
cheaper transform, or the part of the transform that is not random done once and stored.

## Seeing it on a card

On a machine with an NVIDIA card, the driver ships a tool that shows how busy the card is. **This
course has no card, so the commands below were not run for it**:

```
nvidia-smi
nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv -l 1
```

The first prints one table of every card, its memory and the processes using it; the second
prints one line a second with the two numbers named. `utilization.gpu` is the share of the last
sample period during which the card was running anything at all. A training run that keeps it near
100% is computing most of the time; one that hovers at 30 or 40% is waiting for something most of
the time, and the loader is the first suspect. The number does not say how well the card is used
while it runs, only how often it runs, and `waiting.py`'s two clocks are what tell you why.
