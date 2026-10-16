---
title: The confusion matrix, counted
version: 1
---

Lesson 1 drew the four outcomes of a yes-or-no prediction: true and false positives, false and true
negatives. **Every classification metric in this lesson is arithmetic on those four counts**, so the
first step is to count them for a real model. The model is lesson 2's gradient boosting with its
defaults, and the first program scores the test months once and saves the scores, so that every
later program in this lesson reads the same numbers. Save this as `scores.py`:

```python
# scores.py
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
model.fit(train[features], train["churned"])
test = test.assign(chance=model.predict_proba(test[features])[:, 1])
test[["customer_id", "snapshot", "churned", "chance"]].to_csv("scores.csv", index=False)
print(f"{len(test):,} test rows scored; saved scores.csv")
```

```
ana@lab:~/ml$ python scores.py
24,257 test rows scored; saved scores.csv
```

A model like this one gives a **chance**, and the four counts only exist once a **cut** turns the
chance into a yes or a no. Two cuts are worth comparing: 0.5, the one every library uses when asked
for `predict`, and 0.278, lesson 2's break-even point. Save this as `confusion.py`:

```python
# confusion.py
import pandas as pd
from sklearn.metrics import confusion_matrix

from feira import CREDIT, KEPT, SAVED

scores = pd.read_csv("scores.csv")
for cut in [0.5, CREDIT / (SAVED * KEPT)]:
    said = (scores["chance"] >= cut).astype(int)
    tn, fp, fn, tp = confusion_matrix(scores["churned"], said).ravel()
    print(f"cut {cut:.3f}:  TP {tp:4}  FP {fp:4}  FN {fn:4}  TN {tn:6}")
```

```
ana@lab:~/ml$ python confusion.py
cut 0.500:  TP  117  FP   77  FN 1367  TN  22696
cut 0.278:  TP  348  FP  363  FN 1136  TN  22410
```

`confusion_matrix` returns the counts in a fixed order, which `ravel` flattens to true negatives,
false positives, false negatives and true positives. Laid out as lesson 1 drew them:

| cut 0.278 | the subscriber left | the subscriber stayed |
|---|---|---|
| **credit sent** | 348 true positives | 363 false positives |
| **no credit** | 1,136 false negatives | 22,410 true negatives |

**The cut moves rows between the cells.** At 0.5 the model sends 194 credits and finds 117 leavers;
at 0.278 it sends 711 and finds 348. Lowering the cut always turns some false negatives into true
positives and some true negatives into false positives, and the question of where to stop is lesson
11's. This lesson is about how to read the four numbers once a cut is chosen, and how to judge a model
without choosing one.

Every metric below either picks a cut and summarises the four cells, or summarises the model across
all cuts at once. Keep the table in view; each formula is a ratio of two of its cells.
