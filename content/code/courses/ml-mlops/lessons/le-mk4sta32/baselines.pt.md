---
title: Toda nota precisa de algo para vencer
version: 1
---

R$ 179,49 de erro parece ruim para membros que gastam algumas centenas de reais, e um modelo de
afastamento que aponta os membros certos parece bom. **Nenhuma das duas frases significa nada até
dizer comparado com quê.** A comparação que sempre existe é a **linha de base** (*baseline*): a
predição mais boba, que não usa atributo nenhum.

| tarefa | a linha de base |
| --- | --- |
| classificação | prever sempre a classe mais comum |
| regressão | prever sempre a média do rótulo de treino |
| recomendação | recomendar os títulos mais populares que o membro não tem |

O scikit-learn tem as duas primeiras como modelos próprios, então elas passam pelo mesmo `fit` e
`predict` dos modelos de verdade. Salve isto como `baseline.py`; ele importa `examples` do
`regress.py`:

```python
"""baseline.py: what the two models are worth against guessing."""
from sklearn.dummy import DummyClassifier, DummyRegressor
from sklearn.metrics import mean_absolute_error

import features
from regress import examples

train, test = examples("2025-09-30"), examples("2025-11-30")
X = features.NUMERIC

always_stays = DummyClassifier(strategy="most_frequent").fit(train[X], train["lapsed"])
print("always 'stays' predicts lapsed for", int(always_stays.predict(test[X]).sum()), "members")

average = DummyRegressor(strategy="mean").fit(train[X], train["spend_next_90d"])
guess = average.predict(test[X])
print(f"everybody spends the average: R$ {guess[0] / 100:.2f} each")
print(f"mean absolute error: R$ {mean_absolute_error(test['spend_next_90d'], guess) / 100:.2f}")
```

```
ana@dev:~/ml$ python baseline.py
always 'stays' predicts lapsed for 0 members
everybody spends the average: R$ 304.01 each
mean absolute error: R$ 213.76
```

**"Sempre fica" prevê que ninguém se afasta**, porque a maioria dos membros não se afasta: um modelo
sem informação nenhuma, e a lição 4 vai mostrá-lo tirando 83% na medida mais comum que existe. Essa
é a armadilha que dá nome àquela lição.

**"Todo mundo gasta a média" erra R$ 213,76 por membro.** A regressão errava R$ 179,49, então os
atributos compraram uma melhora de R$ 34,27, cerca de um sexto. Esse é o tamanho honesto do que o
modelo sabe, e é o número a pôr na frente de quem o pediu.

## Por que a linha de base é assunto da plataforma

Quem modela a calcula uma vez, enquanto escolhe um modelo. **A plataforma precisa continuar
calculando**, porque uma linha de base também se move: se a maioria dos membros começasse a se
afastar, "sempre fica" pioraria e um modelo poderia parecer melhor sabendo menos. A lição 9
acompanha a nota de um modelo em produção, e o número que ela acompanha é sempre um par: o modelo, e
a linha de base nas mesmas linhas.
