---
title: Experimentos guardados em vez de lembrados
version: 1
---

O registro guarda os modelos que podem ir ao ar. **A maioria dos modelos treinados nunca vai**: quem
modela testa uma dúzia de ajustes para achar um, e a dúzia também vale ser guardada, porque a próxima
pessoa que perguntar "alguém testou gradient boosting?" merece uma resposta com números. O MLflow os
guarda como execuções num **experimento**. Salve isto como `experiments.py`:

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

Ele treina cinco candidatos nas mesmas linhas: regressão logística com quatro intensidades de
regularização (`C`, em que menor quer dizer mais simples) e um modelo de árvores com gradient
boosting. Cada execução registra o nome e três notas, e o `search_runs` as lê de volta, a melhor
primeiro. `2>/dev/null` esconde as linhas de log que o MLflow escreve ao criar o experimento.

```
ana@dev:~/ml$ python experiments.py 2>/dev/null
     params.model  metrics.average_precision  metrics.roc_auc  metrics.said
  logistic C=0.01                      0.526            0.793         0.175
   logistic C=0.1                      0.524            0.794         0.176
   logistic C=1.0                      0.522            0.793         0.177
  logistic C=10.0                      0.521            0.792         0.178
gradient boosting                      0.472            0.757         0.159
```

**As quatro regressões logísticas ficam a cinco milésimos umas das outras**, então o ajuste quase não
importa nestes dados; o mais simples, `C=0.01`, é por pouco o melhor. **O gradient boosting é
claramente pior**: 0,472 de precisão média contra 0,526, e ele prevê 0,159 em média onde 0,169 se
afastaram. Um algoritmo mais poderoso não é um modelo melhor com alguns milhares de linhas e dez
atributos.

Nenhum destes é registrado. Eles moram no experimento `lapse-experiments`, separados das execuções
do pipeline em `lapse`, e o que valesse a pena publicar passaria pelo pipeline, para que os seus
dados e código tivessem versão como os do v1. **Um experimento é um notebook que não perde os
resultados; o pipeline é como um resultado vira um modelo.**
