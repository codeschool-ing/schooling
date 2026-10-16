---
title: Grid search
version: 1
---

The obvious way to search is to list the values worth trying for each hyperparameter and fit every
combination. That is a **grid**, and `GridSearchCV` does it: for each combination, cross-validate,
then refit the best on all the training rows. Three learning rates, three sizes of tree and two
numbers of trees make 3 × 3 × 2 = 18 candidates, and with three folds, 54 fits. `n_jobs=-1` runs them
on every processor at once. Save this as `grid.py`:

```python
# grid.py
import time

import pandas as pd
from sklearn.model_selection import GridSearchCV

from feira import by_time, load_churn
from tuning import FEATURES, booster, time_folds, value_per_thousand

train, _ = by_time(load_churn())
grid = {"learning_rate": [0.03, 0.1, 0.3],
        "max_leaf_nodes": [7, 31, 63],
        "max_iter": [100, 300]}
start = time.perf_counter()
search = GridSearchCV(booster(), grid, cv=list(time_folds(train)),
                      scoring=value_per_thousand, n_jobs=-1)
search.fit(train[FEATURES], train["churned"])
print(f"{len(search.cv_results_['params'])} candidates x 3 folds, {time.perf_counter() - start:.0f} s")
results = pd.DataFrame(search.cv_results_)[["params", "mean_test_score", "std_test_score"]]
for _, row in results.sort_values("mean_test_score", ascending=False).head(5).iterrows():
    print(f"  {row['mean_test_score']:6.0f} +/- {row['std_test_score']:4.0f}  {row['params']}")
print("worst:", f"{results['mean_test_score'].min():.0f}")
```

```
ana@lab:~/ml$ python grid.py
18 candidates x 3 folds, 17 s
     757 +/-  193  {'learning_rate': 0.1, 'max_iter': 100, 'max_leaf_nodes': 7}
     726 +/-  138  {'learning_rate': 0.03, 'max_iter': 300, 'max_leaf_nodes': 7}
     714 +/-  171  {'learning_rate': 0.03, 'max_iter': 100, 'max_leaf_nodes': 7}
     710 +/-  146  {'learning_rate': 0.1, 'max_iter': 300, 'max_leaf_nodes': 7}
     705 +/-  132  {'learning_rate': 0.03, 'max_iter': 100, 'max_leaf_nodes': 31}
worst: 255
```

**The best combination makes R$ 757 per thousand rows, against R$ 610 for the defaults**, and the worst
makes R$ 255: the dials matter. All five of the best use small trees, 7 leaves, against the default 31.
That is information the grid found and nobody guessed.

Look at the numbers beside the scores, though: **the standard deviation across the three folds is
between 132 and 193 for each of the top five.** The difference between first and fifth place is 52.
The order among them is mostly luck, and the honest summary of the grid is *small trees are better
here*, not *this exact row is best*.

## What a grid costs

A grid grows by multiplication. Three values of five hyperparameters is 3⁵ = 243 candidates; five
values of each is 3,125. And most of those fits are wasted when, as is common, only one or two of the
hyperparameters matter much: a grid spends most of its budget varying dials that change nothing,
while trying only three values of the one that does. The next section is the fix for that.
