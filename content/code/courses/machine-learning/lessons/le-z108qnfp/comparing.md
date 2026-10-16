---
title: Comparing the ensembles honestly
version: 1
---

Every model in this lesson made money on the test months, and they can be lined up:

| model | lesson | test R$ |
|---|---|---|
| logistic regression | 5 | 16,424 |
| random forest, `max_features="sqrt"` | 8 | 18,584 |
| HistGradientBoosting, early stopping, rate 0.03 | 8 | 21,296 |
| XGBoost | 8 | 21,656 |
| HistGradientBoosting, as in lesson 2 | 2 | 21,672 |
| random forest, every column | 8 | 21,864 |
| LightGBM | 8 | 22,304 |
| 100 bagged trees | 8 | 23,384 |

The tempting reading is a ranking with bagging at the top. **The honest reading is that the ensembles
are tied.** Lesson 2's bootstrap put the noise in a test score of this size at several thousand reais,
and everything from R$ 21,296 to R$ 23,384 sits inside a range like that. A different six months, or
a different seed, would reorder them.

That is a claim, so measure it. Save this as `compare.py`; it fits the two boosting models again and
bootstraps the difference between them by subscriber, exactly as `beaten.py` did in lesson 2:

```python
# compare.py
import lightgbm
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

models = {
    "HistGradientBoosting": HistGradientBoostingClassifier(learning_rate=0.03, max_iter=2000,
        early_stopping=True, validation_fraction=0.15, n_iter_no_change=30,
        categorical_features="from_dtype", random_state=0),
    "LightGBM": lightgbm.LGBMClassifier(n_estimators=400, learning_rate=0.05, num_leaves=15,
        subsample=0.8, subsample_freq=1, colsample_bytree=0.8, random_state=0, verbose=-1),
}
send = {}
for name, model in models.items():
    model.fit(train[features], train["churned"])
    send[name] = model.predict_proba(test[features])[:, 1] >= cut
    print(f"{name:21} R$ {net_value(test['churned'], send[name]):,.0f}")

rng = np.random.default_rng(0)
rows = test.groupby("customer_id").indices
people = list(rows)
y = test["churned"].to_numpy()
gaps = []
for _ in range(1000):
    idx = np.concatenate([rows[people[i]] for i in rng.choice(len(people), len(people))])
    a, b = (net_value(y[idx], send[n][idx]) for n in models)
    gaps.append(b - a)
low, high = np.percentile(gaps, [2.5, 97.5])
print(f"LightGBM minus HistGradientBoosting: 95% of resamples between R$ {low:,.0f} and R$ {high:,.0f}")
```

```
ana@lab:~/ml$ python compare.py
HistGradientBoosting  R$ 21,296
LightGBM              R$ 22,304
LightGBM minus HistGradientBoosting: 95% of resamples between R$ -1,008 and R$ 3,176
```

LightGBM made R$ 1,008 more on these rows, and **the interval of the difference runs from −R$ 1,008
to R$ 3,176**: it crosses zero comfortably. The test cannot tell the two apart, and lesson 2's advice
applies: choose on something else.

What the table does show is a step. **Every boosted model, the full forest and the bagged trees beat
logistic regression by R$ 5,000 to R$ 7,000, and none of them beats another by more than the noise.** The
forest limited to the square root of the columns sits between the two groups, for the reason the
forest section gave. That is the usual shape on tabular
business data: the jump from linear to trees is real, the choice among good tree ensembles is mostly
not. So the choice is made on practical grounds:

- **a random forest** when the defaults have to work, nobody will tune it, and probabilities that are
  roughly right matter more than the last thousand reais;
- **scikit-learn's HistGradientBoosting** when the project wants one library and nothing to install;
- **XGBoost or LightGBM** when the data is large, the team already uses one of them, or a feature only
  they have is needed.

Ana keeps the HistGradientBoosting model from here on, for the second reason. Lesson 9 tunes it, and
asks whether tuning is worth more than the noise.
