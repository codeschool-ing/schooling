---
title: The same member on both sides
version: 1
---

One cutoff gives about three thousand examples. **More are easily had by stacking cutoffs**: the
members as of every month-end, nine months of them, each row labelled by its own next 90 days. That
is a common and reasonable way to build a training set, and it creates a trap, because now **the
same member appears many times**, once per cutoff, with rows that resemble each other.

Split those rows at random and some of a member's months go to training while their neighbouring
months go to the test. The model is then tested partly on people it has already met, a month
earlier or later. This program measures the effect with three splits of the same nine months. Save
it as `splits.py`:

```python
"""splits.py: nine monthly cutoffs stacked, split three ways, scored on what was held out."""
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import GroupShuffleSplit, train_test_split

import features

CUTOFFS = ["2025-03-31", "2025-04-30", "2025-05-31", "2025-06-30", "2025-07-31",
           "2025-08-31", "2025-09-30", "2025-10-31", "2025-11-30"]
rows = pd.concat([features.build(c).assign(cutoff=c) for c in CUTOFFS], ignore_index=True)
print(f"{len(rows)} rows, {rows['member_id'].nunique()} different members")


def score(train, test):
    forest = RandomForestClassifier(n_estimators=200, random_state=0, n_jobs=-1)
    forest.fit(train[features.NUMERIC], train["lapsed"])
    return roc_auc_score(test["lapsed"], forest.predict_proba(test[features.NUMERIC])[:, 1])


train, test = train_test_split(rows, test_size=0.25, random_state=0)
print(f"random rows:          {score(train, test):.3f}")

keep, held = next(GroupShuffleSplit(test_size=0.25, random_state=0)
                  .split(rows, groups=rows["member_id"]))
print(f"by member:            {score(rows.iloc[keep], rows.iloc[held]):.3f}")

print(f"by time, Nov from <= Aug: "
      f"{score(rows[rows['cutoff'] <= '2025-08-31'], rows[rows['cutoff'] == '2025-11-30']):.3f}")
```

`train_test_split` takes a random quarter of the rows. `GroupShuffleSplit` takes a random quarter
of the **members**, so each member's rows all land on one side. The last line trains on the
cutoffs up to August and tests on November, the way the model will actually be used: on members as
they stand on a later date.

```
ana@dev:~/ml$ python splits.py
24977 rows, 3518 different members
random rows:          0.766
by member:            0.750
by time, Nov from <= Aug: 0.755
```

The random split says 0.766. Split so that no member is on both sides, the same forest scores
0.750, and on a later month 0.755. **Sixteen thousandths is the size of the illusion here**, and
it is not small: it is about the size of the improvements a modeller argues for when choosing
between two algorithms. With a model that memorises more, or a feature closer to the member's
identity, it grows; an id column left among the features is the extreme case.

**The split that matches use is the right one.** The lapse model will score members it has met
before, on a date after its training data ends, so the honest test is a later date. A model used on
customers it has never seen (a new shop, say) would want the split by member. The question to ask
the modeller is not "did you split?" but "**what will be different about the rows in production,
and does the test have the same difference?**"
