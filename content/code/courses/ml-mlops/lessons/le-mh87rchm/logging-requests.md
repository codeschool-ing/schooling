---
title: A line for every request
version: 1
---

Every check of speed and errors starts from the same raw material: **one record per request, saying
when it came, what it asked, how it ended, how long it took and what the model said.** Uvicorn
prints a line per request on its terminal, but a terminal scrolls away; the record has to go to a
file a program can read.

Replace `serve.py` with this version. The model, the features and the route are the same as in
lesson 8; what is new is the logger and the function above the route:

```python
"""serve.py: the lapse model as a web service, one member at a time, every request logged.

    uvicorn serve:app --port 8000
"""
import json
import logging
import time

import mlflow
import pandas as pd
from fastapi import FastAPI, HTTPException, Request
from mlflow import MlflowClient

from featurestore import get
from model import COLUMNS
from project import ROOT

mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
VERSION = MlflowClient().get_model_version_by_alias("lapse", "champion").version
MODEL = mlflow.sklearn.load_model(f"models:/lapse/{VERSION}")   # loaded once, at start-up

LOG = logging.getLogger("requests")
LOG.addHandler(logging.FileHandler(ROOT / "requests.log"))
LOG.setLevel(logging.INFO)

app = FastAPI()


@app.middleware("http")
async def log_every_request(request: Request, call_next):
    started = time.perf_counter()
    response = await call_next(request)
    LOG.info(json.dumps({
        "at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "path": request.url.path,
        "status": response.status_code,
        "ms": round((time.perf_counter() - started) * 1000, 2),
        "p_lapse": getattr(request.state, "p_lapse", None),
        "model_version": VERSION,
    }))
    return response


@app.get("/lapse/{member_id}")
def lapse(member_id: int, request: Request):
    row = get(member_id)
    if row is None:
        raise HTTPException(404, "no features fresh enough for this member")
    p = round(float(MODEL.predict_proba(pd.DataFrame([row])[COLUMNS])[0, 1]), 3)
    request.state.p_lapse = p
    return {"member_id": member_id, "p_lapse": p,
            "features_as_of": row["as_of"], "model_version": VERSION}
```

**A middleware is a function every request passes through on its way in and out.** This one starts
a clock, lets the request go on to the route with `call_next`, and when the response comes back
writes one line of JSON: the time, the path, the status, the milliseconds, the probability and the
version. The route leaves its probability on `request.state`, a place that travels with the
request, so the middleware can log it; a refused request never sets it, and its line says `null`.

**Each line is a JSON object on its own**, a format called JSON Lines: a program reads it a line at
a time, and a line half written when the process died spoils only itself. The logging module writes
it, because it is safe to call from the threads FastAPI runs the route on.

Stop the service of lesson 8 with Ctrl+C if it is still running, and start this one the same way,
in the second terminal:

```sh
uvicorn serve:app --port 8000
```

Then, from the first terminal, one member who has a score and one who does not, and the last two
lines of the log:

```
ana@dev:~/ml$ curl -s http://127.0.0.1:8000/lapse/2; echo
{"member_id":2,"p_lapse":0.098,"features_as_of":"2026-02-28","model_version":1}
ana@dev:~/ml$ curl -s http://127.0.0.1:8000/lapse/8; echo
{"detail":"no features fresh enough for this member"}
ana@dev:~/ml$ tail -2 requests.log
{"at": "2026-10-15T22:00:02", "path": "/lapse/2", "status": 200, "ms": 42.14, "p_lapse": 0.098, "model_version": 1}
{"at": "2026-10-15T22:00:02", "path": "/lapse/8", "status": 404, "ms": 1.15, "p_lapse": null, "model_version": 1}
```

Both requests are in the file, the refusal included, with its `null` probability. **A log that
only recorded successes would make the error rate zero by construction.**
