---
title: SHAP: repartindo cada previsão
version: 1
---

A importância por permutação e a dependência parcial descrevem o modelo como um todo. O **SHAP** (SHapley
Additive exPlanations) explica cada previsão separadamente, repartindo-a entre as colunas. Ele parte da saída
média do modelo e dá a cada coluna um número, seu **valor SHAP**, de modo que a média mais o valor de cada
coluna somem exatamente a previsão daquela linha. Um valor positivo empurrou a chance deste assinante para
cima, um negativo a puxou para baixo.

A repartição vem da teoria dos jogos: um valor de Shapley é a parte justa de cada jogador nos ganhos de um
time, em média em toda ordem em que os jogadores poderiam ter entrado. Para árvores há um jeito rápido e
exato de calculá-lo, e a biblioteca `shap` o tem para o LightGBM, o boosting que a aula 8 usou. A média do
tamanho dos valores SHAP de cada coluna em toda linha de teste também dá uma importância global. Salve isto
como `shap_global.py`:

```python
# shap_global.py
import numpy as np
import pandas as pd
import shap
from lightgbm import LGBMClassifier

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
model = LGBMClassifier(n_estimators=200, learning_rate=0.05, random_state=0, verbose=-1)
model.fit(train[features], train["churned"])
explained = shap.TreeExplainer(model)(test[features])

print(f"{explained.values.shape[0]:,} subscribers x {explained.values.shape[1]} columns of SHAP values")
average = pd.Series(np.abs(explained.values).mean(axis=0), index=features)
print(average.sort_values(ascending=False).head(8).round(3).to_string())
```

O `verbose=-1` deixa o LightGBM quieto ao ajustar. Os valores SHAP estão em log-odds, as unidades que um
classificador de boosting soma antes de transformar a soma em chance.

```
ana@lab:~/ml$ python shap_global.py
24,257 subscribers x 16 columns of SHAP values
rating_90d          0.484
tenure_months       0.392
complaints_90d      0.196
late_90d            0.178
skips_90d           0.154
days_since_login    0.146
payment             0.095
age                 0.089
```

A ordem concorda com a importância por permutação no topo, nota e depois tempo de casa, e acrescenta as
categorias, que o `importances.py` deixou de fora: `payment` é a sétima, o efeito do boleto da seção dos
pesos. Onde as duas discordam um pouco mais abaixo, o motivo é o que medem. A permutação pergunta quanto a
**nota** depende de uma coluna; o SHAP pergunta quanto as **previsões** se mexem com ela. Uma coluna pode
mexer nas previsões sem melhorá-las.

Uma ordem global é o resumo. O ponto do SHAP é a próxima seção: um assinante de cada vez.
