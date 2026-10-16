"""canary.py: send one member in ten to a new version, and compare the two groups."""
import sqlite3
import zlib

import mlflow
import pandas as pd

from featurestore import STORE
from model import COLUMNS
from project import ROOT

CANARY_PERCENT = 10


def arm(member_id):
    """The same member always lands in the same group, and nobody chooses which."""
    return "canary" if zlib.crc32(str(member_id).encode()) % 100 < CANARY_PERCENT else "stable"


mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
versions = {"stable": mlflow.sklearn.load_model("models:/lapse/1"),
            "canary": mlflow.sklearn.load_model("models:/lapse/2")}

with sqlite3.connect(STORE) as db:
    rows = pd.read_sql_query("SELECT * FROM offline WHERE as_of = '2026-02-28'", db)
rows["arm"] = rows["member_id"].map(arm)
for name, model in versions.items():
    group = rows["arm"] == name
    rows.loc[group, "p_lapse"] = model.predict_proba(rows.loc[group, COLUMNS])[:, 1]

summary = rows.groupby("arm").agg(members=("member_id", "size"), mean_p=("p_lapse", "mean"),
                                  over_0_2=("p_lapse", lambda p: (p > 0.2).mean()))
print(summary.round(3).to_string())
