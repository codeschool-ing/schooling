---
title: A armadilha da acurácia
version: 1
---

**Acurácia é a fração de predições certas**, e é a primeira nota que todo mundo pede porque não
precisa de explicação. Para o modelo de afastamento ela também é quase inútil, e o motivo é um número
da lição 2: a maioria dos membros não se afasta.

Todo programa desta lição treina o mesmo modelo, então ele é definido uma vez. Salve isto como
`model.py`:

```python
"""model.py: the lapse model, defined once, for every program that trains it."""
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
        LogisticRegression(max_iter=1000),
    )


def trained(cutoff):
    rows = features.build(cutoff)
    return make_model().fit(rows[COLUMNS], rows["lapsed"])
```

`make_model` é o pipeline da lição 2: escala, one-hot e regressão logística. `trained` monta os
exemplos de um corte e ajusta um modelo a eles. Daqui em diante, um programa que precisa do modelo de
afastamento o importa, e **o modelo tem uma definição no projeto em vez de uma por programa**, do que
a lição 5 depende.

Agora a nota. Salve isto como `accuracy.py`:

```python
"""accuracy.py: the lapse model's accuracy, and a model that knows nothing."""
from sklearn.metrics import accuracy_score

import features
from model import COLUMNS, trained

lapse = trained("2025-09-30")
test = features.build("2025-11-30")

predicted = lapse.predict(test[COLUMNS])
nobody = [0] * len(test)                       # "every member stays"

print(f"members in the test:      {len(test)}")
print(f"of whom lapsed:           {test['lapsed'].sum()} ({test['lapsed'].mean():.1%})")
print(f"accuracy, lapse model:    {accuracy_score(test['lapsed'], predicted):.1%}")
print(f"accuracy, 'nobody lapses': {accuracy_score(test['lapsed'], nobody):.1%}")
```

```
ana@dev:~/ml$ python accuracy.py
members in the test:      3130
of whom lapsed:           530 (16.9%)
accuracy, lapse model:    86.0%
accuracy, 'nobody lapses': 83.1%
```

**86,0% parece um modelo. 83,1% é um modelo que não sabe nada**: ele diz que todo membro fica, e
acerta todo membro que ficou, que é a maioria. Tudo o que o modelo de afastamento aprendeu com dez
atributos vale 2,9 pontos de acurácia, e um gestor que visse 86% nunca adivinharia isso.

A armadilha é geral. Sempre que um desfecho é muito mais comum que o outro, **a acurácia mede
sobretudo o quão comum é o desfecho comum.** Fraude é mais rara que afastamento, e um modelo de
fraude que nunca aponta nada tira 99,9% na maioria dos dados de pagamento. Quanto mais raro aquilo
que importa, mais a acurácia recompensa ignorá-lo.

O que a substitui depende de para que serve o modelo, e isso exige desmontar as respostas: não certo
ou errado, mas **certo ou errado em qual direção**.
