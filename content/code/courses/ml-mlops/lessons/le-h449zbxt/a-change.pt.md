---
title: Uma mudança de uma linha
version: 1
---

Uma colega sugere uma correção comum para um desfecho raro: **pesar as classes**, para que os 17%
que
se afastam contem no treino tanto quanto os 83% que ficam. No scikit-learn isso é um argumento. Aqui
está o `model.py` com ele, mudado nessa linha e na docstring:

```python
"""model.py: the lapse model, defined once, for every program that trains it.

Version 2: class_weight="balanced" weighs the members who lapsed as much, in total,
as the members who stayed.
"""
from sklearn.compose import make_column_transformer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

import features

COLUMNS = features.NUMERIC + features.CATEGORICAL


def make_model():
    return make_pipeline(
        make_column_transformer(
            (StandardScaler(), features.NUMERIC),
            (OneHotEncoder(handle_unknown="ignore"), features.CATEGORICAL),
        ),
        LogisticRegression(max_iter=1000, class_weight="balanced"),
    )


def trained(cutoff):
    rows = features.build(cutoff)
    return make_model().fit(rows[COLUMNS], rows["lapsed"])
```

Salve-o por cima do `model.py` antigo, e deixe o DVC descobrir o que isso afeta:

```
ana@dev:~/ml$ dvc repro
'shop.db.dvc' didn't change, skipping
Stage 'dataset' didn't change, skipping
Running stage 'train':
> python train.py data/train.csv models/lapse.joblib
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "d04183235c0e66c2",
  "cutoff": "2025-08-31",
  "rows": 2863,
  "scikit_learn": "1.9.1"
}
Updating lock file 'dvc.lock'

Running stage 'evaluate':
> python evaluate.py models/lapse.joblib data/test.csv
{
  "test": "data/test.csv",
  "cutoff": "2025-11-30",
  "members": 3130,
  "lapsed": 530,
  "roc_auc": 0.791,
  "average_precision": 0.519,
  "baseline_average_precision": 0.169,
  "lapsed_in_top_300": 191,
  "said": 0.426
}
Updating lock file 'dvc.lock'

To track the changes with git, run:

	git add dvc.lock

To enable auto staging, run:

	dvc config core.autostage true
Use `dvc push` to send your updates to remote storage.
ana@dev:~/ml$ dvc metrics diff v1
Path                      Metric             v1     workspace    Change
models/lapse.scores.json  average_precision  0.522  0.519        -0.003
models/lapse.scores.json  lapsed_in_top_300  190    191          1
models/lapse.scores.json  roc_auc            0.793  0.791        -0.002
models/lapse.scores.json  said               0.177  0.426        0.249
ana@dev:~/ml$ git add . && git commit -qm "lapse model v2: balanced class weights" && python log_run.py
Registered model 'lapse' already exists. Creating a new version of this model...
Created version '2' of model 'lapse'.
run 170f9946, registered as lapse version 2
ana@dev:~/ml$ python champion.py
version 1  aliases ['champion']  commit ada6255  average precision 0.522  said 0.177
version 2  aliases []  commit d9f6d3a  average precision 0.519  said 0.426
 member_id  p_lapse
         1    0.123
         2    0.090
         3    0.106
```

**O DVC pulou o estágio do conjunto de dados**, porque nada de que ele depende mudou, **e rodou de
novo treino e avaliação**, porque o `model.py` é dependência do treino e o modelo é dependência da
avaliação. `dvc metrics diff v1` compara as notas do diretório de trabalho com as commitadas em
`v1`.

O diff é o argumento inteiro da lição em quatro linhas. **A ordenação quase não se mexeu**: precisão
média de 0,522 para 0,519, AUC de 0,793 para 0,791, um afastamento a mais nos 300 primeiros. **As
probabilidades se mexeram**: o modelo agora diz 0,426 em média, onde 0,169 dos membros se afastam.
Pesos balanceados dizem ao modelo que se afastar é tão comum quanto ficar, e ele acredita, então a
conta do limiar da lição 4, e qualquer previsão de quantos membros vão embora, erraria por mais do
dobro.

A mudança é commitada e registrada mesmo assim, como **versão 2**. O registro guarda o que foi
tentado além do que foi ao ar. O `champion.py` sem argumento mostra que o apelido não se moveu: **a
produção continua carregando a versão 1.** A decisão de não promover também é uma decisão, e as
notas
ao lado de cada versão são o motivo dela.
