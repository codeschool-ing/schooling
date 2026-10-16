"""experiments.py: try several models on the same rows, and let MLflow keep the score of each."""
import mlflow
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score, roc_auc_score

from model import COLUMNS, make_model
from project import DATA, ROOT

train, test = pd.read_csv(DATA / "train.csv"), pd.read_csv(DATA / "test.csv")
mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
mlflow.set_experiment("lapse-experiments")

candidates = {f"logistic C={c}": make_model().set_params(logisticregression__C=c)
              for c in (0.01, 0.1, 1.0, 10.0)}
boosted = make_model()
boosted.steps[-1] = ("boosted", HistGradientBoostingClassifier(random_state=0))
candidates["gradient boosting"] = boosted

for name, model in candidates.items():
    with mlflow.start_run(run_name=name):
        model.fit(train[COLUMNS], train["lapsed"])
        p = model.predict_proba(test[COLUMNS])[:, 1]
        mlflow.log_param("model", name)
        mlflow.log_metrics({"roc_auc": roc_auc_score(test["lapsed"], p),
                            "average_precision": average_precision_score(test["lapsed"], p),
                            "said": p.mean()})

runs = mlflow.search_runs(experiment_names=["lapse-experiments"],
                          order_by=["metrics.average_precision DESC"])
print(runs[["params.model", "metrics.average_precision", "metrics.roc_auc", "metrics.said"]]
      .round(3).to_string(index=False))
