---
title: Evaluation as a step, with its baseline
version: 1
---

The fourth step scores the saved model on the test file and saves the scores beside the model.
**It reloads the model from disk rather than using the one in memory**, which is the point: what it
scores is the file that would be deployed, not an object that existed only while training ran.
Save this as `evaluate.py`:

```python
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
```

The scores are lesson 4's, each with what it needs to mean anything. `baseline_average_precision`
is the share who lapsed, what a model that knew nothing would score; `lapsed_in_top_300` answers
marketing's budget; `said` is the average probability, to compare with the share who actually
lapsed and catch a model that has stopped being calibrated.

```
ana@dev:~/ml$ python evaluate.py models/lapse.joblib data/test.csv
{
  "test": "data/test.csv",
  "cutoff": "2025-11-30",
  "members": 3130,
  "lapsed": 530,
  "roc_auc": 0.793,
  "average_precision": 0.522,
  "baseline_average_precision": 0.169,
  "lapsed_in_top_300": 190,
  "said": 0.177
}
```

Lesson 4's model scored 0.790 and 195 in the top 300. **This one, trained a month earlier on 31
August, scores 0.793 and 190.** Neither difference is an improvement or a decline worth reading: they
are the noise of training on one month rather than another. That is worth knowing before anybody
celebrates the next change of three thousandths.
