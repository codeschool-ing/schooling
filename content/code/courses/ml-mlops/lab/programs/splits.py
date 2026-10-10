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
