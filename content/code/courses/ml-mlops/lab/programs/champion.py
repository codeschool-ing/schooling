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
