---
title: XGBoost
version: 1
---

O **XGBoost** tornou o gradient boosting a resposta padrão para tabelas por volta de 2015, vencendo
uma competição atrás da outra, e ainda está entre as bibliotecas mais usadas para isso. As ideias são
as de cima, mais três que importam na prática:

- **regularização dentro das árvores**: uma penalidade no número de folhas e no tamanho do valor de
  cada folha, no espírito do ridge da aula 5, para uma árvore só criar uma folha em que os dados
  insistem;
- **subamostragem**: o `subsample` ajusta cada árvore numa parte aleatória das linhas, e o
  `colsample_bytree` numa parte aleatória das colunas, emprestando o truque da floresta para deixar as
  árvores mais diferentes;
- **velocidade**, pelo mesmo método de histogramas da seção anterior, `tree_method="hist"`, que é o
  padrão nas versões recentes.

Ele segue as convenções do scikit-learn, `fit` e `predict_proba`, então entra nos mesmos programas. O
`enable_categorical=True` deixa que ele leia categorias do pandas direto. Salve isto como `xgb.py`:

```python
# xgb.py
import time

import xgboost

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

start = time.perf_counter()
model = xgboost.XGBClassifier(n_estimators=400, learning_rate=0.05, max_depth=4,
                              subsample=0.8, colsample_bytree=0.8,
                              enable_categorical=True, tree_method="hist", random_state=0)
model.fit(train[features], train["churned"])
send = model.predict_proba(test[features])[:, 1] >= cut
print(f"XGBoost {xgboost.__version__}: R$ {net_value(test['churned'], send):,.0f}, "
      f"{send.sum():,} credits, {time.perf_counter() - start:.1f} s")
```

```
ana@lab:~/ml$ python xgb.py
XGBoost 3.4.1: R$ 21,656, 751 credits, 0.7 s
```

**R$ 21.656**, em menos de um segundo. Os ajustes foram escolhidos à mão para serem razoáveis, não
otimizados: 400 árvores com taxa 0,05, quatro níveis, 80% das linhas e das colunas para cada árvore. A
aula 9 os otimiza.

O XGBoost instalado aqui é o `xgboost-cpu`, a versão sem suporte a placa de vídeo, como a aula 1
explicou. Numa máquina com uma placa adequada, a versão completa ajusta com `device="cuda"`; em
tabelas deste tamanho o processador é rápido o bastante para não fazer diferença prática.
