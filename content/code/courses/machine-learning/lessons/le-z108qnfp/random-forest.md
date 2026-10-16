---
title: Random forests
version: 1
---

Bagging leaves one source of sameness in place. When one column is far stronger than the others, as
the rating is here, **every tree puts it at the root**, and the trees end up more alike than the
bootstrap alone would make them. A **random forest** adds a second kind of randomness: at each cut,
each tree may only consider a random subset of the columns. Sometimes the rating is not on offer,
and the tree has to find the next best question, which makes the trees more different from each
other.

How many columns are offered is `max_features`. The classic choice for classification is the square
root of the number of columns; `1.0` means all of them, which turns the forest back into bagging.

A random forest in scikit-learn wants numbers, so the categories become one-hot columns with
`get_dummies`; the gaps it handles as the trees of lesson 7 did. And it brings a free validation set:
each tree's bootstrap leaves out about a third of the rows, and scoring each row with only the trees
that did not see it gives the **out-of-bag** score, a cross-validation that costs nothing. Save this
as `forest.py`:

```python
# forest.py
import time

import pandas as pd
from sklearn.ensemble import RandomForestClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
X_train = pd.get_dummies(train[NUMERIC + CATEGORICAL], dtype=float)
X_test = pd.get_dummies(test[NUMERIC + CATEGORICAL], dtype=float)
cut = CREDIT / (SAVED * KEPT)

for features in ["sqrt", 1.0]:
    start = time.perf_counter()
    forest = RandomForestClassifier(n_estimators=300, min_samples_leaf=20, max_features=features,
                                    oob_score=True, n_jobs=-1, random_state=0)
    forest.fit(X_train, train["churned"])
    send = forest.predict_proba(X_test)[:, 1] >= cut
    print(f"max_features={str(features):5} out-of-bag accuracy {forest.oob_score_:.4f}, "
          f"test R$ {net_value(test['churned'], send):,.0f}, {time.perf_counter() - start:.0f} s")
```

```
ana@lab:~/ml$ python forest.py
max_features=sqrt  out-of-bag accuracy 0.9438, test R$ 18,584, 4 s
max_features=1.0   out-of-bag accuracy 0.9450, test R$ 21,864, 11 s
```

Here the textbook default loses. With the square root of the columns at each cut, the forest makes
**R$ 18,584**; offered every column, **R$ 21,864**. On this data the rating matters so much that a tree
denied it at the root grows worse, and the extra difference between the trees does not make up for
it. On data where several columns are about equally useful, the square root usually wins. **That is
why it is a setting and not a constant**, and lesson 9 chooses it on validation data.

The out-of-bag accuracy, 0.9438 against 0.9450, barely moves, and sits a hair above what saying *stays* to everybody scores on those training rows, where 5.7% leave. That is lesson 2 again: accuracy cannot see what matters here. The forest scores its out-of-bag rows
by accuracy because that is its default, and a different score can be computed from
`oob_decision_function_` when one is needed.

Random forests are the most forgiving model in this course. They need no scaling, handle gaps and
interactions, rarely overfit badly, and give a good result with the defaults on most tables. **When in
doubt, fit a forest** is a reasonable habit; on most business data the next three sections will still
beat it by a little.
