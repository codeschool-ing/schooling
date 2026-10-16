---
title: One subscriber, explained
version: 1
---

The retention team calls the subscribers who get a credit, and a caller who knows why the model chose
someone has a better conversation than one reading a number. Take the subscriber the model was surest
about in December 2025, and share out their prediction. Save this as `shap_one.py`:

```python
# shap_one.py
import numpy as np
import pandas as pd
import shap
from lightgbm import LGBMClassifier

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
model = LGBMClassifier(n_estimators=200, learning_rate=0.05, random_state=0, verbose=-1)
model.fit(train[features], train["churned"])

december = test[test["snapshot"] == "2025-12-01"]
chance = model.predict_proba(december[features])[:, 1]
one = december.iloc[[np.argmax(chance)]]
explained = shap.TreeExplainer(model)(one[features])

print(f"{one['customer_id'].iloc[0]}, December 2025: chance {chance.max():.3f}")
print(f"starting point, the average subscriber: {explained.base_values[0]:+.2f}")
contributions = pd.Series(explained.values[0], index=features)
for column in contributions.abs().sort_values(ascending=False).index[:6]:
    print(f"  {column:18} = {str(one[column].iloc[0]):>8}   {contributions[column]:+.2f}")
total = explained.base_values[0] + contributions.sum()
print(f"sum of all {len(features)}: {total:+.2f}, which is a chance of {1 / (1 + np.exp(-total)):.3f}")
```

The last line checks the promise SHAP makes: the starting point plus every column's contribution, turned
from log-odds back into a chance, is exactly the model's prediction.

```
ana@lab:~/ml$ python shap_one.py
C02724, December 2025: chance 0.883
starting point, the average subscriber: -3.50
  rating_90d         =     3.09   +2.86
  tenure_months      =        3   +0.61
  days_since_login   =     40.0   +0.60
  complaints_90d     =        1   +0.44
  late_90d           =        2   +0.41
  payment            =   boleto   +0.40
sum of all 16: +2.02, which is a chance of 0.883
```

**The sum is the prediction, to the third decimal.** The starting point, −3.50 in log-odds, is a chance of
about 3%: the model's average output. This subscriber's columns move it to +2.02, a chance of 0.883, and
six columns do most of the moving.

Read as a sentence for the caller: *a rating of 3.09 over the last ninety days, the biggest reason by far;
only three months as a subscriber; forty days without opening the app; a complaint and two late
deliveries; pays by boleto.* Every item is something the caller can raise, and two of them, the
complaint and the late boxes, are things the company did. That is a different call from *"our model
thinks you might leave"*.

Two cautions. SHAP explains **the model**, not the subscriber: it says why the model gave 0.883, and if the
model has learned something wrong, SHAP explains the wrong thing faithfully. And a contribution is not a
lever. Raising this subscriber's rating would not lower their chance by 2.86, because the rating is a
symptom of the boxes, not a dial the company can turn. The next section takes that further.
