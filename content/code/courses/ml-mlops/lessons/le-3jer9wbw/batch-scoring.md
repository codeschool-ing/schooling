---
title: A nightly batch of scores
version: 1
---

A batch job does three things: **load the model production is meant to use, read the features of
everybody it scores, and write one row per member to a table** that other people read. Save this
as `score_batch.py`:

```python
"""score_batch.py: tonight's lapse scores for every active member, by the champion.

    python score_batch.py 2026-02-28
"""
import sqlite3
import sys

import mlflow
import pandas as pd
from mlflow import MlflowClient

from featurestore import STORE
from model import COLUMNS
from project import ROOT

cutoff = sys.argv[1]
mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
version = MlflowClient().get_model_version_by_alias("lapse", "champion").version
model = mlflow.sklearn.load_model(f"models:/lapse/{version}")

with sqlite3.connect(STORE) as db:
    rows = pd.read_sql_query("SELECT * FROM offline WHERE as_of = ?", db, params=(cutoff,))
if rows.empty:
    sys.exit(f"refused: the feature store has no snapshot for {cutoff}")
rows["p_lapse"] = model.predict_proba(rows[COLUMNS])[:, 1]

with sqlite3.connect(ROOT / "scores.db") as db:
    db.execute("""CREATE TABLE IF NOT EXISTS lapse_scores (
                    member_id INTEGER, cutoff TEXT, p_lapse REAL, model_version TEXT,
                    PRIMARY KEY (member_id, cutoff))""")
    db.execute("DELETE FROM lapse_scores WHERE cutoff = ?", (cutoff,))   # a rerun replaces the night
    db.executemany("INSERT INTO lapse_scores VALUES (?, ?, ?, ?)",
                   [(int(m), cutoff, round(float(p), 4), version)
                    for m, p in zip(rows["member_id"], rows["p_lapse"])])
    total = db.execute("SELECT count(*) FROM lapse_scores").fetchone()[0]
print(f"{len(rows)} members scored as of {cutoff} by lapse version {version}; "
      f"{total} rows in lapse_scores")
```

Each decision in it comes from an earlier lesson:

- **the model is the champion**, found through the alias from lesson 7, then loaded by its version
  number, so the job knows and records exactly which version wrote each row;
- **the features come from the offline store** of lesson 6, the snapshot for the night being
  scored, so the batch reads the same values training would read for that day;
- **a night with no snapshot is refused**, rather than scored from whatever is lying around;
- **the table's key is member and cutoff**, and the version is stored beside every score, the two
  things lesson 2 said a stored answer needs.

The program reads `features.db` and writes `scores.db`, a third SQLite file that marketing's tools
would read. Neither belongs in Git, so add them to `.gitignore`, along with the edge files section 08
will make:

```sh
printf 'scores.db\nmodels/*.onnx\n' >> .gitignore
```

Lesson 6's store has to hold tonight's snapshot first; if you ran its commands, it does. Then:

```
ana@dev:~/ml$ python score_batch.py 2026-02-28
3355 members scored as of 2026-02-28 by lapse version 1; 3355 rows in lapse_scores
```
