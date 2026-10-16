---
title: The model registry, and an alias called champion
version: 1
---

DVC knows which model file belongs to which commit. **It does not know which model is in use**, and
a service that wants "the current lapse model" should not have to know a commit hash. That is the
**model registry**'s job: MLflow keeps named models, each with numbered versions, each version
pointing at the run that produced it.

This program records the pipeline's model as an MLflow run, with the commit and the scores, and
registers it under the name `lapse`. It refuses to run on uncommitted code, because a run that
cannot name its commit is lesson 5's record over again. Save it as `log_run.py`:

```python
"""log_run.py: record the pipeline's model in MLflow, with the code and data it came from.

    python log_run.py            # after dvc repro, from a committed working tree
"""
import json
import subprocess

import joblib
import mlflow

from project import MODELS, ROOT


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True).stdout.strip()


if git("status", "--porcelain"):
    raise SystemExit("refused: commit first, or the run cannot name the code that made it")

record = json.loads((MODELS / "lapse.json").read_text())
scores = json.loads((MODELS / "lapse.scores.json").read_text())

mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
if mlflow.get_experiment_by_name("lapse") is None:
    mlflow.create_experiment("lapse", artifact_location=(ROOT / "mlruns").as_uri())
mlflow.set_experiment("lapse")

with mlflow.start_run(run_name=f"pipeline {git('rev-parse', '--short', 'HEAD')}") as run:
    mlflow.log_params({**record, "git_commit": git("rev-parse", "HEAD")})
    mlflow.log_metrics({k: v for k, v in scores.items() if isinstance(v, (int, float))})
    info = mlflow.sklearn.log_model(joblib.load(MODELS / "lapse.joblib"), name="model",
                                    registered_model_name="lapse")
print(f"run {run.info.run_id[:8]}, registered as lapse version {info.registered_model_version}")
```

`set_tracking_uri` points MLflow at a SQLite file in the project, `mlflow.db`; the model files go to
`mlruns/`. `registered_model_name` creates version 1 of `lapse` the first time and a new version
every time after. Then a second program, which points an **alias** at a version and loads whatever
the alias names. Save it as `champion.py`:

```python
"""champion.py: point the alias at a version, then load whatever the alias names."""
import sys

import mlflow
import pandas as pd
from mlflow import MlflowClient

from model import COLUMNS
from project import DATA, ROOT

mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
client = MlflowClient()
if len(sys.argv) > 1:
    client.set_registered_model_alias("lapse", "champion", sys.argv[1])

for found in client.search_model_versions("name = 'lapse'", order_by=["version_number ASC"]):
    v = client.get_model_version("lapse", found.version)      # the search leaves aliases out
    run = client.get_run(v.run_id)
    print(f"version {v.version}  aliases {v.aliases}  commit {run.data.params['git_commit'][:7]}  "
          f"average precision {run.data.metrics['average_precision']}  said {run.data.metrics['said']}")

model = mlflow.sklearn.load_model("models:/lapse@champion")
members = pd.read_csv(DATA / "test.csv").head(3)
print(members[["member_id"]].assign(p_lapse=model.predict_proba(members[COLUMNS])[:, 1].round(3))
      .to_string(index=False))
```

The two new programs are code like any other, so they are committed first; `log_run.py` would
refuse otherwise, its own two files being the uncommitted change.

```
ana@dev:~/ml$ git add log_run.py champion.py && git commit -qm "record runs in MLflow"
ana@dev:~/ml$ python log_run.py
2026/10/10 22:44:27 INFO mlflow.store.db.utils: Creating initial MLflow database tables...
2026/10/10 22:44:27 INFO mlflow.store.db.utils: Updating database tables
Successfully registered model 'lapse'.
Created version '1' of model 'lapse'.
run 2bf77d2f, registered as lapse version 1
ana@dev:~/ml$ python champion.py 1
version 1  aliases ['champion']  commit ada6255  average precision 0.522  said 0.177
 member_id  p_lapse
         1    0.123
         2    0.090
         3    0.106
```

MLflow prints a few `INFO` lines of its own the first time it creates its database; they are shown
here because they are what you will see. The run is registered as **version 1**, and `champion.py 1`
points the alias `champion` at it. The last lines are the model **loaded by its alias**,
`models:/lapse@champion`, scoring three members: close to the 0.129, 0.087 and 0.121 that lesson
2's `classify.py` gave the same members, from a model trained a month later.

**The alias is what production uses.** A batch job or a service loads `models:/lapse@champion`, and
promoting a new version is moving the alias, one call, with no change to anything that loads it.
Rolling back is moving it back. Lesson 8 loads the model that way, and lesson 10 moves the alias.
