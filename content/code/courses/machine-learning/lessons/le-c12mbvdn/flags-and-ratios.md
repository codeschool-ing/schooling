---
title: Flags, caps and ratios
version: 1
---

The program below rebuilds lesson 5's table, then adds columns in two rounds, and fits both a
logistic regression and gradient boosting on each version. The first round, **the gaps**, is the subject of the next section; here the second matters. It adds seven columns, each with a reason:

| column | what it is | why |
|---|---|---|
| `unhappy` | rating below 3.6 | the cliff in `shapes.py` |
| `skip_streak` | three skips or more | the threshold |
| `gone_quiet` | more than 21 days without logging in | the jump |
| `young` | under 25 | the retention team says younger subscribers leave for a cheaper app |
| `tenure_capped` | tenure, but never above 24 | the first two years matter; after that a month is a month |
| `box_price` | price per box, not per month | a weekly plan's monthly price mixes the box with how often it comes |
| `late_and_new` | late deliveries, counted only in the first six months | a late box early on means more than a late box to somebody with two years of good ones |

Save this as `features.py`:

```python
# features.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.preprocessing import StandardScaler

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
medians = train[NUMERIC].median()

def lesson_5(rows):
    numbers = rows[NUMERIC].fillna(medians)
    words = pd.get_dummies(rows[CATEGORICAL], drop_first=True, dtype=float)
    return pd.concat([numbers, words], axis=1)

def with_gaps(rows):
    table = lesson_5(rows)
    table["no_rating"] = rows["rating_90d"].isna().astype(float)
    table["no_login"] = rows["days_since_login"].isna().astype(float)
    return table

def with_shapes(rows):
    table = with_gaps(rows)
    table["unhappy"] = (rows["rating_90d"] < 3.6).astype(float)
    table["skip_streak"] = (rows["skips_90d"] >= 3).astype(float)
    table["gone_quiet"] = (rows["days_since_login"] > 21).astype(float)
    table["young"] = (rows["age"] < 25).astype(float)
    table["tenure_capped"] = rows["tenure_months"].clip(upper=24)
    boxes = rows["plan"].map({"weekly": 4, "fortnightly": 2, "monthly": 1}).astype(float)
    table["box_price"] = rows["price_month"] / boxes
    table["late_and_new"] = rows["late_90d"] * (rows["tenure_months"] < 6)
    return table

cut = CREDIT / (SAVED * KEPT)
print("features        columns   logistic AUC   net value   boosting AUC   net value")
for name, build in [("lesson 5's", lesson_5), ("+ the gaps", with_gaps), ("+ the shapes", with_shapes)]:
    X_train, X_test = build(train), build(test)
    scale = StandardScaler().fit(X_train)
    line = LogisticRegression(max_iter=2000).fit(scale.transform(X_train), train["churned"])
    trees = HistGradientBoostingClassifier(random_state=0).fit(X_train, train["churned"])
    print(f"{name:14} {X_train.shape[1]:8}", end="")
    for chance in [line.predict_proba(scale.transform(X_test))[:, 1],
                   trees.predict_proba(X_test)[:, 1]]:
        print(f" {roc_auc_score(test['churned'], chance):13.3f}"
              f"   R$ {net_value(test['churned'], chance >= cut):6,.0f}", end="")
    print()
```

A missing rating is `NaN`, and `NaN < 3.6` is false, so a subscriber with no rating is not counted
as unhappy. That is the right default here, and it is a decision: write it down when you make it.

The new columns go through the same `StandardScaler` as the old ones, fitted on the training rows.
Scaling is the one kind of feature work this lesson does not revisit: lesson 5 showed why a weighted
sum needs it and a tree does not, and nothing about that has changed.

```
ana@lab:~/ml$ python features.py
features        columns   logistic AUC   net value   boosting AUC   net value
lesson 5's           22         0.799   R$ 16,424         0.801   R$ 22,912
+ the gaps           24         0.799   R$ 16,360         0.803   R$ 21,688
+ the shapes         31         0.818   R$ 22,712         0.800   R$ 23,168
```

**The logistic regression went from R$ 16,424 to R$ 22,712**, and its AUC from 0.799 to 0.818, the
best honest score of any model in the course so far. Seven columns, each one sentence long, did more than lesson 9's
whole search did for boosting. Lesson 9 said as much in advance: a good feature usually moves a model
more than a good dial.

**The boosted trees barely moved**: 0.801, 0.803, 0.800, and net values that wander by a thousand reais
either way, inside the noise lesson 2 measured. They had found the cliffs already. Every flag here is
a split a tree would make on its own, and handing it over saves the tree nothing.

Two lessons in one table, then:

- **Feature engineering matters most for the models that cannot find shapes**: linear and logistic
  regression, and anything that measures distances, such as nearest neighbours. For trees it matters
  when the shape needs information no single column holds, such as a ratio of two of them.
- **A simple model with good features can match a complex one with raw columns**, here with a
  higher AUC and the money within the noise, and keep everything
  lesson 5 valued in the simple one: weights a person can read, and a flag called `unhappy` that the
  retention team understands without a lesson on gradient boosting.
