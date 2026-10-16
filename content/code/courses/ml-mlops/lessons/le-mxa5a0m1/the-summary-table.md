---
title: The column from today's table
version: 1
---

Most warehouses keep a summary per customer, rebuilt every night: last visit, total spent, number
of orders. It is the right table for a dashboard, which wants the present. **It is the wrong table
for training, which wants the past**, and it is the first place a data engineer reaches for a
feature because it is already there.

This program trains the lapse model twice. Once with `recency_days` from `features.py`, computed as
of the cutoff. Once with the same column computed from a nightly summary of each member's latest
visit, the way such a table would hold it on 28 February. Save it as `leak.py`:

```python
"""leak.py: the same model, given one column read from today's table instead of the cutoff's."""
import sqlite3

import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

import features

# a summary table the way many warehouses keep one: rebuilt every night, one row
# per member, holding their latest visit as of the last night it was rebuilt
LATEST = "SELECT member_id, max(day) AS last_visit FROM purchases GROUP BY member_id"


def examples(cutoff, leaky):
    rows = features.build(cutoff)
    if leaky:
        with sqlite3.connect("shop.db") as db:
            latest = pd.read_sql_query(LATEST, db)
        rows = rows.merge(latest, on="member_id")
        rows["recency_days"] = (pd.Timestamp(cutoff) - pd.to_datetime(rows["last_visit"])).dt.days
    return rows


for leaky in (False, True):
    train, test = examples("2025-09-30", leaky), examples("2025-11-30", leaky)
    model = LogisticRegression(max_iter=1000).fit(train[features.NUMERIC], train["lapsed"])
    p = model.predict_proba(test[features.NUMERIC])[:, 1]
    print(f"recency from {'the summary table' if leaky else 'the cutoff       '}: "
          f"test AUC {roc_auc_score(test['lapsed'], p):.3f}")

# in production the summary table can only hold the past, so the model meets
# the honest column it was never trained on
train, live = examples("2025-09-30", True), examples("2025-11-30", False)
model = LogisticRegression(max_iter=1000).fit(train[features.NUMERIC], train["lapsed"])
p = model.predict_proba(live[features.NUMERIC])[:, 1]
print(f"trained on the summary table, used in production: AUC {roc_auc_score(live['lapsed'], p):.3f}, "
      f"members predicted to lapse {(p > 0.5).sum()} of {len(live)}, actually {live['lapsed'].sum()}")

print(examples("2025-11-30", True)[["member_id", "last_visit", "recency_days", "lapsed"]]
      .head(3).to_string(index=False))
```

```
ana@dev:~/ml$ python leak.py
recency from the cutoff       : test AUC 0.790
recency from the summary table: test AUC 0.994
trained on the summary table, used in production: AUC 0.787, members predicted to lapse 2450 of 3130, actually 530
 member_id last_visit  recency_days  lapsed
         1 2025-12-14           -14       0
         2 2026-02-25           -87       0
         3 2026-02-27           -89       0
```

**0.994.** The second model is nearly perfect on its test set, and the last three rows say how.
Member 1's latest visit, as the summary holds it, is 14 December, after the cutoff of 30 November,
so their recency comes out **negative**: -14 days. A negative recency means "came back", which is
the label. The model learned to read it, and the test rows, built from the same summary, rewarded
it.

**Then the third line, which is what production would have done.** On the night of a real cutoff
the summary can only hold visits up to that night, so recency is never negative, and the model
meets a column it was never trained on. It still ranks members in roughly the right order, AUC
0.787, but its probabilities are nonsense: **it predicts 2,450 of 3,130 members will lapse, when
530 did.** Any threshold chosen from its test results, any voucher budget, any forecast of
revenue lost, would be wrong by a factor of four.

## The fix is in the data, not the model

The model did nothing wrong. **A feature has to be computed as of the moment of prediction**, and
for that the platform needs either the history to compute it from (the purchases table, which is
what `features.py` reads) or snapshots of the summary as it stood each night, kept rather than
overwritten. Lesson 6 calls the result a point-in-time join, and builds it.

The check that catches this kind of leak costs one query: **for every feature, could its value on
the cutoff date have been computed on the cutoff date?** A recency that is negative, a "total
orders" that is larger than the orders before the cutoff, a status column with a value that did
not exist yet: each is a leak with its fingerprint left in the rows.
