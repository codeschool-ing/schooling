"""calibration.py: when the model says 0.3, do 30% lapse?"""
import pandas as pd

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")
test["p"] = lapse.predict_proba(test[COLUMNS])[:, 1]

test["band"] = pd.cut(test["p"], [0, 0.1, 0.2, 0.3, 0.5, 0.7, 1.0])
table = test.groupby("band", observed=True).agg(
    members=("p", "size"), said=("p", "mean"), happened=("lapsed", "mean"))
print(table.round(3).to_string())
print(f"all members: said {test['p'].mean():.3f}, happened {test['lapsed'].mean():.3f}")
