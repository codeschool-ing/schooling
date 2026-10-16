---
title: A matriz de confusão, contada
version: 1
---

A aula 1 desenhou os quatro resultados de uma previsão de sim ou não: verdadeiros e falsos positivos,
falsos e verdadeiros negativos. **Toda métrica de classificação desta aula é aritmética com essas
quatro contagens**, então o primeiro passo é contá-las para um modelo de verdade. O modelo é o
gradient boosting da aula 2 com os padrões, e o primeiro programa mede os meses de teste uma vez e
salva as notas, para que todo programa seguinte desta aula leia os mesmos números. Salve isto como
`scores.py`:

```python
# scores.py
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0)
model.fit(train[features], train["churned"])
test = test.assign(chance=model.predict_proba(test[features])[:, 1])
test[["customer_id", "snapshot", "churned", "chance"]].to_csv("scores.csv", index=False)
print(f"{len(test):,} test rows scored; saved scores.csv")
```

```
ana@lab:~/ml$ python scores.py
24,257 test rows scored; saved scores.csv
```

Um modelo como este dá uma **chance**, e as quatro contagens só existem depois que um **corte**
transforma a chance num sim ou num não. Vale comparar dois cortes: 0,5, o que toda biblioteca usa
quando se pede `predict`, e 0,278, o ponto de equilíbrio da aula 2. Salve isto como `confusion.py`:

```python
# confusion.py
import pandas as pd
from sklearn.metrics import confusion_matrix

from feira import CREDIT, KEPT, SAVED

scores = pd.read_csv("scores.csv")
for cut in [0.5, CREDIT / (SAVED * KEPT)]:
    said = (scores["chance"] >= cut).astype(int)
    tn, fp, fn, tp = confusion_matrix(scores["churned"], said).ravel()
    print(f"cut {cut:.3f}:  TP {tp:4}  FP {fp:4}  FN {fn:4}  TN {tn:6}")
```

```
ana@lab:~/ml$ python confusion.py
cut 0.500:  TP  117  FP   77  FN 1367  TN  22696
cut 0.278:  TP  348  FP  363  FN 1136  TN  22410
```

O `confusion_matrix` devolve as contagens numa ordem fixa, que o `ravel` achata em verdadeiros
negativos, falsos positivos, falsos negativos e verdadeiros positivos. Arrumadas como a aula 1 as
desenhou:

| corte 0,278 | o assinante saiu | o assinante ficou |
|---|---|---|
| **crédito enviado** | 348 verdadeiros positivos | 363 falsos positivos |
| **sem crédito** | 1.136 falsos negativos | 22.410 verdadeiros negativos |

**O corte move linhas entre as células.** Em 0,5 o modelo manda 194 créditos e acha 117 que saem; em
0,278 manda 711 e acha 348. Baixar o corte sempre transforma alguns falsos negativos em verdadeiros
positivos e alguns verdadeiros negativos em falsos positivos, e a pergunta de onde parar é da aula 11.
Esta aula trata de como ler os quatro números depois de escolhido um corte, e de como julgar um modelo
sem escolher nenhum.

Toda métrica abaixo ou escolhe um corte e resume as quatro células, ou resume o modelo em todos os
cortes de uma vez. Mantenha a tabela à vista; cada fórmula é uma razão entre duas das células.
