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
