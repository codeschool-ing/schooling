---
title: Too few, or too small a share
version: 1
---

A model learns what a leaver looks like from the leavers it is shown. If it is shown 2,201, that is
one amount of evidence; if 100, much less, whatever the stayers are doing. The share and the count
can be pulled apart: keep every stayer and vary the leavers, then keep the share fixed and vary
everything. Save this as `few.py`:

```python
# few.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score, roc_auc_score

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
leavers, stayers = train[train["churned"] == 1], train[train["churned"] == 0]

print("leavers   stayers   share    AUC     AP")
for n_leavers, n_stayers in [(100, 36427), (300, 36427), (1000, 36427), (2201, 36427),
                             (300, 4966), (2201, 4966)]:
    rows = pd.concat([leavers.sample(n_leavers, random_state=0),
                      stayers.sample(n_stayers, random_state=0)])
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    chance = model.fit(rows[features], rows["churned"]).predict_proba(test[features])[:, 1]
    print(f"{n_leavers:7,} {n_stayers:9,} {n_leavers / len(rows):7.1%} "
          f"{roc_auc_score(test['churned'], chance):6.3f} "
          f"{average_precision_score(test['churned'], chance):6.3f}")
```

Every model is scored on the same test months, with all their 1,484 leavers, so only the training
rows change.

```
ana@lab:~/ml$ python few.py
leavers   stayers   share    AUC     AP
    100    36,427    0.3%  0.593  0.124
    300    36,427    0.8%  0.748  0.219
  1,000    36,427    2.7%  0.791  0.290
  2,201    36,427    5.7%  0.803  0.322
    300     4,966    5.7%  0.737  0.238
  2,201     4,966   30.7%  0.794  0.298
```

Read the first four rows down. **With every stayer kept, AUC climbs from 0.593 to 0.803 as the
leavers go from 100 to 2,201.** The model with 100 leavers is barely better than chance; the one
with 1,000 is most of the way there.

Now compare rows that share a count and differ in share. 300 leavers among 36,427 stayers, a share
of 0.8%, and 300 among 4,966, a share of 5.7%: AUC 0.748 and 0.737. 2,201 leavers at 5.7% and at
30.7%: 0.803 and 0.794. **Changing the share, with the count fixed, did nothing useful.** If anything
the extra stayers helped a little, which makes sense: they are evidence too, about what staying looks
like.

That is the most important fact about imbalance, and the remedies in the next sections cannot change
it. **Resampling changes the share and cannot change the count.** Duplicating a leaver adds no new
leaver; dropping stayers throws evidence away. When a class is rare because there are only a few
hundred examples, the cure is more examples: a longer history, more months, a label collected for
longer. When it is rare only as a share, as here, the model has enough to learn from, and what is
left to handle is how its output is read.
