---
title: What the search is judged by
version: 1
---

A search compares hundreds of fits, so before it starts, two things have to be fixed: **which rows
judge each candidate** and **what score they give it**. Change either one halfway and the
comparison is meaningless. Both go in a small module, which is the second shared file of the course.
Save this as `tuning.py`:

```schooling-example
{
  "language": "python",
  "file": "tuning.py",
  "parts": [
    {
      "code": "# tuning.py\n\"\"\"What every search in lesson 9 shares: the folds, the score and the model.\"\"\"\nimport numpy as np\nfrom sklearn.ensemble import HistGradientBoostingClassifier\n\nfrom feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, net_value\n\nFEATURES = NUMERIC + CATEGORICAL\n",
      "note": "The second shared file of the course, after `feira.py`. Every search in this lesson imports these three things, so every candidate is judged by exactly the same folds and the same score."
    },
    {
      "code": "\ndef time_folds(train, last=3):\n    \"\"\"For each of the last months: learn from every month before it, score that month.\"\"\"\n    months = sorted(train[\"snapshot\"].unique())\n    for month in months[-last:]:\n        yield (np.flatnonzero(train[\"snapshot\"] < month),\n               np.flatnonzero(train[\"snapshot\"] == month))\n",
      "note": "**The folds walk forward**, as lesson 3 argued. Each of the last three training months is scored by a model that learned from every month before it. The test months, July to December, are not touched; `by_time` has already cut them off before this function sees the rows."
    },
    {
      "code": "\ndef value_per_thousand(model, X, y):\n    \"\"\"The scorer: reais per 1,000 rows, sending the credit at the break-even chance.\"\"\"\n    send = model.predict_proba(X)[:, 1] >= CREDIT / (SAVED * KEPT)\n    return net_value(y, send) / len(y) * 1000\n",
      "note": "**The score is the business's.** scikit-learn accepts any function of a fitted model, the rows and the answers as a scorer, so the search optimises net value per thousand rows rather than accuracy, which section 03 explains."
    },
    {
      "code": "\ndef booster(**settings):\n    return HistGradientBoostingClassifier(categorical_features=\"from_dtype\", early_stopping=False,\n                                          random_state=0, **settings)",
      "note": "The model being tuned, with early stopping off, so that the number of trees is one of the dials the search turns rather than something decided behind its back."
    }
  ]
}
```

Two decisions are inside it.

**The folds respect time.** Lesson 3 showed that a random split flatters a model here by about 13%,
and a search on flattering folds picks the setting that exploits the flattery best. Here each of
April, May and June 2025 is scored by a model fitted on every earlier month. The test months, July
to December, stay untouched until the end of the lesson.

**The score is net value.** scikit-learn's searches maximise whatever score they are given, and
their default for a classifier is accuracy. Lesson 2 showed accuracy barely moves on this data while
the money moves a great deal, so a search on accuracy would pick among settings by the third decimal
place of a number nobody cares about. `value_per_thousand` hands it lesson 1's question instead.

Before searching anything, score the defaults the same way, so there is a number to beat. Save this
as `baseline_cv.py`:

```python
# baseline_cv.py
from sklearn.model_selection import cross_val_score

from feira import by_time, load_churn
from tuning import FEATURES, booster, time_folds, value_per_thousand

train, _ = by_time(load_churn())
folds = list(time_folds(train))
for rows, check in folds:
    print(f"learn from {len(rows):,} rows, score {train['snapshot'].iloc[check[0]]:%Y-%m}")
scores = cross_val_score(booster(), train[FEATURES], train["churned"], cv=folds,
                         scoring=value_per_thousand)
print("defaults, R$ per 1,000 rows:", scores.round(0), f"mean {scores.mean():.0f}")
```

```
ana@lab:~/ml$ python baseline_cv.py
learn from 27,797 rows, score 2025-04
learn from 31,300 rows, score 2025-05
learn from 34,906 rows, score 2025-06
defaults, R$ per 1,000 rows: [361. 910. 561.] mean 610
```

**The defaults make R$ 610 per thousand rows on average**, and that average hides a wide range:
R$ 361 in April, R$ 910 in May. The spread across folds is the size of the luck in each comparison
to come, and it is large. Keep it in mind when the search reports its winner.
