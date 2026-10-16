---
title: Experiments, kept rather than remembered
version: 1
---

The registry holds the models that might ship. **Most models trained never ship**: a modeller tries
a dozen settings to find one, and the dozen are worth keeping too, because the next person to ask
"did anybody try gradient boosting?" deserves an answer with numbers. MLflow keeps them as runs in
an **experiment**. Save this as `experiments.py`:

```python
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
```

It trains five candidates on the same rows: logistic regression with four strengths of
regularisation (`C`, where smaller means simpler) and a gradient-boosted tree model. Each run logs
its name and three scores, and `search_runs` reads them back, best first. `2>/dev/null` hides the
log lines MLflow writes when it creates the experiment.

```
ana@dev:~/ml$ python experiments.py 2>/dev/null
     params.model  metrics.average_precision  metrics.roc_auc  metrics.said
  logistic C=0.01                      0.526            0.793         0.175
   logistic C=0.1                      0.524            0.794         0.176
   logistic C=1.0                      0.522            0.793         0.177
  logistic C=10.0                      0.521            0.792         0.178
gradient boosting                      0.472            0.757         0.159
```

**The four logistic regressions are within five thousandths of each other**, so the setting barely
matters on this data; the simplest, `C=0.01`, is fractionally best. **Gradient boosting is clearly
worse**: 0.472 average precision against 0.526, and it predicts 0.159 on average where 0.169 lapsed.
A more powerful algorithm is not a better model on a few thousand rows with ten features.

None of these is registered. They live in the experiment `lapse-experiments`, apart from the
pipeline's runs in `lapse`, and the one worth shipping would go through the pipeline, so that its
data and code are versioned like v1's. **An experiment is a notebook that cannot lose its results;
the pipeline is how a result becomes a model.**
