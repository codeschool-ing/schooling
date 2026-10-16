---
title: Busca em grade
version: 1
---

O jeito óbvio de buscar é listar os valores que vale testar para cada hiperparâmetro e ajustar toda
combinação. Isso é uma **grade**, e o `GridSearchCV` faz isso: para cada combinação, validação
cruzada, e depois reajusta a melhor em todas as linhas de treino. Três taxas, três tamanhos de árvore
e dois números de árvores dão 3 × 3 × 2 = 18 candidatos, e com três partes, 54 ajustes. O `n_jobs=-1`
os roda em todos os processadores de uma vez. Salve isto como `grid.py`:

```python
# grid.py
import time

import pandas as pd
from sklearn.model_selection import GridSearchCV

from feira import by_time, load_churn
from tuning import FEATURES, booster, time_folds, value_per_thousand

train, _ = by_time(load_churn())
grid = {"learning_rate": [0.03, 0.1, 0.3],
        "max_leaf_nodes": [7, 31, 63],
        "max_iter": [100, 300]}
start = time.perf_counter()
search = GridSearchCV(booster(), grid, cv=list(time_folds(train)),
                      scoring=value_per_thousand, n_jobs=-1)
search.fit(train[FEATURES], train["churned"])
print(f"{len(search.cv_results_['params'])} candidates x 3 folds, {time.perf_counter() - start:.0f} s")
results = pd.DataFrame(search.cv_results_)[["params", "mean_test_score", "std_test_score"]]
for _, row in results.sort_values("mean_test_score", ascending=False).head(5).iterrows():
    print(f"  {row['mean_test_score']:6.0f} +/- {row['std_test_score']:4.0f}  {row['params']}")
print("worst:", f"{results['mean_test_score'].min():.0f}")
```

```
ana@lab:~/ml$ python grid.py
18 candidates x 3 folds, 17 s
     757 +/-  193  {'learning_rate': 0.1, 'max_iter': 100, 'max_leaf_nodes': 7}
     726 +/-  138  {'learning_rate': 0.03, 'max_iter': 300, 'max_leaf_nodes': 7}
     714 +/-  171  {'learning_rate': 0.03, 'max_iter': 100, 'max_leaf_nodes': 7}
     710 +/-  146  {'learning_rate': 0.1, 'max_iter': 300, 'max_leaf_nodes': 7}
     705 +/-  132  {'learning_rate': 0.03, 'max_iter': 100, 'max_leaf_nodes': 31}
worst: 255
```

**A melhor combinação faz R$ 757 por mil linhas, contra R$ 610 dos padrões**, e a pior faz R$ 255: os
botões importam. As cinco melhores usam árvores pequenas, 7 folhas, contra 31 do padrão. Essa é uma
informação que a grade achou e ninguém adivinhou.

Mas olhe os números ao lado das notas: **o desvio-padrão entre as três partes fica entre 132 e 193 em
cada uma das cinco melhores.** A diferença entre o primeiro e o quinto lugar é 52. A ordem entre eles é
quase toda sorte, e o resumo honesto da grade é *árvores pequenas são melhores aqui*, não *esta linha
exata é a melhor*.

## O que uma grade custa

Uma grade cresce por multiplicação. Três valores de cinco hiperparâmetros são 3⁵ = 243 candidatos;
cinco valores de cada são 3.125. E a maioria desses ajustes é desperdiçada quando, como é comum, só um
ou dois dos hiperparâmetros importam muito: a grade gasta quase todo o orçamento variando botões que
não mudam nada, enquanto testa só três valores do que muda. A próxima seção é a correção disso.
