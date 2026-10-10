---
title: Does 0.3 mean 30%?
version: 1
---

A ranking only needs the order of the probabilities. **Anything that multiplies them needs the
probabilities themselves to be right**: the threshold rule of section 05, a forecast of how many
members will lapse next quarter, an expected revenue lost. A model whose 0.3 really means a 30%
chance is called **calibrated**.

The check is simple: group members by what the model said, and compare each group's average
prediction with the share who actually lapsed. Save this as `calibration.py`:

```python
"""calibration.py: when the model says 0.3, do 30% lapse?"""
import pandas as pd

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
test["p"] = lapse.predict_proba(test[COLUMNS])[:, 1]

test["band"] = pd.cut(test["p"], [0, 0.1, 0.2, 0.3, 0.5, 0.7, 1.0])
table = test.groupby("band", observed=True).agg(
    members=("p", "size"), said=("p", "mean"), happened=("lapsed", "mean"))
print(table.round(3).to_string())
print(f"all members: said {test['p'].mean():.3f}, happened {test['lapsed'].mean():.3f}")
```

```
ana@dev:~/ml$ python calibration.py
            members   said  happened
band                                
(0.0, 0.1]     1442  0.064     0.061
(0.1, 0.2]      946  0.139     0.127
(0.2, 0.3]      254  0.244     0.280
(0.3, 0.5]      240  0.389     0.338
(0.5, 0.7]      128  0.596     0.625
(0.7, 1.0]      120  0.790     0.750
all members: said 0.176, happened 0.169
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l04-calibration\" aria-label=\"What the model said against what happened, for six bands of members. The points sit close to the diagonal: 0.064 said and 0.061 happened, 0.139 and 0.127, 0.244 and 0.280, 0.389 and 0.338, 0.596 and 0.625, 0.790 and 0.750.\"><path d=\"M230.0 30.0 L230.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M226.0 270.0 L230.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M230.0 213.5 L480.0 213.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M226.0 213.5 L230.0 213.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"213.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M230.0 157.1 L480.0 157.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M226.0 157.1 L230.0 157.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"157.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M230.0 100.6 L480.0 100.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M226.0 100.6 L230.0 100.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"100.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M230.0 44.1 L480.0 44.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M226.0 44.1 L230.0 44.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"222.0\" y=\"44.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8</text><text x=\"230.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">what happened</text><path d=\"M230.0 270.0 L480.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M230.0 270.0 L230.0 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"230.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M288.8 270.0 L288.8 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"288.8\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M347.6 270.0 L347.6 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"347.6\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M406.5 270.0 L406.5 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"406.5\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M465.3 270.0 L465.3 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"465.3\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8</text><text x=\"355.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">what the model said</text><path d=\"M230.0 270.0 L480.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"412.4\" y=\"49.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perfectly calibrated</text><circle cx=\"248.8\" cy=\"252.8\" r=\"9.0\" fill=\"var(--phosphor)\"></circle><circle cx=\"270.9\" cy=\"234.1\" r=\"7.859752908908532\" fill=\"var(--phosphor)\"></circle><circle cx=\"301.8\" cy=\"190.9\" r=\"5.518172509538362\" fill=\"var(--phosphor)\"></circle><circle cx=\"344.4\" cy=\"174.6\" r=\"5.4477904781022275\" fill=\"var(--phosphor)\"></circle><circle cx=\"405.3\" cy=\"93.5\" r=\"4.787613414537261\" fill=\"var(--phosphor)\"></circle><circle cx=\"462.4\" cy=\"58.2\" r=\"4.730849245989947\" fill=\"var(--phosphor)\"></circle></svg>", "caption": "Every band lands near the diagonal, where a prediction of 0.3 is followed by 30% of members lapsing. A ranking score cannot see this; the probabilities need it."}
```

Read it a row at a time. The 1,442 members given 0.1 or less were told 0.064 on average, and 6.1%
lapsed. The 120 told more than 0.7 averaged 0.790, and 75.0% lapsed. **Every band is within a few
points of the truth, and over all members the model said 0.176 against 0.169.** Logistic regression
fits by making its probabilities match the training labels, so it comes out close to calibrated on
data like the data it learned from. Other algorithms make no such promise, and the table has to be
built for each model rather than assumed.

**Calibration is also the score that breaks first in production.** If the share of members who
lapse changes, as lesson 10's shop will see, the order of the members may stay roughly right while
every probability is wrong by the same amount. AUC would not notice. This table would, as soon as
the labels arrived.
