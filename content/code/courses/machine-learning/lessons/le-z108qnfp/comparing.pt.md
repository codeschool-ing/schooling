---
title: Comparando os ensembles com honestidade
version: 1
---

Todo modelo desta aula ganhou dinheiro nos meses de teste, e eles podem ser postos em fila:

| modelo | aula | R$ no teste |
|---|---|---|
| regressão logística | 5 | 16.424 |
| floresta aleatória, `max_features="sqrt"` | 8 | 18.584 |
| HistGradientBoosting, parada antecipada, taxa 0,03 | 8 | 21.296 |
| XGBoost | 8 | 21.656 |
| HistGradientBoosting, como na aula 2 | 2 | 21.672 |
| floresta aleatória, todas as colunas | 8 | 21.864 |
| LightGBM | 8 | 22.304 |
| 100 árvores em bagging | 8 | 23.384 |

A leitura tentadora é uma classificação com o bagging no topo. **A leitura honesta é que os
ensembles empatam.** O bootstrap da aula 2 pôs o ruído de uma nota de teste deste tamanho em vários
milhares de reais, e tudo de R$ 21.296 a R$ 23.384 cabe numa faixa assim. Outros seis meses, ou outra
semente, os reordenariam.

Isso é uma afirmação, então meça. Salve isto como `compare.py`; ele ajusta de novo os dois modelos de
boosting e faz o bootstrap da diferença entre eles por assinante, exatamente como o `beaten.py` fez na
aula 2:

```python
# compare.py
import lightgbm
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

train, test = by_time(load_churn())
features = NUMERIC + CATEGORICAL
cut = CREDIT / (SAVED * KEPT)

models = {
    "HistGradientBoosting": HistGradientBoostingClassifier(learning_rate=0.03, max_iter=2000,
        early_stopping=True, validation_fraction=0.15, n_iter_no_change=30,
        categorical_features="from_dtype", random_state=0),
    "LightGBM": lightgbm.LGBMClassifier(n_estimators=400, learning_rate=0.05, num_leaves=15,
        subsample=0.8, subsample_freq=1, colsample_bytree=0.8, random_state=0, verbose=-1),
}
send = {}
for name, model in models.items():
    model.fit(train[features], train["churned"])
    send[name] = model.predict_proba(test[features])[:, 1] >= cut
    print(f"{name:21} R$ {net_value(test['churned'], send[name]):,.0f}")

rng = np.random.default_rng(0)
rows = test.groupby("customer_id").indices
people = list(rows)
y = test["churned"].to_numpy()
gaps = []
for _ in range(1000):
    idx = np.concatenate([rows[people[i]] for i in rng.choice(len(people), len(people))])
    a, b = (net_value(y[idx], send[n][idx]) for n in models)
    gaps.append(b - a)
low, high = np.percentile(gaps, [2.5, 97.5])
print(f"LightGBM minus HistGradientBoosting: 95% of resamples between R$ {low:,.0f} and R$ {high:,.0f}")
```

```
ana@lab:~/ml$ python compare.py
HistGradientBoosting  R$ 21,296
LightGBM              R$ 22,304
LightGBM minus HistGradientBoosting: 95% of resamples between R$ -1,008 and R$ 3,176
```

O LightGBM fez R$ 1.008 a mais nestas linhas, e **o intervalo da diferença vai de −R$ 1.008 a
R$ 3.176**: ele cruza o zero com folga. O teste não consegue separar os dois, e o conselho da aula 2
vale: escolha por outra coisa.

O que a tabela mostra é um degrau. **Todo modelo de boosting, a floresta completa e as árvores em
bagging superam a regressão logística por uns R$ 5.000, e nenhum supera outro por mais que o ruído.**
A floresta limitada à raiz quadrada das colunas fica entre os dois grupos, pelo motivo que a seção da
floresta deu. Essa é a forma de costume em dados tabulares de negócio: o salto da reta para as
árvores é real, a escolha entre bons ensembles de árvores quase sempre não é. Então a escolha se faz
por motivos práticos:

- **uma floresta aleatória** quando os padrões precisam funcionar, ninguém vai otimizá-la, e
  probabilidades mais ou menos certas importam mais que os últimos mil reais;
- **o HistGradientBoosting do scikit-learn** quando o projeto quer uma biblioteca só e nada a instalar;
- **XGBoost ou LightGBM** quando os dados são grandes, a equipe já usa um deles, ou é preciso um
  recurso que só eles têm.

A Ana fica com o modelo HistGradientBoosting daqui em diante, pelo segundo motivo. A aula 9 o otimiza,
e pergunta se otimizar vale mais que o ruído.
