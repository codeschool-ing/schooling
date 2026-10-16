---
title: Whether a chance means what it says
version: 1
---

The break-even line works like this. A credit costs R$ 40 and is worth R$ 144 when it reaches a
leaver, so it pays for itself when the chance of leaving is above 40 / 144 = 0.278. **That
arithmetic is only right if the chances are honest**: among all the subscribers the model gives a
chance of 0.278, about 27.8% must really leave. A model with that property is **calibrated**.

Nothing in fitting a model promises it. A model is trained to rank and to separate, and its
chances can be too high everywhere, too low everywhere, or squeezed towards the middle, while the
ranking stays as good as ever. The AUC of lesson 10 cannot see any of that, because it only looks at
the order.

The check is direct: sort the test rows by chance, cut them into ten groups of equal size, and in
each group compare the average chance with the share that really left. scikit-learn does the
grouping in `calibration_curve`. Save this as `reliability.py`:

```python
# reliability.py
import pandas as pd
from sklearn.calibration import calibration_curve

scores = pd.read_csv("scores.csv")
happened, said = calibration_curve(scores["churned"], scores["chance"],
                                   n_bins=10, strategy="quantile")
print("tenth   model said   happened")
for tenth, (s, h) in enumerate(zip(said, happened), start=1):
    print(f"{tenth:5}   {s:10.3f}   {h:8.3f}")
print(f"all     {scores['chance'].mean():10.3f}   {scores['churned'].mean():8.3f}")
```

```
ana@lab:~/ml$ python reliability.py
tenth   model said   happened
    1        0.010      0.010
    2        0.013      0.012
    3        0.016      0.015
    4        0.019      0.026
    5        0.023      0.028
    6        0.028      0.028
    7        0.034      0.040
    8        0.046      0.067
    9        0.074      0.093
   10        0.247      0.292
all          0.051      0.061
```

`strategy="quantile"` makes the groups equal in size; the default makes them equal in width, which
on a rare class puts almost every row in the first group. Drawn, each group is a point, and a
calibrated model's points sit on the diagonal:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 380\" role=\"img\" data-fig=\"l11-reliability\" aria-label=\"A reliability chart. Each of ten points is a tenth of the test rows: across, the average chance the model gave; up, the share that really cancelled. The dashed diagonal is where an honest model sits. The low points sit on it; the top three sit above it, the last at 0.247 across and 0.292 up.\"><path d=\"M80.0 330.0 L420.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 330.0 L80.0 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M136.7 330.0 L136.7 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"136.7\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.05</text><path d=\"M193.3 330.0 L193.3 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"193.3\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.10</text><path d=\"M250.0 330.0 L250.0 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"250.0\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.15</text><path d=\"M306.7 330.0 L306.7 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"306.7\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.20</text><path d=\"M363.3 330.0 L363.3 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"363.3\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.25</text><path d=\"M420.0 330.0 L420.0 334.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"420.0\" y=\"343.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.30</text><text x=\"250.0\" y=\"361.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">what the model said</text><path d=\"M80.0 30.0 L80.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 330.0 L80.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"330.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M80.0 280.0 L420.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 280.0 L80.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.05</text><path d=\"M80.0 230.0 L420.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 230.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.10</text><path d=\"M80.0 180.0 L420.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 180.0 L80.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.15</text><path d=\"M80.0 130.0 L420.0 130.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 130.0 L80.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.20</text><path d=\"M80.0 80.0 L420.0 80.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 80.0 L80.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.25</text><path d=\"M80.0 30.0 L420.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 30.0 L80.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.30</text><text x=\"80.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">what happened</text><path d=\"M80.0 330.0 L420.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"314.7\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">honest</text><path d=\"M90.9 320.1 L94.6 317.6 L98.1 314.7 L101.4 304.0 L105.9 301.6 L111.3 301.6 L118.2 290.4 L131.6 262.8 L163.7 237.3 L359.7 38.2\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"90.9\" cy=\"320.1\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"94.6\" cy=\"317.6\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"98.1\" cy=\"314.7\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"101.4\" cy=\"304.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"105.9\" cy=\"301.6\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"111.3\" cy=\"301.6\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"118.2\" cy=\"290.4\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"131.6\" cy=\"262.8\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"163.7\" cy=\"237.3\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"359.7\" cy=\"38.2\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"349.7\" y=\"36.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">top tenth</text><text x=\"440.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">above the line:</text><text x=\"440.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">more left than</text><text x=\"440.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the model said</text></svg>", "caption": "Honest at the bottom, low at the top, where the credits go."}
```

The bottom half is close: a chance of 0.010 and 1.0% left. **From the seventh tenth up, the model
says less than happened**, and in the top tenth, where every credit goes, it says 0.247 where 0.292
left. Over all six months it predicted 5.1% and 6.1% cancelled.

So the chances are too low, by about a sixth, just where the decision is made. A subscriber the
model gives 0.24 is really nearer 0.28, already worth a credit, and the break-even cut leaves them
out. That is why a cut below 0.278 made more money in lesson 10. The cause is the next question,
because the cure depends on it.
