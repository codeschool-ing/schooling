---
title: Class weights
version: 1
---

The gentlest remedy changes nothing in the data. **A class weight multiplies each row's share of the
loss**: with `class_weight="balanced"`, every leaver counts as much as 36,427 / 2,201, about 16.6
stayers, so that the two classes weigh the same in total. A model that ignored the leavers before
now pays as much for missing them as for everything else together.

Most classifiers in scikit-learn accept the argument: logistic regression, support vector machines,
trees, forests, `HistGradientBoostingClassifier`. XGBoost spells it `scale_pos_weight`, and LightGBM
accepts either.

The program below fits the churn model four ways: as it was, with class weights, and with the two
kinds of resampling the next section describes. For each it prints the ranking measures from lesson
10, the average chance, the money at the default cut, and **the best cut on the test months with the
money there**. That last column is lesson 11's hindsight, and it is used here for one purpose only:
to compare the four models at their own best, which is the fairest comparison of what each one
learned. It is a ceiling, and none of them could have known it in advance. Save this as
`rebalance.py`:

```python
# rebalance.py
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score, roc_auc_score

from feira import CATEGORICAL, NUMERIC, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
leavers, stayers = train[train["churned"] == 1], train[train["churned"] == 0]
cuts = np.round(np.arange(0.02, 0.99, 0.01), 2)

remedies = {
    "none": (train, {}),
    "class weights": (train, {"class_weight": "balanced"}),
    "oversampling": (pd.concat([stayers, leavers.sample(len(stayers), replace=True,
                                                         random_state=0)]), {}),
    "undersampling": (pd.concat([leavers, stayers.sample(len(leavers), random_state=0)]), {}),
}
print("remedy           rows    AUC     AP   mean chance   net at 0.5   ceiling at")
for name, (rows, settings) in remedies.items():
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0,
                                           **settings)
    chance = model.fit(rows[features], rows["churned"]).predict_proba(test[features])[:, 1]
    values = [net_value(test["churned"], chance >= cut) for cut in cuts]
    print(f"{name:14} {len(rows):6,} {roc_auc_score(test['churned'], chance):6.3f} "
          f"{average_precision_score(test['churned'], chance):6.3f} {chance.mean():9.3f}"
          f"   R$ {net_value(test['churned'], chance >= 0.5):8,.0f}"
          f"   {cuts[np.argmax(values)]:.2f}: R$ {max(values):,.0f}")
```

```
ana@lab:~/ml$ python rebalance.py
remedy           rows    AUC     AP   mean chance   net at 0.5   ceiling at
none           38,628  0.804  0.322     0.051   R$    9,088   0.23: R$ 23,832
class weights  38,628  0.797  0.321     0.313   R$  -41,528   0.79: R$ 21,304
oversampling   72,854  0.788  0.315     0.276   R$  -28,784   0.78: R$ 21,616
undersampling   4,402  0.788  0.285     0.342   R$  -73,464   0.84: R$ 18,440
```

Take the first two rows. **The weights did not improve the ranking**: AUC went from 0.804 to 0.797,
average precision from 0.322 to 0.321. What they did is move every chance up, from an average of
0.051 to 0.313, six times the plain model's average and about five times the true rate of leaving. That
moves which rows cross 0.5: the weighted model sends credits by the thousand at the default cut, and
loses R$ 41,528 doing it.

Its own best cut is 0.79, where it makes R$ 21,304, a little less than the plain model at 0.23. The
weights changed **where the useful cut is**, not how much the model knows. That is the whole effect,
and it is the same thing lesson 11 found from the other side: a weighted model is a distorted one,
whose chances need calibrating before a cut computed from the costs means anything.
