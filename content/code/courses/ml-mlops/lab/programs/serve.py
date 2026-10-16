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
