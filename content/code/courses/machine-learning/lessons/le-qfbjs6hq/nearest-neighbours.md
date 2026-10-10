---
title: Nearest neighbours, the model that remembers
version: 1
---

The simplest idea in machine learning fits in a sentence: **to predict a new row, find the k rows
most like it in the training data, and let them vote.** That is k-nearest neighbours. Fitting does
nothing but store the training rows; all the work happens when a prediction is asked for, which is
backwards from every model so far. The chance of leaving is simply the share of leavers among the k
neighbours.

"Most like it" means closest, and closest means a **distance**: by default, the straight-line
distance through all the numeric columns at once, as if each row were a point in a space with one
axis per column. Two decisions matter more than anything else about the model: how many neighbours,
and what the axes are measured in. Save this as `knn.py`; it fits eight models and predicts 24,257
rows with each, so it takes about a minute:

```python
# knn.py
from sklearn.neighbors import KNeighborsClassifier
from sklearn.preprocessing import StandardScaler

from feira import CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
medians = train[NUMERIC].median()
X_train, X_test = train[NUMERIC].fillna(medians), test[NUMERIC].fillna(medians)
cut = CREDIT / (SAVED * KEPT)

scale = StandardScaler().fit(X_train)
for k in [1, 15, 101, 501]:
    for scaled in [False, True]:
        a, b = (scale.transform(X_train), scale.transform(X_test)) if scaled else (X_train, X_test)
        knn = KNeighborsClassifier(n_neighbors=k).fit(a, train["churned"])
        send = knn.predict_proba(b)[:, 1] >= cut
        print(f"k={k:<4} {'scaled' if scaled else 'raw':6}  {send.sum():5,} credits  "
              f"R$ {net_value(test['churned'], send):>8,.0f}")
```

```
ana@lab:~/ml$ python knn.py
k=1    raw     1,134 credits  R$  -22,896
k=1    scaled  1,118 credits  R$  -15,632
k=15   raw       120 credits  R$       96
k=15   scaled    332 credits  R$    7,744
k=101  raw         0 credits  R$        0
k=101  scaled    111 credits  R$    5,784
k=501  raw         0 credits  R$        0
k=501  scaled     16 credits  R$    1,232
```

## Reading it by k

**k = 1 loses money either way.** One neighbour is one row's luck: whether the single most similar
subscriber in the training months left decides everything, and that is the unlimited tree of lesson
3 under a different name. Its 1,118 credits are scattered almost at random.

**k = 15, scaled, is the best of them, at R$ 7,744.** Fifteen neighbours average away most of the
luck and still keep the neighbourhood local.

**Large k fades to the constant.** With 501 neighbours, almost every neighbourhood looks like the
whole population, about 6% leavers, and almost nobody reaches the 28% where a credit pays. The model
sends 16 credits; at the limit, with every training row as a neighbour, it would be lesson 2's
constant. **k is a dial from memorising to averaging**, and the right setting is between the ends,
found on validation data as lesson 9 does.

Even its best, R$ 7,744, is under half of logistic regression's R$ 16,424 and about a third of
boosting's. Section 08 says why that is the usual result on data like this, and where nearest
neighbours earns its place anyway.
