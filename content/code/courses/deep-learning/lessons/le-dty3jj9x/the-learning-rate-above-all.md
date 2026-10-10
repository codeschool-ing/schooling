---
title: The learning rate above all
version: 1
---

Choosing the optimiser feels like the big decision, and it is the smaller one. **If you can tune
one setting, tune the learning rate.** This section sweeps ten rates for each of the three
optimisers on the same network and the same data, 30 runs of 20 epochs each, and compares what the
choice of optimiser bought with what the choice of rate did. Save as `~/dl/sweep.py`:

```schooling-example
{
  "language": "python",
  "file": "sweep.py",
  "parts": [
    {
      "code": "\"\"\"sweep: ten learning rates for each of three optimisers, 20 epochs each.\"\"\"\nimport numpy as np\n\nimport digits\nimport optim\nfrom fit import fit\nfrom tinynet import Linear, ReLU, Net\n\nRATES = [0.0001, 0.0003, 0.001, 0.003, 0.01, 0.03, 0.1, 0.3, 1.0, 3.0]\ntrain, val, _ = digits.load()",
      "note": "Ten rates, each about three times the one before, from 0.0001 to 3. A rate is searched on that kind of scale, because what matters is its order of magnitude."
    },
    {
      "code": "print(\"rate      \" + \"\".join(f\"{r:>7g}\" for r in RATES))\nfor name in (\"SGD\", \"Momentum\", \"Adam\"):\n    row = []\n    for lr in RATES:\n        rng = np.random.default_rng(0)\n        net = Net(Linear(64, 32, rng), ReLU(), Linear(32, 10, rng))\n        opt = getattr(optim, name)(net.params(), lr)",
      "note": "Every run starts from the same weights, drawn with seed 0, so the only difference between two runs is the optimiser and its rate. `getattr(optim, name)` picks the class by its name."
    },
    {
      "code": "        with np.errstate(all=\"ignore\"):\n            history = fit(net, opt, train, val, epochs=20, every=100)\n        row.append(history[-1][3])\n    print(f\"{name:<10}\" + \"\".join(f\"{acc:7.3f}\" for acc in row))",
      "note": "A rate that is too high throws the network so far that the probability of the right digit rounds to zero, its logarithm is minus infinity, and NumPy warns about it. `errstate` silences those warnings, and the accuracy in the table says what happened. `every=100` keeps `fit` quiet for the 20 epochs."
    }
  ]
}
```

```
PENDING sweep
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Validation accuracy against learning rate, on a logarithmic axis from 0.0001 to 3, for three optimisers. Each curve rises from near chance at tiny rates to a peak around 0.97 or 0.98 and falls back to chance when the rate is too high. Adam peaks at 0.003 to 0.03, momentum at 0.1 and plain SGD at 1, so the three peaks are about the same height and sit a factor of ten or more apart.\"><path d=\"M80 260 L640 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 260 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.0</text><text x=\"70\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M80 145.0 L640 145.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.0</text><path d=\"M80 30.0 L640 30.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0001</text><text x=\"640.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"360.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">learning rate</text><text x=\"88\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">validation accuracy after 20 epochs</text><path d=\"M80 237.0 L640 237.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"646\" y=\"237.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">chance</text></svg>", "caption": "The table of `sweep.py` drawn: the same hill three times, of about the same height, at three different rates."}
```

**The rate moved the result by about 87 points; the optimiser moved it by about one.** Along any
row, the rate takes the network from chance to the top: SGD goes from 0.136 at 0.0001 to 0.981 at 1,
and down to 0.111 at 3. Down the columns of their best rates, the three optimisers reach 0.981, 0.978
and 0.969. A network trained with the wrong optimiser at a good rate beats one trained with the
right optimiser at a bad rate, and by a wide margin.

**Each optimiser has its best rate in a different place.** Plain SGD peaks at 1, momentum at 0.1 and
Adam at 0.03. Momentum's tenfold shift is the one `optim.py` predicted: a steady gradient makes its
velocity ten times the gradient, so the same step needs a tenth of the rate. Adam's rate measures
something else altogether, the size of a step. So **a rate does not travel between optimisers**:
SGD at Adam's default of 0.001 reaches 0.311, and Adam at momentum's 0.1 reaches 0.894.

**Too high fails abruptly, too low fails slowly.** Every row ends in a cliff. Momentum goes from 0.978
at 0.1 to 0.950 at 0.3 and to 0.100 at 1, which is a network guessing among ten digits. At the other
end, SGD at 0.0001 is not broken. It has not arrived yet, and more epochs would take it further, at a
cost nobody needs to pay.

**And a default is a place to start.** Adam at 0.001, the default almost every library ships, gives
0.933 here, where 0.03 gives 0.969.

Two things to take away as a method:

- **Search the rate on a ratio scale**, each value about three times the last, as `RATES` does. 0.01
  and 0.02 are close; 0.0001 and 0.0002 are just as close.
- **The best rate sits one or two steps below the first one that breaks.** SGD peaks at 1 and breaks
  at 3, momentum peaks at 0.1 and breaks at 1, and Adam peaks at 0.03 and breaks at 0.3.

One honest limit. These are single runs, one seed each, of one small network. A difference of a point
or less between two cells could come from the shuffle as easily as from the setting, and the next
section shows one such difference. Lesson 18 measures how far a seed alone moves these numbers.
