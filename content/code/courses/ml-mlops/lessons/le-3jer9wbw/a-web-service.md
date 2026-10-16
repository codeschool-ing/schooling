---
title: A web service that answers for one member
version: 1
---

A real-time model is a program that waits for a request, computes one answer and sends it back.
**The work that can be done once is done at start-up, and the work per request is kept to the
minimum**: load the model once, then for each request read one row and make one prediction. Save
this as `serve.py`:

```python
"""serve.py: the lapse model as a web service, one member at a time.

    uvicorn serve:app --port 8000
"""
import mlflow
import pandas as pd
from fastapi import FastAPI, HTTPException
from mlflow import MlflowClient

from featurestore import get
from model import COLUMNS
from project import ROOT

mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
VERSION = MlflowClient().get_model_version_by_alias("lapse", "champion").version
MODEL = mlflow.sklearn.load_model(f"models:/lapse/{VERSION}")   # loaded once, at start-up

app = FastAPI()


@app.get("/lapse/{member_id}")
def lapse(member_id: int):
    row = get(member_id)
    if row is None:
        raise HTTPException(404, "no features fresh enough for this member")
    p = MODEL.predict_proba(pd.DataFrame([row])[COLUMNS])[0, 1]
    return {"member_id": member_id, "p_lapse": round(float(p), 3),
            "features_as_of": row["as_of"], "model_version": VERSION}
```

`@app.get("/lapse/{member_id}")` says that a request for `/lapse/2` calls the function below it with
`member_id` 2, and FastAPI checks the type: anything that is not a whole number is refused before
the function runs. Three choices in it are the platform's:

- **features come from the online store**, `get` from lesson 6, never computed here, which is how
  lesson 5's skew is kept out by construction;
- **a member the store has nothing fresh for gets a 404**, a refusal with a reason, which is the
  decision lesson 6 said a service must make in advance;
- **the model is pinned at start-up to the version the alias named then**, and the response says
  which. Moving the alias changes nothing until the service restarts, so nobody is scored by two
  versions within one process.

Start it in a second terminal, from `~/ml`, with the environment active:

```sh
uvicorn serve:app --port 8000
```

`serve:app` is the file and the object inside it. Uvicorn prints a line when it is ready, `Uvicorn
running on http://127.0.0.1:8000`, and then one line for every request it answers.
