---
title: Money at every cut
version: 1
---

Lesson 10 judged the model at five cuts and found the most money at 0.2, not at the 0.278 the costs
pointed to. Before asking why, draw the whole picture: **net value at every cut**, on the test
months, from the chances lesson 10 saved. If `scores.csv` is not in `~/ml`, run lesson 10's
`scores.py` again; it takes a few seconds. Save this as `sweep.py`:

```python
# sweep.py
import pandas as pd

from feira import CREDIT, KEPT, SAVED, net_value

scores = pd.read_csv("scores.csv")
print(f"break-even cut: {CREDIT / (SAVED * KEPT):.3f}")
print("cut     sent   net value")
for cut in [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5]:
    send = scores["chance"] >= cut
    print(f"{cut:<5.2f} {send.sum():6,}  R$ {net_value(scores['churned'], send):8,.0f}")
```

```
ana@lab:~/ml$ python sweep.py
break-even cut: 0.278
cut     sent   net value
0.05   5,405  R$  -76,520
0.10   2,589  R$    1,848
0.15   1,695  R$   17,592
0.20   1,167  R$   23,448
0.25     853  R$   22,904
0.30     598  R$   19,280
0.35     439  R$   16,856
0.40     331  R$   14,840
0.45     248  R$   11,536
0.50     194  R$    9,088
```

Drawn at every hundredth instead of every twentieth, the same numbers make a hill:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 580 360\" role=\"img\" data-fig=\"l11-value-curve\" aria-label=\"Net value on the test months against the cut, from 0.05 to 0.5. The curve starts deep below zero, climbs steeply to a broad flat top between about 0.17 and 0.27, and slopes gently down to about R$ 9,000 at 0.5. A dashed line marks the break-even cut of 0.278, just right of the top.\"><path d=\"M92.0 300.0 L550.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M142.9 300.0 L142.9 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"142.9\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M244.7 300.0 L244.7 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"244.7\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M346.4 300.0 L346.4 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"346.4\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.3</text><path d=\"M448.2 300.0 L448.2 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"448.2\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M550.0 300.0 L550.0 304.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"550.0\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.5</text><text x=\"321.0\" y=\"331.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cut: send a credit above this chance</text><path d=\"M92.0 24.0 L92.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M88.0 300.0 L92.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−R$ 80,000</text><path d=\"M92.0 249.8 L550.0 249.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 249.8 L92.0 249.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"249.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−R$ 60,000</text><path d=\"M92.0 199.6 L550.0 199.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 199.6 L92.0 199.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"199.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−R$ 40,000</text><path d=\"M92.0 149.5 L550.0 149.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 149.5 L92.0 149.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"149.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">−R$ 20,000</text><path d=\"M92.0 99.3 L550.0 99.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 99.3 L92.0 99.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"99.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 0</text><path d=\"M92.0 49.1 L550.0 49.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M88.0 49.1 L92.0 49.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84.0\" y=\"49.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 20,000</text><text x=\"92.0\" y=\"10.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">net value, six months</text><path d=\"M92.0 99.3 L550.0 99.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M92.0 291.3 L97.1 247.7 L102.2 213.9 L107.3 182.4 L112.4 162.7 L117.4 146.2 L122.5 134.1 L127.6 122.5 L132.7 113.0 L137.8 101.7 L142.9 94.6 L148.0 88.7 L153.1 83.8 L158.2 77.9 L163.2 72.5 L168.3 66.7 L173.4 62.9 L178.5 59.7 L183.6 57.0 L188.7 57.5 L193.8 55.1 L198.9 52.2 L204.0 50.5 L209.0 49.7 L214.1 46.9 L219.2 45.5 L224.3 45.1 L229.4 44.0 L234.5 41.4 L239.6 39.4 L244.7 40.4 L249.8 41.8 L254.8 41.4 L259.9 41.7 L265.0 41.2 L270.1 40.8 L275.2 39.5 L280.3 38.6 L285.4 40.0 L290.5 40.7 L295.6 41.8 L300.6 42.1 L305.7 42.8 L310.8 44.0 L315.9 44.5 L321.0 45.6 L326.1 46.0 L331.2 47.7 L336.3 47.9 L341.4 49.0 L346.4 50.9 L351.5 52.5 L356.6 52.4 L361.7 53.0 L366.8 53.0 L371.9 54.6 L377.0 54.1 L382.1 54.9 L387.2 55.1 L392.2 56.5 L397.3 57.0 L402.4 57.1 L407.5 57.3 L412.6 58.4 L417.7 59.1 L422.8 59.1 L427.9 59.7 L433.0 59.5 L438.0 59.2 L443.1 60.6 L448.2 62.0 L453.3 62.6 L458.4 63.8 L463.5 64.1 L468.6 65.1 L473.7 65.1 L478.8 65.6 L483.8 65.7 L488.9 66.9 L494.0 69.1 L499.1 70.3 L504.2 70.8 L509.3 71.9 L514.4 72.1 L519.5 73.3 L524.6 73.3 L529.6 74.1 L534.7 74.9 L539.8 75.9 L544.9 76.9 L550.0 76.5\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M323.8 300.0 L323.8 26.5\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"323.8\" y=\"18.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">break-even 0.278</text><circle cx=\"550.0\" cy=\"76.5\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"542.0\" y=\"64.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the default, 0.5</text></svg>", "caption": "A flat top, a gentle slope to the right and a cliff to the left: a cut too low costs far more than a cut too high."}
```

Three things in it matter more than where the top is.

**The top is flat.** Every cut from about 0.17 to 0.27 makes between R$ 21,400 and R$ 23,900. A
difference of a few hundredths in the cut is worth a few hundred reais, and lesson 2's bootstrap
would not tell most of those apart. Arguing over 0.20 against 0.23 is arguing inside the noise.

**The sides are steep, and they are not alike.** To the right, the model sends fewer credits and
misses more leavers, so the money drains away slowly: 0.5 still makes R$ 9,088. To the left it falls
off a cliff. At 0.1 the credits reach so many stayers that the programme barely pays, and at 0.05
it loses R$ 76,520. **A cut too low is much more expensive than a cut too high**, because the stayers
outnumber the leavers fifteen to one.

**0.5 was never a choice.** It is what `predict` uses when nobody says otherwise, and it means
"send a credit when leaving is more likely than staying". Nothing in Feira em Casa's costs says
that. Here it leaves R$ 14,360 of the six months' R$ 23,448 on the table, and a different credit or a
different price would move the best cut somewhere else again.

So the question of this lesson is not "what is the best cut", which the test months answer only
after the fact. It is **where the cut should come from before anybody knows**, and the obvious
candidate is the break-even line that lesson 2 derived from the costs. That line rests on one
assumption: that a chance of 0.278 means what it says. The next section checks it.
