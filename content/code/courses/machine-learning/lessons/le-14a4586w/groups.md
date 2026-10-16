---
title: Keeping a subscriber on one side
version: 1
---

The rows of `churn.csv` come in families: one subscriber, one row a month. When folds are cut at
random, a subscriber's March row can be in the training folds and their April row in the scoring
fold. **Whether that matters depends on whether the rows of a family share the answer.**

`folds.py` already measured it for Feira em Casa's question. Its third line used `GroupKFold`, which
puts every row of a subscriber in the same fold, and it scored about the same as the others: a mean
of R$ 787 per thousand rows against R$ 824 and R$ 758, well inside the spread. That is because the
question is about a month. Whether somebody cancels in April is a fresh event, and knowing their
March row says little about it.

Now ask a different question of the same rows: **will this subscriber ever cancel?** Each row
carries the same answer as every other row of the same person, and a model that recognises the
person has the answer. Save this as `groups.py`:

```python
# groups.py
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GroupKFold, KFold

from feira import NUMERIC, by_time, load_churn

train, _ = by_time(load_churn())
X = train[NUMERIC].fillna(-1)
ever = train.groupby("customer_id")["churned"].transform("max")   # one answer per person
print(f"rows whose subscriber ever cancels: {ever.mean():.1%}")


def top_tenth(splitter, groups=None):
    """Of the 10% of rows the model ranks highest, the share that are right."""
    hits = []
    for fit_rows, check_rows in splitter.split(X, ever, groups):
        forest = RandomForestClassifier(n_estimators=200, n_jobs=-1, random_state=0)
        forest.fit(X.iloc[fit_rows], ever.iloc[fit_rows])
        score = forest.predict_proba(X.iloc[check_rows])[:, 1]
        top = np.argsort(-score)[: len(check_rows) // 10]
        hits.append(ever.iloc[check_rows].iloc[top].mean())
    return np.mean(hits)


print(f"rows split at random:     {top_tenth(KFold(5, shuffle=True, random_state=0)):.1%}")
print(f"subscribers kept whole:   {top_tenth(GroupKFold(5), train['customer_id']):.1%}")
```

```
ana@lab:~/ml$ python groups.py
rows whose subscriber ever cancels: 23.9%
rows split at random:     76.0%
subscribers kept whole:   54.7%
```

The score here is the share of right answers among the 10% of rows the model ranks highest, chosen
because it needs no vocabulary from later lessons. Split at random, **76.0%** of the top tenth are
right; with each subscriber kept whole, **54.7%**. The forest had found a way to recognise people
from their age, tenure and habits, and a random split rewarded it for remembering them. The 54.7%
is the honest one: it is what happens when the model meets somebody new, which is the only thing
it will ever do in production.

## When to group

Group whenever **one real-world thing produces several rows and they share the answer**: a patient
and their scans, a customer and their orders when the question is about the customer, a house and
its listings over the years, a driver and their trips. The test is a question: *in production, will
the model ever score a row whose family it saw in training?* If not, the folds must not let it
either.
