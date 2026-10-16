---
title: Reamostre depois da divisão, nunca antes
version: 1
---

A sobreamostragem copia linhas. Se a cópia acontece **antes** de os dados serem divididos entre a parte
de onde o modelo aprende e a parte em que ele é julgado, cópias da mesma pessoa caem dos dois lados. O
modelo então é julgado em parte por linhas que já viu, e a nota diz isso com confiança. É o vazamento da
aula 4, feito por uma ferramenta que parece um remédio.

O programa abaixo mede o mesmo modelo de três jeitos. As partes aqui são sorteadas e não por mês, o que a
aula 3 desaconselhou; a ideia é isolar a cópia, e os meses de teste no fim são a conferência honesta.
Salve isto como `leak.py`:

```python
# leak.py
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import KFold

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())

def oversample(rows):
    leavers = rows[rows["churned"] == 1]
    extra = leavers.sample(len(rows) - 2 * len(leavers), replace=True, random_state=0)
    return pd.concat([rows, extra])

def auc(learn, judge):
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
    model.fit(learn[features], learn["churned"])
    return roc_auc_score(judge["churned"], model.predict_proba(judge[features])[:, 1])

folds = KFold(5, shuffle=True, random_state=0)
before = oversample(train)
wrong = [auc(before.iloc[a], before.iloc[b]) for a, b in folds.split(before)]
right = [auc(oversample(train.iloc[a]), train.iloc[b]) for a, b in folds.split(train)]
print(f"oversampled, then split:   AUC {np.mean(wrong):.3f}")
print(f"split, then oversampled:   AUC {np.mean(right):.3f}")
print(f"the test months:           AUC {auc(oversample(train), test):.3f}")
```

O `oversample` acrescenta cópias de quem sai até as duas classes terem o mesmo tamanho. As duas linhas
do meio diferem só na ordem de dois passos.

```
ana@lab:~/ml$ python leak.py
oversampled, then split:   AUC 0.908
split, then oversampled:   AUC 0.793
the test months:           AUC 0.789
```

**0,908 contra 0,793.** O primeiro número é o que alguém relataria depois de sobreamostrar um arquivo e
depois rodar validação cruzada nele, e é um modelo que parece melhor que qualquer coisa da aula 8. Os
meses de teste, onde nenhuma cópia chegou, dizem 0,789, e as partes honestas disseram 0,793 o tempo
todo.

A regra vale além da cópia: **tudo o que é ajustado a partir dos dados acontece dentro da parte, depois
da divisão.** Reamostrar, escalar, preencher valores faltantes, escolher colunas. A aula 15 põe isso
dentro de um pipeline, para a ordem não poder ser errada à mão, e a `imbalanced-learn` tem um pipeline
próprio pelo mesmo motivo: ela só aplica a reamostragem ao ajustar, nunca ao pontuar.
