---
title: Um assinante, explicado
version: 1
---

A equipe de retenção liga para os assinantes que recebem crédito, e quem liga sabendo por que o modelo
escolheu alguém tem uma conversa melhor do que quem lê um número. Pegue o assinante de que o modelo tinha
mais certeza em dezembro de 2025, e reparta a previsão dele. Salve isto como `shap_one.py`:

```python
# shap_one.py
import numpy as np
import pandas as pd
import shap
from lightgbm import LGBMClassifier

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
model = LGBMClassifier(n_estimators=200, learning_rate=0.05, random_state=0, verbose=-1)
model.fit(train[features], train["churned"])

december = test[test["snapshot"] == "2025-12-01"]
chance = model.predict_proba(december[features])[:, 1]
one = december.iloc[[np.argmax(chance)]]
explained = shap.TreeExplainer(model)(one[features])

print(f"{one['customer_id'].iloc[0]}, December 2025: chance {chance.max():.3f}")
print(f"starting point, the average subscriber: {explained.base_values[0]:+.2f}")
contributions = pd.Series(explained.values[0], index=features)
for column in contributions.abs().sort_values(ascending=False).index[:6]:
    print(f"  {column:18} = {str(one[column].iloc[0]):>8}   {contributions[column]:+.2f}")
total = explained.base_values[0] + contributions.sum()
print(f"sum of all {len(features)}: {total:+.2f}, which is a chance of {1 / (1 + np.exp(-total)):.3f}")
```

A última linha confere a promessa que o SHAP faz: o ponto de partida mais a contribuição de cada coluna,
transformados de log-odds de volta em chance, é exatamente a previsão do modelo.

```
ana@lab:~/ml$ python shap_one.py
C02724, December 2025: chance 0.883
starting point, the average subscriber: -3.50
  rating_90d         =     3.09   +2.86
  tenure_months      =        3   +0.61
  days_since_login   =     40.0   +0.60
  complaints_90d     =        1   +0.44
  late_90d           =        2   +0.41
  payment            =   boleto   +0.40
sum of all 16: +2.02, which is a chance of 0.883
```

**A soma é a previsão, até a terceira casa.** O ponto de partida, −3,50 em log-odds, é uma chance de cerca
de 3%: a saída média do modelo. As colunas deste assinante a levam a +2,02, uma chance de 0,883, e seis
colunas fazem a maior parte do trabalho.

Lido como uma frase para quem liga: *uma nota de 3,09 nos últimos noventa dias, de longe o maior motivo; só
três meses de assinatura; quarenta dias sem abrir o aplicativo; uma reclamação e duas entregas atrasadas;
paga com boleto.* Todo item é algo que quem liga pode mencionar, e dois deles, a reclamação e as caixas
atrasadas, são coisas que a empresa fez. É uma ligação bem diferente de *"nosso modelo acha que você pode
sair"*.

Dois cuidados. O SHAP explica **o modelo**, não o assinante: ele diz por que o modelo deu 0,883, e se o
modelo aprendeu algo errado, o SHAP explica o erro com fidelidade. E uma contribuição não é uma alavanca.
Subir a nota deste assinante não baixaria a chance dele em 2,86, porque a nota é um sintoma das caixas, não
um botão que a empresa pode girar. A próxima seção vai mais longe nisso.
