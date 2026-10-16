---
title: Resample after the split, never before
version: 1
---

Oversampling copies rows. If the copying happens **before** the data is split into the part a model
learns from and the part it is judged on, copies of the same leaver land on both sides. The model is
then judged partly on rows it has already seen, and the score says so with confidence. It is lesson
4's leakage, made by a tool that looks like a cure.

The program below measures the same model three ways. The folds here are random rather than by
month, which lesson 3 warned against; the point is to isolate the copying, and the test months at
the end are the honest check. Save this as `leak.py`:

```python
# leak.py
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import KFold

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())

def oversample(rows):
    leavers = rows[rows["churned"] == 1]
    extra = leavers.sample(len(rows) - 2 * len(leavers), replace=True, random_state=0)
    return pd.concat([rows, extra])

def auc(learn, judge):
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(learn[features], learn["churned"])
    return roc_auc_score(judge["churned"], model.predict_proba(judge[features])[:, 1])

folds = KFold(5, shuffle=True, random_state=0)
before = oversample(train)
wrong = [auc(before.iloc[a], before.iloc[b]) for a, b in folds.split(before)]
right = [auc(oversample(train.iloc[a]), train.iloc[b]) for a, b in folds.split(train)]
print(f"oversampled, then split:   AUC {np.mean(wrong):.3f}")
print(f"split, then oversampled:   AUC {np.mean(right):.3f}")
print(f"the test months:           AUC {auc(oversample(train), test):.3f}")
```

`oversample` adds copies of leavers until the two classes are the same size. The two lines in the
middle differ only in the order of two steps.

```
ana@lab:~/ml$ python leak.py
oversampled, then split:   AUC 0.908
split, then oversampled:   AUC 0.793
the test months:           AUC 0.789
```

**0.908 against 0.793.** The first number is the one somebody would report after oversampling a
file and then running cross-validation on it, and it is a model that looks better than anything in
lesson 8. The test months, which no copy reached, say 0.789, and the honest folds said 0.793 all
along.

The rule generalises beyond copying: **anything that is fitted from the data happens inside the
fold, after the split.** Resampling, scaling, filling in missing values, choosing features. Lesson 15
builds this into a pipeline, so the order cannot be got wrong by hand, and `imbalanced-learn` has a
pipeline of its own for the same reason: it applies resampling only when fitting, never when scoring.
