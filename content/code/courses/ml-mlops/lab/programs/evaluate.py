"""evaluate.py: score a saved model on a later cutoff, beside the baseline.

    python evaluate.py models/lapse.joblib data/test.csv
"""
import json
import sys

import joblib
import pandas as pd
from sklearn.metrics import average_precision_score, roc_auc_score

from model import COLUMNS
from project import ROOT

model = joblib.load(ROOT / sys.argv[1])
rows = pd.read_csv(ROOT / sys.argv[2])
p = model.predict_proba(rows[COLUMNS])[:, 1]
top = rows.assign(p=p).nlargest(300, "p")

scores = {
    "test": sys.argv[2],
    "cutoff": rows["cutoff"].iloc[0],
    "members": len(rows),
    "lapsed": int(rows["lapsed"].sum()),
    "roc_auc": round(roc_auc_score(rows["lapsed"], p), 3),
    "average_precision": round(average_precision_score(rows["lapsed"], p), 3),
    "baseline_average_precision": round(rows["lapsed"].mean(), 3),
    "lapsed_in_top_300": int(top["lapsed"].sum()),
    "said": round(p.mean(), 3),
}
(ROOT / sys.argv[1]).with_suffix(".scores.json").write_text(json.dumps(scores, indent=2) + "\n")
print(json.dumps(scores, indent=2))
