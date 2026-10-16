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
