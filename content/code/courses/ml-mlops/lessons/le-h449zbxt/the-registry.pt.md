---
title: O registro de modelos, e um apelido chamado champion
version: 1
---

O DVC sabe qual arquivo de modelo pertence a qual commit. **Ele não sabe qual modelo está em uso**, e
um serviço que quer "o modelo de afastamento atual" não deveria precisar saber um hash de commit.
Esse é o trabalho do **registro de modelos** (*model registry*): o MLflow guarda modelos com nome,
cada um com versões numeradas, cada versão apontando para a execução que a produziu.

Este programa registra o modelo do pipeline como uma execução do MLflow, com o commit e as notas, e o
registra sob o nome `lapse`. Ele se recusa a rodar com código não commitado, porque uma execução que
não consegue nomear o seu commit é o registro da lição 5 de novo. Salve-o como `log_run.py`:

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

`set_tracking_uri` aponta o MLflow para um arquivo SQLite no projeto, `mlflow.db`; os arquivos do
modelo vão para `mlruns/`. `registered_model_name` cria a versão 1 de `lapse` na primeira vez e uma
versão nova em cada vez seguinte. Depois, um segundo programa, que aponta um **apelido** para uma
versão e carrega o que quer que o apelido nomeie. Salve-o como `champion.py`:

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

Os dois programas novos são código como qualquer outro, então são commitados primeiro; o
`log_run.py` recusaria de outro jeito, já que os seus dois arquivos seriam a mudança não commitada.

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

O MLflow imprime algumas linhas `INFO` próprias na primeira vez que cria o banco; elas aparecem aqui
porque são o que você vai ver. A execução é registrada como **versão 1**, e o `champion.py 1` aponta
o apelido `champion` para ela. As últimas linhas são o modelo **carregado pelo apelido**,
`models:/lapse@champion`, pontuando três membros: perto dos 0,129, 0,087 e 0,121 que o `classify.py`
da lição 2 deu aos mesmos membros, de um modelo treinado um mês depois.

**O apelido é o que a produção usa.** Um job em lote ou um serviço carrega `models:/lapse@champion`,
e promover uma versão nova é mover o apelido, uma chamada, sem mudar nada no que o carrega. Voltar
atrás é movê-lo de volta. A lição 8 carrega o modelo desse jeito, e a lição 10 move o apelido.
