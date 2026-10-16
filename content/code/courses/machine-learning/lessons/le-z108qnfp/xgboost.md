---
title: XGBoost
version: 1
---

**XGBoost** made gradient boosting the default answer for tables around 2015, by winning one
competition after another, and it is still among the most used libraries for it. The ideas are the
ones above, plus three that matter in practice:

- **regularisation inside the trees**: a penalty on the number of leaves and on the size of each
  leaf's value, in the spirit of lesson 5's ridge, so that a tree only grows a leaf the data insists on;
- **subsampling**: `subsample` fits each tree on a random share of the rows, and `colsample_bytree` on
  a random share of the columns, borrowing the forest's trick to make the trees more different;
- **speed**, through the same histogram method as the previous section, `tree_method="hist"`, which is
  the default in recent versions.

It follows scikit-learn's conventions, `fit` and `predict_proba`, so it drops into the same programs.
`enable_categorical=True` lets it read pandas categories directly. Save this as `xgb.py`:

```python
# xgb.py
import time

import xgboost

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

start = time.perf_counter()
model = xgboost.XGBClassifier(n_estimators=400, learning_rate=0.05, max_depth=4,
                              subsample=0.8, colsample_bytree=0.8,
                              enable_categorical=True, tree_method="hist", random_state=0)
model.fit(train[features], train["churned"])
send = model.predict_proba(test[features])[:, 1] >= cut
print(f"XGBoost {xgboost.__version__}: R$ {net_value(test['churned'], send):,.0f}, "
      f"{send.sum():,} credits, {time.perf_counter() - start:.1f} s")
```

```
ana@lab:~/ml$ python xgb.py
XGBoost 3.4.1: R$ 21,656, 751 credits, 0.7 s
```

**R$ 21,656**, in under a second. The settings were picked by hand to be sensible rather than tuned:
400 trees at a learning rate of 0.05, four levels deep, 80% of the rows and columns for each tree.
Lesson 9 tunes them.

The XGBoost installed here is `xgboost-cpu`, the build without graphics-card support, as lesson 1
explained. On a machine with a suitable graphics card, the full build can fit with `device="cuda"`;
on tables of this size the processor is fast enough that it makes no practical difference.
