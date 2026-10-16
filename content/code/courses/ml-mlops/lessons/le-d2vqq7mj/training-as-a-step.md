---
title: Training as a step that leaves a record
version: 1
---

The training step reads a validated file, fits the model from `model.py`, and saves it. **And it
writes down what it did**, because a model file on its own cannot say which rows made it. Save this
as `train.py`:

```python
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
```

`joblib.dump` saves the whole fitted pipeline, scaler and encoder included, to one file; `joblib`
comes with scikit-learn. Beside it, the step writes a small JSON record:

- **`data_sha256`** is a fingerprint of the training file's bytes, its first sixteen hexadecimal
  characters. Change one row and it changes, so two models with the same fingerprint learned from
  the same rows, whatever the files were called;
- **`cutoff` and `rows`** say what the data was, in words a person checks against a report;
- **`scikit_learn`** is the library version, because a saved model is only guaranteed to load in
  the version that saved it.

```
ana@dev:~/ml$ python train.py data/train.csv models/lapse.joblib
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "d04183235c0e66c2",
  "cutoff": "2025-08-31",
  "rows": 2863,
  "scikit_learn": "1.9.1"
}
```

**That record is the beginning of lineage**: the chain from a model back to the data and code that
made it. It is incomplete in one obvious way. It names the data but not the code: if somebody
changes `features.py` and builds a new training file, the fingerprint changes and nothing says why.
Lesson 7 closes that gap with Git, DVC and MLflow, which record the code's version and the data's
together; this file is what the pipeline can do with nothing but Python.
