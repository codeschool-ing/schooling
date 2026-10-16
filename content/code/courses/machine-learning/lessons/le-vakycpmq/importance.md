---
title: Two kinds of importance, and a column of noise
version: 1
---

"Which columns matter most" has two common answers for a tree model, and they can disagree badly.

- **Impurity importance**, `feature_importances_` on a random forest, adds up how much each column
  reduced the impurity of lesson 7's splits, across every tree. It comes free with the fitted model.
- **Permutation importance** shuffles one column on the **test** rows, breaking its link to everything
  else, and measures how much the model's score falls. A column the model relies on costs a lot to
  shuffle; a column it ignores costs nothing.

To see which one to trust, give the model something that cannot matter. The program below adds two
columns of pure chance, `noise`, a random number between 0 and 1, and `coin`, a random 0 or 1, and asks
both methods to rank them. Save this as `importances.py`:

```python
# importances.py
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.inspection import permutation_importance

from feira import NUMERIC, by_time, load_churn

train, test = by_time(load_churn())
rng = np.random.default_rng(0)
for rows in (train, test):
    rows["noise"] = rng.random(len(rows))
    rows["coin"] = rng.integers(0, 2, len(rows))
columns = NUMERIC + ["noise", "coin"]

forest = RandomForestClassifier(n_estimators=200, min_samples_leaf=5, random_state=0, n_jobs=-1)
forest.fit(train[columns].fillna(-1), train["churned"])
shuffled = permutation_importance(forest, test[columns].fillna(-1), test["churned"],
                                  scoring="roc_auc", n_repeats=5, random_state=0, n_jobs=-1)
table = pd.DataFrame({"impurity": forest.feature_importances_,
                      "permutation": shuffled.importances_mean}, index=columns)
print(table.sort_values("impurity", ascending=False).round(3).to_string())
```

The permutation column is how much the test AUC falls, on average over five shuffles, when that column
alone is shuffled.

```
ana@lab:~/ml$ python importances.py
                   impurity  permutation
rating_90d            0.265        0.091
noise                 0.133       -0.002
tenure_months         0.103        0.031
age                   0.101        0.001
days_since_login      0.090        0.011
skips_90d             0.062        0.008
late_90d              0.054        0.018
orders_90d            0.047       -0.001
price_month           0.045        0.003
complaints_90d        0.042        0.014
support_calls_90d     0.029       -0.001
coin                  0.021       -0.001
app_user              0.009       -0.000
```

**By impurity, random noise is the second most important column in the model**, above tenure, the days
since login and every complaint. By permutation it is worth −0.002: shuffling it changes nothing.

The reason is how impurity importance is earned. A column with many distinct values offers the tree many
places to split, and with deep trees some of those splits will carve up the training rows usefully by
pure luck. Each one is credited to the column. `noise` has 38,628 distinct values and gets a great deal
of such credit; `coin`, with two values, gets little, though it is just as meaningless. Age, with sixty
values, is fourth by impurity and almost nothing by permutation. **Impurity importance is biased towards
columns with many values**, and on the training rows it cannot tell learning from memorising.

Permutation importance is measured where it should be, on rows the model did not learn from, in units
that mean something, here AUC. It is slower, since it re-scores the model many times, and it shares
credit badly between correlated columns: shuffle one of two columns that say the same thing, and the
model leans on the other. But it is the one to put in a report.
