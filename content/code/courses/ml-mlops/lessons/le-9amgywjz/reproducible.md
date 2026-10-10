---
title: The same rows, every time
version: 1
---

A feature store earns its place by one property: **asked for the training rows of a past cutoff, it
returns exactly what the feature code would have computed on that day**, today and next year. That
is checkable, and this program checks it, then shows what happens without it. Save it as
`reproduce.py`:

```python
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
```

`labelled` builds the question to ask the store: each member active on a cutoff, the cutoff as the
moment, and the label beside them. Labels come from `features.py` because they are not in the store,
and nothing else from that call is used.

```
ana@dev:~/ml$ python reproduce.py
30 November from the store equals features.py: True
trained on as of each row   2863 rows, test AUC 0.793
trained on latest values    2536 rows, test AUC 0.645
```

**`True` is the property.** Every feature of every member on 30 November, read from the store by
point-in-time join, is identical to what `features.py` computes for that cutoff, down to the last
decimal. A model trained on the store's rows for 31 August then scores **0.793**, the number lesson
5's pipeline printed. Same rows, same model, same score.

**The shortcut is the second line.** Join the 31 August labels to the online store's latest values
instead, which is the easy query and the one a dashboard table invites, and two things go wrong at
once. **327 members fall out**, because they are not active tonight and the online store has nothing
fresh for them. And the model learns from February's features beside August's outcomes, the
summary-table leak in a new shape: **its AUC drops to 0.645.** Nothing failed; it simply learned from
a moment nobody was predicting at.
