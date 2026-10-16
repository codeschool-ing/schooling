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
