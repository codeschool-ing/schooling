---
title: The learning rate is the size of the step
version: 1
---

The rate of 1.0 in `descent.py` was not chosen by a rule. It happened to work. **The learning rate
sets how far each step goes, and the slope says nothing about how far is safe.** Here are four
rates on the same ten points, from the same starting weight. Save as `~/dl/rates.py`:

```python
# rates.py: the same descent at four learning rates, side by side
import numpy as np

from points import x, y

rates = [0.1, 1.0, 2.4, 2.8]
ws = np.zeros(len(rates))
print("step" + "".join(f"{'lr ' + str(lr):>10}" for lr in rates))
for step in range(16):
    print(f"{step:4d}" + "".join(f"{w:10.3f}" for w in ws))
    grads = np.array([np.mean(2 * x * (w * x - y)) for w in ws])
    ws = ws - np.array(rates) * grads

c = 2 * np.mean(x * x)
print(f"curvature {c:.2f}: a rate of {1 / c:.2f} lands in one step, above {2 / c:.2f} it diverges")
```

```
ana@vm:~/dl$ python rates.py
step    lr 0.1    lr 1.0    lr 2.4    lr 2.8
   0     0.000     0.000     0.000     0.000
   1     0.264     2.638     6.331     7.386
   2     0.507     3.244     0.962    -1.152
   3     0.732     3.384     5.515     8.718
   4     0.939     3.416     1.654    -2.692
   5     1.131     3.424     4.928    10.498
   6     1.308     3.425     2.152    -4.749
   7     1.471     3.426     4.506    12.876
   8     1.621     3.426     2.510    -7.499
   9     1.760     3.426     4.203    16.055
  10     1.888     3.426     2.767   -11.173
  11     2.007     3.426     3.984    20.302
  12     2.116     3.426     2.952   -16.084
  13     2.217     3.426     3.827    25.979
  14     2.310     3.426     3.085   -22.645
  15     2.396     3.426     3.715    33.564
curvature 0.77: a rate of 1.30 lands in one step, above 2.60 it diverges
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 340\" role=\"img\" aria-label=\"The weight against the step, for fifteen steps at four learning rates, with a dashed line at the bottom, 3.426. At 0.1 the weight climbs slowly and reaches 2.396 by step 15. At 1.0 it reaches the bottom within a few steps and stays. At 2.4 it jumps over the bottom to 6.331, back to 0.962, and zigzags inwards. At 2.8 each zigzag is wider than the last and the line leaves the chart at step 7.\"><path d=\"M60 290 L520 290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 290 L60 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"213.33333333333334\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"366.6666666666667\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"520.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">15</text><text x=\"46\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-6</text><text x=\"46\" y=\"246.66666666666666\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-3</text><text x=\"46\" y=\"203.33333333333331\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"46\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"46\" y=\"116.66666666666666\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><text x=\"46\" y=\"73.33333333333334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><text x=\"46\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"290.0\" y=\"326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">step</text><text x=\"54\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the weight w</text><path d=\"M60 203.33333333333331 L520 203.33333333333331\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M60 153.84666666666666 L520 153.84666666666666\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M60.0 203.3 L90.7 199.5 L121.3 196.0 L152.0 192.8 L182.7 189.8 L213.3 187.0 L244.0 184.4 L274.7 182.1 L305.3 179.9 L336.0 177.9 L366.7 176.1 L397.3 174.3 L428.0 172.8 L458.7 171.3 L489.3 170.0 L520.0 168.7\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M60.0 203.3 L90.7 165.2 L121.3 156.5 L152.0 154.5 L182.7 154.0 L213.3 153.9 L244.0 153.9 L274.7 153.8 L305.3 153.8 L336.0 153.8 L366.7 153.8 L397.3 153.8 L428.0 153.8 L458.7 153.8 L489.3 153.8 L520.0 153.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M60.0 203.3 L90.7 111.9 L121.3 189.4 L152.0 123.7 L182.7 179.4 L213.3 132.2 L244.0 172.2 L274.7 138.2 L305.3 167.1 L336.0 142.6 L366.7 163.4 L397.3 145.8 L428.0 160.7 L458.7 148.1 L489.3 158.8 L520.0 149.7\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M60.0 203.3 L90.7 96.6 L121.3 220.0 L152.0 77.4 L182.7 242.2 L213.3 51.7 L244.0 271.9 L273.1 30.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"532\" y=\"102.88888888888889\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">lr 2.4</text><text x=\"532\" y=\"118.88888888888889\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">oscillates</text><text x=\"532\" y=\"146.22222222222223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">lr 1.0</text><text x=\"532\" y=\"162.22222222222223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">about right</text><text x=\"532\" y=\"189.55555555555554\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor-dim)\">lr 0.1</text><text x=\"532\" y=\"205.55555555555554\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor-dim)\">too small</text><text x=\"284.66666666666663\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">lr 2.8</text><text x=\"284.66666666666663\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">diverges, leaves the chart</text><path d=\"M370 268.3333333333333 L394 268.3333333333333\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"400\" y=\"268.3333333333333\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the bottom, 3.426</text></svg>", "caption": "The same descent at four learning rates, drawn from the numbers `rates.py` printed."}
```

Four behaviours, one per column:

- **0.1 crawls.** After 15 steps it has reached 2.396 of the 3.426 it is heading for. It will get
  there, but each step is a fraction of what the ground allows.
- **1.0 arrives.** It is at 3.424 by step 5 and at 3.426 by step 7, and it stays there.
- **2.4 overshoots.** Its first step lands on 6.331, far past the bottom, and its second on 0.962,
  on the other side. Each crossing lands a little closer, and it settles in a zigzag.
- **2.8 diverges.** Every step overshoots by more than the error it set out to correct, so the
  swings grow: 33.564 by step 15, and the loss with them.

**For this model, where each behaviour starts is arithmetic.** The slope of the slope, the
**curvature**, is 0.77 everywhere on a parabola. Each step multiplies the distance to the bottom by
`1 - lr × 0.77`. At 0.1 that keeps 92% of the distance and at 1.0 it keeps 23%. At 2.4 it flips the
sign and keeps 85%, and at 2.8 it flips the sign and grows it. The last line printed the two
boundaries: 1.30 lands on the bottom in one step, and anything above 2.60 diverges.

A network has no single curvature. It has one for every direction through its weights, and they
change as the weights move, so nobody computes the safe rate for a real network. They try a few,
watch the loss, and keep the largest that does not blow up. **A loss that grows step after step is
the signature of a rate too high**, and lesson 5 is about choosing it well.
