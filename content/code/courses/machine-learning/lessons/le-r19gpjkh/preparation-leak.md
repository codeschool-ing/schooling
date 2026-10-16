---
title: The leak in the preparation
version: 1
---

The third way in has no column to blame. It happens when a step that **learns from the data** is
fitted on every row, and only then are the rows split. Scaling learns a mean and a spread; filling
gaps learns a median; choosing the best columns learns which ones are related to the target. Each
of those learned numbers then carries a little of the validation rows into the training.

The last of those is the one that does real damage, and it can be shown with nothing at all to
learn from. Take 400 rows, half of them leavers, and give them 2,000 columns of **random numbers**.
No column means anything. Choose the 20 columns most related to the target, then cross-validate a
model on them. Save this as `noise.py`:

```python
# noise.py
import numpy as np
from sklearn.feature_selection import SelectKBest, f_classif
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score
from sklearn.pipeline import make_pipeline

from feira import load_churn

churn = load_churn()
rng = np.random.default_rng(0)
sample = churn.groupby("churned").sample(200, random_state=0)   # 200 left, 200 stayed
y = sample["churned"].to_numpy()
X = rng.normal(size=(len(y), 2000))                              # 2,000 columns of nothing
print(f"{X.shape[0]} rows, {X.shape[1]} columns of random numbers, half the rows leavers")

picked = SelectKBest(f_classif, k=20).fit(X, y)                  # chosen with every row
X20 = picked.transform(X)
wrong = cross_val_score(LogisticRegression(), X20, y, cv=5)
print(f"columns picked before the split: accuracy {wrong.mean():.3f}")

honest = make_pipeline(SelectKBest(f_classif, k=20), LogisticRegression())
right = cross_val_score(honest, X, y, cv=5)                      # picked inside each fold
print(f"columns picked inside each fold: accuracy {right.mean():.3f}")
```

```
ana@lab:~/ml$ python noise.py
400 rows, 2000 columns of random numbers, half the rows leavers
columns picked before the split: accuracy 0.688
columns picked inside each fold: accuracy 0.445
```

**68.8% accuracy from pure noise**, on a balanced sample where a coin gets 50%. Among 2,000 random
columns, some line up with the target by chance, and choosing them with every row means choosing
the ones that line up on the validation rows too. The model is then validated on rows whose noise
was used to pick its columns.

Done properly, inside each fold, the choice is made again from the four training folds only and
the fifth is left alone. The accuracy falls to **44.5%**, which is chance with a little bad luck, and
is the truth: there was nothing to find.

## A pipeline is the fix

`make_pipeline` glued the choosing and the model into one object, and `cross_val_score` fitted
that whole object inside each fold. That is the general cure for this kind of leak: **put every
step that learns anything inside the pipeline**, and the cross-validation cannot fit it on rows it
should not see. Lesson 15 builds Feira em Casa's pipeline that way, scaling and encoding included.

Scaling and filling gaps on every row leak far less than choosing columns does, because a mean
computed from 38,000 rows hardly moves when a fifth of them are added. They are still leaks, and
they are fixed in the same place for free, so there is no reason to argue about their size.
