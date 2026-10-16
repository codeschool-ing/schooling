---
title: SHAP: sharing out each prediction
version: 1
---

Permutation importance and partial dependence describe the model as a whole. **SHAP** (SHapley Additive
exPlanations) explains each prediction separately, by sharing it out among the columns. It starts from
the model's average output, and gives each column a number, its **SHAP value**, such that the average
plus every column's value adds up exactly to that row's prediction. A positive value pushed this
subscriber's chance up, a negative one pulled it down.

The sharing comes from game theory: a Shapley value is each player's fair share of a team's winnings,
averaged over every order in which the players could have joined. For trees there is a fast exact way to
compute it, and the `shap` library has it for LightGBM, the booster lesson 8 used. Averaging the size of
each column's SHAP values over every test row gives a global importance too. Save this as
`shap_global.py`:

```python
# shap_global.py
import numpy as np
import pandas as pd
import shap
from lightgbm import LGBMClassifier

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
model = LGBMClassifier(n_estimators=200, learning_rate=0.05, random_state=0, verbose=-1)
model.fit(train[features], train["churned"])
explained = shap.TreeExplainer(model)(test[features])

print(f"{explained.values.shape[0]:,} subscribers x {explained.values.shape[1]} columns of SHAP values")
average = pd.Series(np.abs(explained.values).mean(axis=0), index=features)
print(average.sort_values(ascending=False).head(8).round(3).to_string())
```

`verbose=-1` keeps LightGBM quiet while fitting. The SHAP values are in log-odds, the units a boosted
classifier adds up before turning the sum into a chance.

```
ana@lab:~/ml$ python shap_global.py
24,257 subscribers x 16 columns of SHAP values
rating_90d          0.484
tenure_months       0.392
complaints_90d      0.196
late_90d            0.178
skips_90d           0.154
days_since_login    0.146
payment             0.095
age                 0.089
```

The ranking agrees with permutation importance at the top, rating and then tenure, and adds the
categories, which `importances.py` left out: `payment` is seventh, the boleto effect from the weights
section. Where the two disagree a little lower down, the reason is what they measure. Permutation asks
how much the **score** depends on a column; SHAP asks how much the **predictions** move with it. A column
can move predictions without improving them.

A global ranking is the summary. SHAP's real use is one subscriber at a time, which is the next section.
