---
title: LightGBM
version: 1
---

**LightGBM**, from Microsoft, is the other library that dominates boosting on tables. It differs from
XGBoost mainly in how a tree grows. XGBoost, by default, grows **level by level**: every leaf at one
depth is split before any leaf at the next. LightGBM grows **leaf by leaf**: at each step it splits
whichever single leaf gains the most, wherever it is, so a tree can go deep along one branch and stay
shallow elsewhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 250\" role=\"img\" data-fig=\"l08-growth\" aria-label=\"Two small trees with three splits and four leaves each. On the left, level by level: every node at one depth is split before the next depth. On the right, leaf by leaf: one branch goes three levels deep while the other stops after the first split.\"><path d=\"M160.0 57.0 L100.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M160.0 57.0 L220.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 107.0 L70.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 107.0 L130.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M220.0 107.0 L190.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M220.0 107.0 L250.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"160.0\" cy=\"50.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"100.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"220.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"70.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"130.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"190.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"250.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><path d=\"M480.0 57.0 L430.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M480.0 57.0 L560.0 93.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M430.0 107.0 L400.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M430.0 107.0 L470.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M470.0 157.0 L440.0 193.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M470.0 157.0 L500.0 193.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"480.0\" cy=\"50.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"430.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"560.0\" cy=\"100.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"400.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"470.0\" cy=\"150.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"440.0\" cy=\"200.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"500.0\" cy=\"200.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"160.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">level by level: XGBoost by default</text><text x=\"480.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">leaf by leaf: LightGBM</text><text x=\"160.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">four leaves at one depth</text><text x=\"480.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the best leaf is split next, wherever it is</text></svg>", "caption": "Same number of splits, different shapes. A filled circle is a question; an empty one is a leaf."}
```

That makes the important setting `num_leaves`, the total number of leaves a tree may have, rather than
a depth. Leaf-wise growth reaches a given accuracy with fewer splits and is faster on large data; it
can also overfit faster on small data, which is why `num_leaves` is kept modest and the same
subsampling as XGBoost is used. LightGBM reads pandas categories on its own and, like the others,
accepts gaps. Save this as `lgbm.py`:

```python
# lgbm.py
import time

import lightgbm

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

start = time.perf_counter()
model = lightgbm.LGBMClassifier(n_estimators=400, learning_rate=0.05, num_leaves=15,
                                subsample=0.8, subsample_freq=1, colsample_bytree=0.8,
                                random_state=0, verbose=-1)
model.fit(train[features], train["churned"])
send = model.predict_proba(test[features])[:, 1] >= cut
print(f"LightGBM {lightgbm.__version__}: R$ {net_value(test['churned'], send):,.0f}, "
      f"{send.sum():,} credits, {time.perf_counter() - start:.1f} s")
```

```
ana@lab:~/ml$ python lgbm.py
LightGBM 4.7.0: R$ 22,304, 760 credits, 1.0 s
```

**R$ 22,304**, with settings chosen to match `xgb.py` as closely as two libraries allow: 400 trees at
0.05, 15 leaves, the same subsampling. `verbose=-1` silences the training messages LightGBM prints by
default.

Speed differences between the two only show on much bigger tables than this one; at 38,628 rows both
fit in about a second. Which to use is mostly a matter of habit and of what the rest of a team
already runs. The next section asks whether the difference in reais between them means anything.
