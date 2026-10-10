---
title: "Schedules: changing the rate as training goes"
version: 1
---

A fixed rate is a compromise. Early on, the weights are far from anything good and large steps get
them there quickly. Late in training the same steps keep them jittering around the minimum, because
the batch noise of the first section does not shrink near the bottom. **A schedule is a function from
the epoch to a rate**, and the loop sets `opt.lr` from it before each epoch. Save as
`~/dl/schedules.py`:

```schooling-example
{
  "language": "python",
  "file": "schedules.py",
  "parts": [
    {
      "code": "\"\"\"schedules: three ways to change the learning rate as the epochs go by, and a run with each.\"\"\"\nimport math\n\nimport numpy as np\n\nimport digits\nimport optim\nfrom fit import fit\nfrom tinynet import Linear, ReLU, Net\n\nEPOCHS, TOP = 20, 0.1",
      "note": "Twenty epochs, and a top rate of 0.1 for Adam: the rate where the sweep's Adam had already fallen from 0.969 to 0.894."
    },
    {
      "code": "def constant(epoch):\n    return TOP\n\n\ndef step_decay(epoch):\n    \"\"\"The top rate for 8 epochs, a tenth of it for the next 8, a hundredth after.\"\"\"\n    return TOP * 0.1 ** ((epoch - 1) // 8)",
      "note": "A schedule is a function from the epoch to a rate. Step decay divides the rate by ten at fixed epochs, here after 8 and after 16."
    },
    {
      "code": "def cosine(epoch, start=1, length=EPOCHS):\n    \"\"\"Half a cosine wave, from the top rate down towards zero.\"\"\"\n    return TOP * 0.5 * (1 + math.cos(math.pi * (epoch - start) / length))",
      "note": "Cosine decay slides from the top rate towards zero along half a cosine wave: slowly at first, fastest in the middle, slowly again at the end."
    },
    {
      "code": "def warmup_cosine(epoch, warm=3):\n    \"\"\"A straight climb for `warm` epochs, then the cosine over what is left.\"\"\"\n    if epoch <= warm:\n        return TOP * epoch / warm\n    return cosine(epoch, start=warm, length=EPOCHS - warm + 1)",
      "note": "Warm-up climbs from a third of the rate to all of it over three epochs, then hands over to the cosine. The first steps of a fresh network are its largest and least reliable, and warm-up keeps them small."
    },
    {
      "code": "SCHEDULES = [constant, step_decay, cosine, warmup_cosine]\nprint(\"epoch\" + \"\".join(f\"{s.__name__:>15}\" for s in SCHEDULES))\nfor epoch in range(1, EPOCHS + 1):\n    print(f\"{epoch:5d}\" + \"\".join(f\"{s(epoch):15.5f}\" for s in SCHEDULES))",
      "note": "The four schedules as numbers, one row per epoch."
    },
    {
      "code": "train, val, _ = digits.load()\nfor schedule in SCHEDULES:\n    rng = np.random.default_rng(0)\n    net = Net(Linear(64, 32, rng), ReLU(), Linear(32, 10, rng))\n    opt = optim.Adam(net.params(), lr=TOP)\n    for epoch in range(1, EPOCHS + 1):\n        opt.lr = schedule(epoch)\n        history = fit(net, opt, train, val, epochs=1, seed=epoch, every=100)\n    val_loss, val_acc = history[-1][2:]\n    print(f\"Adam at {TOP} with {schedule.__name__:<14} val loss {val_loss:.4f}  val acc {val_acc:.3f}\")",
      "note": "The same network and the same seed four times. Before each epoch the schedule sets `opt.lr`, and `fit` runs that one epoch; `seed=epoch` gives every epoch a different shuffle, as one long call to `fit` would."
    }
  ]
}
```

```
ana@vm:~/dl$ python schedules.py
epoch       constant     step_decay         cosine  warmup_cosine
    1        0.10000        0.10000        0.10000        0.03333
    2        0.10000        0.10000        0.09938        0.06667
    3        0.10000        0.10000        0.09755        0.10000
    4        0.10000        0.10000        0.09455        0.09924
    5        0.10000        0.10000        0.09045        0.09698
    6        0.10000        0.10000        0.08536        0.09330
    7        0.10000        0.10000        0.07939        0.08830
    8        0.10000        0.10000        0.07270        0.08214
    9        0.10000        0.01000        0.06545        0.07500
   10        0.10000        0.01000        0.05782        0.06710
   11        0.10000        0.01000        0.05000        0.05868
   12        0.10000        0.01000        0.04218        0.05000
   13        0.10000        0.01000        0.03455        0.04132
   14        0.10000        0.01000        0.02730        0.03290
   15        0.10000        0.01000        0.02061        0.02500
   16        0.10000        0.01000        0.01464        0.01786
   17        0.10000        0.00100        0.00955        0.01170
   18        0.10000        0.00100        0.00545        0.00670
   19        0.10000        0.00100        0.00245        0.00302
   20        0.10000        0.00100        0.00062        0.00076
Adam at 0.1 with constant       val loss 0.2262  val acc 0.950
Adam at 0.1 with step_decay     val loss 0.0681  val acc 0.978
Adam at 0.1 with cosine         val loss 0.1713  val acc 0.953
Adam at 0.1 with warmup_cosine  val loss 0.0966  val acc 0.964
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"The learning rate of four schedules over 20 epochs, from 0 to 0.1. Constant stays at 0.1. Step decay holds 0.1 for 8 epochs, drops to 0.01 for 8 and to 0.001 for the last 4. Cosine starts at 0.1 and curves down to near zero by epoch 20. Warm-up and cosine climbs in a straight line from 0.033 to 0.1 over the first three epochs, then follows its own cosine down to near zero.\"><path d=\"M80 240 L560 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 240 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"70\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.05</text><text x=\"70\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.1</text><text x=\"80.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"181.05263157894737\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"307.36842105263156\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"433.6842105263158\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">15</text><text x=\"560.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"320.0\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">epoch</text><text x=\"88\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">learning rate</text><path d=\"M80.0 30.0 L105.3 30.0 L130.5 30.0 L155.8 30.0 L181.1 30.0 L206.3 30.0 L231.6 30.0 L256.8 30.0 L282.1 30.0 L307.4 30.0 L332.6 30.0 L357.9 30.0 L383.2 30.0 L408.4 30.0 L433.7 30.0 L458.9 30.0 L484.2 30.0 L509.5 30.0 L534.7 30.0 L560.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M580 50 L606 50\" stroke=\"var(--paper-dim)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"612\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">constant</text><path d=\"M80.0 30.0 L80.0 30.0 L105.3 30.0 L130.5 30.0 L155.8 30.0 L181.1 30.0 L206.3 30.0 L231.6 30.0 L256.8 30.0 L269.5 30.0 L269.5 219.0 L282.1 219.0 L307.4 219.0 L332.6 219.0 L357.9 219.0 L383.2 219.0 L408.4 219.0 L433.7 219.0 L458.9 219.0 L471.6 219.0 L471.6 237.9 L484.2 237.9 L509.5 237.9 L534.7 237.9 L560.0 237.9\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M580 76 L606 76\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"612\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">step_decay</text><path d=\"M80.0 30.0 L105.3 31.3 L130.5 35.1 L155.8 41.4 L181.1 50.1 L206.3 60.7 L231.6 73.3 L256.8 87.3 L282.1 102.6 L307.4 118.6 L332.6 135.0 L357.9 151.4 L383.2 167.4 L408.4 182.7 L433.7 196.7 L458.9 209.3 L484.2 219.9 L509.5 228.6 L534.7 234.9 L560.0 238.7\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M580 102 L606 102\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"612\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cosine</text><path d=\"M80.0 170.0 L105.3 100.0 L130.5 30.0 L155.8 31.6 L181.1 36.3 L206.3 44.1 L231.6 54.6 L256.8 67.5 L282.1 82.5 L307.4 99.1 L332.6 116.8 L357.9 135.0 L383.2 153.2 L408.4 170.9 L433.7 187.5 L458.9 202.5 L484.2 215.4 L509.5 225.9 L534.7 233.7 L560.0 238.4\" stroke=\"var(--paper)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M580 128 L606 128\" stroke=\"var(--paper)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"612\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">warmup_cosine</text></svg>", "caption": "The four schedules of `schedules.py`, drawn from the table it printed."}
```

All four runs use Adam at a top rate of 0.1, which the sweep showed to be too high. **What the
schedule did with that too-high rate is the result**:

| schedule | val loss | val acc |
| --- | --- | --- |
| constant | 0.2262 | 0.950 |
| step decay | 0.0681 | 0.978 |
| cosine | 0.1713 | 0.953 |
| warm-up then cosine | 0.0966 | 0.964 |

**Step decay did best here, and the reason is in the table of rates.** It spent eight epochs at 0.1,
eight at 0.01 and the last four at 0.001, and the sweep had already found 0.01 to be among Adam's
best rates. The cosine is still at 0.05782 at epoch 10 and only drops below 0.01 in the last four
epochs, so it spent most of the run too high. **Warm-up helped the cosine**: the same curve with a
gentler first three epochs ended at a validation loss of 0.0966 instead of 0.1713.

Read the constant row against the sweep. The configuration is the same, Adam at 0.1 for 20 epochs,
and the sweep printed 0.894 where this prints 0.950. The only change is the shuffle: `sweep.py` drew
one order of batches per epoch from a single generator, and this loop gives every epoch its own seed.
**A different order of the same batches moved the accuracy by 0.056**, which is why no row of this
table settles anything alone.

Which schedule to use is mostly convention, and the conventions are worth knowing:

- **Step decay** is the classic one. The original ResNets were trained at 0.1, divided by ten twice as
  training went on, and lesson 12 is about those networks.
- **Cosine** has nothing to choose but its length, which is why it is a common default now.
- **Warm-up followed by a decay** is how transformers are trained, because Adam's first steps on a
  fresh, deep network are the least reliable ones. Lesson 15 builds one.
- **Lowering the rate when the validation loss stops improving** reacts to the run instead of
  following a plan. PyTorch calls it `ReduceLROnPlateau`.

**A schedule is not a way out of choosing the rate.** The step decay won because its later epochs
ran at rates the sweep had already found good. The rate came first, and the schedule only decided
when to use which.
