---
title: A change of one line
version: 1
---

A colleague suggests a common fix for a rare outcome: **weight the classes**, so that the 17% who
lapse count as much in training as the 83% who stay. In scikit-learn that is one argument. Here is
`model.py` with it, changed in that line and in its docstring:

```python
"""model.py: the lapse model, defined once, for every program that trains it.

Version 2: class_weight="balanced" weighs the members who lapsed as much, in total,
as the members who stayed.
"""
from sklearn.compose import make_column_transformer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

import features

COLUMNS = features.NUMERIC + features.CATEGORICAL


def make_model():
    return make_pipeline(
        make_column_transformer(
            (StandardScaler(), features.NUMERIC),
            (OneHotEncoder(handle_unknown="ignore"), features.CATEGORICAL),
        ),
        LogisticRegression(max_iter=1000, class_weight="balanced"),
    )


def trained(cutoff):
    rows = features.build(cutoff)
    return make_model().fit(rows[COLUMNS], rows["lapsed"])
```

Save it over the old `model.py`, and let DVC work out what that touches:

```
ana@dev:~/ml$ dvc repro
'shop.db.dvc' didn't change, skipping
Stage 'dataset' didn't change, skipping
Running stage 'train':
> python train.py data/train.csv models/lapse.joblib
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "d04183235c0e66c2",
  "cutoff": "2025-08-31",
  "rows": 2863,
  "scikit_learn": "1.9.1"
}
Updating lock file 'dvc.lock'

Running stage 'evaluate':
> python evaluate.py models/lapse.joblib data/test.csv
{
  "test": "data/test.csv",
  "cutoff": "2025-11-30",
  "members": 3130,
  "lapsed": 530,
  "roc_auc": 0.791,
  "average_precision": 0.519,
  "baseline_average_precision": 0.169,
  "lapsed_in_top_300": 191,
  "said": 0.426
}
Updating lock file 'dvc.lock'

To track the changes with git, run:

	git add dvc.lock

To enable auto staging, run:

	dvc config core.autostage true
Use `dvc push` to send your updates to remote storage.
ana@dev:~/ml$ dvc metrics diff v1
Path                      Metric             v1     workspace    Change
models/lapse.scores.json  average_precision  0.522  0.519        -0.003
models/lapse.scores.json  lapsed_in_top_300  190    191          1
models/lapse.scores.json  roc_auc            0.793  0.791        -0.002
models/lapse.scores.json  said               0.177  0.426        0.249
ana@dev:~/ml$ git add . && git commit -qm "lapse model v2: balanced class weights" && python log_run.py
Registered model 'lapse' already exists. Creating a new version of this model...
Created version '2' of model 'lapse'.
run 170f9946, registered as lapse version 2
ana@dev:~/ml$ python champion.py
version 1  aliases ['champion']  commit ada6255  average precision 0.522  said 0.177
version 2  aliases []  commit d9f6d3a  average precision 0.519  said 0.426
 member_id  p_lapse
         1    0.123
         2    0.090
         3    0.106
```

**DVC skipped the dataset stage**, because nothing it depends on changed, **and reran training and
evaluation**, because `model.py` is a dependency of training and the model is a dependency of
evaluation. `dvc metrics diff v1` compares the scores in the working directory with the ones
committed at `v1`.

The diff is the lesson's whole argument in four rows. **The ranking barely moved**: average
precision
0.522 to 0.519, AUC 0.793 to 0.791, one more lapse in the top 300. **The probabilities did**: the
model now says 0.426 on average, where 0.169 of members lapse. Balanced weights tell the model that
lapsing is as common as staying, and it believes it, so lesson 4's threshold arithmetic, and any
forecast of how many members will leave, would be off by more than double.

The change is committed and registered anyway, as **version 2**. The registry records what was tried
as well as what shipped. `champion.py` without an argument shows that the alias did not move:
**production still loads version 1.** The decision not to promote is a decision too, and
the scores beside each version are why it was made.
