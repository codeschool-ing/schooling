---
title: PCA inside a model
version: 1
---

The second reason to reduce was to feed a model fewer columns. Lesson 15's pipeline makes that a one-line
experiment: put a `PCA` step between the preparation and the logistic regression, and the model learns
from components instead of columns. Save this as `pca_model.py`; it tries several numbers of components
on the churn model:

```python
# pca_model.py
from sklearn.decomposition import PCA
from sklearn.metrics import roc_auc_score

from churn_model import build
from feira import CREDIT, KEPT, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
print("columns into the model    AUC   net value")
for components in [3, 5, 10, 20, None]:
    model = build()
    if components:
        model.steps.insert(2, ("pca", PCA(n_components=components, random_state=0)))
    chance = model.fit(train, train["churned"]).predict_proba(test)[:, 1]
    label = f"{components} components" if components else "all 36 columns"
    print(f"{label:22} {roc_auc_score(test['churned'], chance):6.3f}"
          f"   R$ {net_value(test['churned'], chance >= CREDIT / (SAVED * KEPT)):,.0f}")
```

`model.steps.insert(2, …)` puts the new step third, after `shapes` and `prepare`, so the PCA sees the 36
prepared columns and is fitted on the training months only, like everything else in the pipeline.

```
ana@lab:~/ml$ python pca_model.py
columns into the model    AUC   net value
3 components            0.790   R$ 17,736
5 components            0.799   R$ 18,456
10 components           0.812   R$ 22,344
20 components           0.815   R$ 23,384
all 36 columns          0.818   R$ 22,184
```

**The AUC never rises above the full model's 0.818.** Three components lose a good deal, 0.790; ten are
nearly as good, 0.812; twenty are within the noise. The net value wanders, R$ 23,384 at twenty
components and R$ 22,184 with all of them, inside the range lesson 2's bootstrap would not separate.

So on this problem PCA buys a smaller model and costs a little accuracy. It also costs something that
matters more: **the weights stop meaning anything.** Lesson 5 read a weight on `rating_90d` and lesson 14
on `unhappy`; a weight on *component 7* is a weight on a mixture of 36 columns, and no retention team can
act on it.

PCA earns its place in a model in two cases. One is many more columns than this, hundreds or thousands
that move together, such as the pixels of an image or the words of lesson 14's text. The other is a
method that measures distance and is suffering from the curse of lesson 6. With 36 well-chosen columns and 38,628 rows,
neither is true, and the full model stays.
