"""reproduce.py: training rows from the feature store, against features.py and against a shortcut."""
import sqlite3

import pandas as pd
from sklearn.metrics import roc_auc_score

import features
from featurestore import STORE, historical
from model import COLUMNS, make_model


def labelled(cutoff):
    return features.build(cutoff)[["member_id", "lapsed"]].assign(at=cutoff)


test = historical(labelled("2025-11-30"))
print(f"30 November from the store equals features.py: "
      f"{test[COLUMNS].equals(features.build('2025-11-30')[COLUMNS])}")

with sqlite3.connect(STORE) as db:
    latest = pd.read_sql_query("SELECT * FROM online", db)
train = labelled("2025-08-31")
for name, rows in (("as of each row", historical(train)),
                   ("latest values", train.merge(latest, on="member_id"))):
    model = make_model().fit(rows[COLUMNS], rows["lapsed"])
    p = model.predict_proba(test[COLUMNS])[:, 1]
    print(f"trained on {name:15} {len(rows):5} rows, test AUC {roc_auc_score(test['lapsed'], p):.3f}")
