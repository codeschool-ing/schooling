"""train.py: fit the lapse model on a validated training set and save it.

    python train.py data/train.csv models/lapse.joblib
"""
import json
import sys
from hashlib import sha256

import joblib
import pandas as pd
import sklearn

from model import COLUMNS, make_model
from project import ROOT

data, out = ROOT / sys.argv[1], ROOT / sys.argv[2]
rows = pd.read_csv(data)
model = make_model().fit(rows[COLUMNS], rows["lapsed"])

out.parent.mkdir(exist_ok=True)
joblib.dump(model, out)
record = {
    "model": sys.argv[2],
    "trained_on": sys.argv[1],
    "data_sha256": sha256(data.read_bytes()).hexdigest()[:16],
    "cutoff": rows["cutoff"].iloc[0],
    "rows": len(rows),
    "scikit_learn": sklearn.__version__,
}
out.with_suffix(".json").write_text(json.dumps(record, indent=2) + "\n")
print(json.dumps(record, indent=2))
