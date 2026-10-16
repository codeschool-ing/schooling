---
title: Dois tipos de importância, e uma coluna de ruído
version: 1
---

"Que colunas importam mais" tem duas respostas comuns para um modelo de árvores, e elas podem discordar
muito.

- A **importância por impureza**, `feature_importances_` numa floresta aleatória, soma quanto cada coluna
  reduziu a impureza dos cortes da aula 7, em todas as árvores. Ela vem de graça com o modelo ajustado.
- A **importância por permutação** embaralha uma coluna nas linhas de **teste**, quebrando a ligação dela
  com todo o resto, e mede quanto a nota do modelo cai. Uma coluna de que o modelo depende custa muito
  embaralhar; uma que ele ignora não custa nada.

Para ver em qual confiar, dê ao modelo algo que não pode importar. O programa abaixo acrescenta duas colunas
de puro acaso, `noise`, um número sorteado entre 0 e 1, e `coin`, um 0 ou 1 sorteado, e pede aos dois
métodos que as ordenem. Salve isto como `importances.py`:

```python
# importances.py
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.inspection import permutation_importance

from feira import NUMERIC, by_time, load_churn

train, test = by_time(load_churn())
rng = np.random.default_rng(0)
for rows in (train, test):
    rows["noise"] = rng.random(len(rows))
    rows["coin"] = rng.integers(0, 2, len(rows))
columns = NUMERIC + ["noise", "coin"]

forest = RandomForestClassifier(n_estimators=200, min_samples_leaf=5, random_state=0, n_jobs=-1)
forest.fit(train[columns].fillna(-1), train["churned"])
shuffled = permutation_importance(forest, test[columns].fillna(-1), test["churned"],
                                  scoring="roc_auc", n_repeats=5, random_state=0, n_jobs=-1)
table = pd.DataFrame({"impurity": forest.feature_importances_,
                      "permutation": shuffled.importances_mean}, index=columns)
print(table.sort_values("impurity", ascending=False).round(3).to_string())
```

A coluna de permutação é quanto a AUC de teste cai, em média em cinco embaralhamentos, quando só aquela
coluna é embaralhada.

```
ana@lab:~/ml$ python importances.py
                   impurity  permutation
rating_90d            0.265        0.091
noise                 0.133       -0.002
tenure_months         0.103        0.031
age                   0.101        0.001
days_since_login      0.090        0.011
skips_90d             0.062        0.008
late_90d              0.054        0.018
orders_90d            0.047       -0.001
price_month           0.045        0.003
complaints_90d        0.042        0.014
support_calls_90d     0.029       -0.001
coin                  0.021       -0.001
app_user              0.009       -0.000
```

**Por impureza, ruído puro é a segunda coluna mais importante do modelo**, acima do tempo de casa, dos dias
desde o login e de toda reclamação. Por permutação ela vale −0,002: embaralhá-la não muda nada.

O motivo é como a importância por impureza é ganha. Uma coluna com muitos valores diferentes oferece à
árvore muitos lugares para cortar, e com árvores fundas alguns desses cortes vão dividir as linhas de treino
de um jeito útil por pura sorte. Cada um é creditado à coluna. A `noise` tem 38.628 valores diferentes e
recebe muito desse crédito; a `coin`, com dois valores, recebe pouco, embora seja igualmente sem sentido. A
idade, com sessenta valores, é quarta por impureza e quase nada por permutação. **A importância por impureza
é enviesada a favor de colunas com muitos valores**, e nas linhas de treino ela não distingue aprender de decorar.

A importância por permutação é medida onde deve, em linhas de onde o modelo não aprendeu, em unidades que
querem dizer algo, aqui AUC. Ela é mais lenta, já que mede o modelo de novo muitas vezes, e divide mal o
crédito entre colunas correlacionadas: embaralhe uma de duas colunas que dizem a mesma coisa, e o modelo se
apoia na outra. Mas é ela que vai num relatório.
