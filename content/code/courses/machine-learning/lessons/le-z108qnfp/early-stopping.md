---
title: Early stopping, and the boosting in scikit-learn
version: 1
---

The model lesson 2 used as a box was `HistGradientBoostingClassifier`, scikit-learn's fast gradient
boosting. *Hist* is for histograms: before fitting, every numeric column is cut into at most 255
bins, and the trees search for cuts between bins rather than between every pair of values. On tens
of thousands of rows that is much faster and loses almost nothing. It also reads pandas categories
and gaps as they are.

How many trees to grow is the question boosting always raises, and the answer it gives is to watch.
With `early_stopping=True`, the model holds back a share of its training rows, here 15%, scores them
after every tree, and stops when `n_iter_no_change` trees in a row have not improved that score. The
held-back rows are validation data in the sense of lesson 3, taken from the training months only.
Save this as `hist_boost.py`:

```python
# hist_boost.py
import time

from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

for rate, early in [(0.1, False), (0.1, True), (0.03, True)]:
    start = time.perf_counter()
    model = HistGradientBoostingClassifier(learning_rate=rate, max_iter=2000,
                                           early_stopping=early, validation_fraction=0.15,
                                           n_iter_no_change=30, categorical_features="from_dtype",
                                           random_state=0)
    model.fit(train[features], train["churned"])
    send = model.predict_proba(test[features])[:, 1] >= cut
    print(f"learning_rate={rate:<5} early_stopping={str(early):5} trees {model.n_iter_:4}  "
          f"R$ {net_value(test['churned'], send):7,.0f}  {time.perf_counter() - start:4.1f} s")
```

```
ana@lab:~/ml$ python hist_boost.py
learning_rate=0.1   early_stopping=False trees 2000  R$  13,424   6.4 s
learning_rate=0.1   early_stopping=True  trees   60  R$  20,856   0.4 s
learning_rate=0.03  early_stopping=True  trees  172  R$  21,296   0.9 s
```

**Without early stopping, 2,000 trees at a learning rate of 0.1 make R$ 13,424**: the model went on
fitting long after the signal ran out, and the extra trees learned noise. With early stopping at the
same rate it stops after **60** trees and makes R$ 20,856, in a small fraction of the time. At a gentler
rate of 0.03 it takes **172** trees and makes R$ 21,296, which is the usual pattern: a slower rate,
more trees, a slightly better result.

That last line is what every boosting library recommends in one form or another: **set the learning
rate low, set the number of trees high, and let early stopping decide when to stop**. It turns the
number of trees from a dial somebody has to guess into a measurement.

One caution from lesson 3 applies directly. The held-back 15% is drawn at random from the training
months, so it shares months with the rest. A stricter version holds back the **last** months instead,
and stops when the model stops improving on the most recent data. scikit-learn's random choice is fine
here because the months are only twelve and the drift within them is small; for a model that will meet
a changing world, hold back by time.
