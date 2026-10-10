---
title: Regression, when the answer is an amount
version: 1
---

**Regression answers with a quantity.** The question for this section: how much will each active
member spend in the 90 days after the cutoff? It is the same members and the same features as the
lapse model, and a different label, which `features.py` does not compute. So the program adds it
with one query of its own. Save it as `regress.py`:

```python
"""regress.py: how much will each active member spend in the next 90 days?"""
import sqlite3

import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error

import features

SPEND_AFTER = """
SELECT p.member_id, sum(l.price_cents) AS spend_next_90d
FROM purchases p JOIN lines l USING (purchase_id)
WHERE p.day > :cutoff AND p.day <= date(:cutoff, '+90 days')
GROUP BY p.member_id
"""


def examples(cutoff):
    rows = features.build(cutoff)
    with sqlite3.connect("shop.db") as db:
        after = pd.read_sql_query(SPEND_AFTER, db, params={"cutoff": cutoff})
    rows = rows.merge(after, on="member_id", how="left")
    rows["spend_next_90d"] = rows["spend_next_90d"].fillna(0)   # no visit: spent nothing
    return rows


if __name__ == "__main__":
    train, test = examples("2025-09-30"), examples("2025-11-30")
    model = LinearRegression().fit(train[features.NUMERIC], train["spend_next_90d"])
    test["predicted"] = model.predict(test[features.NUMERIC]).round()

    print(test[["member_id", "visits_180d", "spend_180d", "predicted", "spend_next_90d"]]
          .head(4).to_string(index=False))
    print(f"mean absolute error: R$ {mean_absolute_error(test['spend_next_90d'], test['predicted']) / 100:.2f}")
```

`examples` joins the spending after the cutoff to the features before it. **The `fillna(0)` line
is a decision, not a tidy-up**: a member with no visit in the 90 days has no row in the query, and
"spent nothing" is the true value for them, so missing becomes zero. In another dataset a missing
value means "we do not know", and filling it with zero would teach the model something false.

The `if __name__ == "__main__":` line means the training below it runs when you type
`python regress.py`, and not when another program imports `examples` from it, which the next
section does.

`LinearRegression` fits one weight per feature and adds them up, with no probability at the end.

```
ana@dev:~/ml$ python regress.py
 member_id  visits_180d  spend_180d  predicted  spend_next_90d
         1            5       32930    28375.0          8980.0
         2            4       33940    29732.0          3990.0
         3            4       33940    27933.0         22960.0
         7            7       56900    34937.0         69880.0
mean absolute error: R$ 179.49
```

Read the four rows against each other. Members 2 and 3 had identical histories, four visits and
R$ 339.40, and the model predicted nearly the same for both, about R$ 297 and R$ 279. One then
spent R$ 39.90 and the other R$ 229.60. **No model that only sees the past could tell those two
apart**, and that is the normal state of a regression: the error is spread around the truth, and
the useful question is how wide.

**Mean absolute error** is the plainest answer: the average distance between prediction and truth,
in the units of the label. Here it is R$ 179.49 per member. Whether that is good is not something
the number can say on its own, and that is the next section.
