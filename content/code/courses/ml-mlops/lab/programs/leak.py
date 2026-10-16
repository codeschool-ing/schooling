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
