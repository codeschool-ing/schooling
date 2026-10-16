---
title: O que quebra quando a preparação é feita à mão
version: 1
---

Toda regressão logística deste curso até aqui foram três ou quatro objetos segurados juntos pelo
programa em volta deles: um dicionário de medianas, uma chamada ao `get_dummies`, um `StandardScaler`, o
modelo. Cada um foi ajustado nas linhas de treino e aplicado nas de teste, na ordem certa, à mão.
Funcionou, porque as linhas de teste vinham do mesmo arquivo, lido do mesmo jeito, algumas linhas
depois.

Agora use o modelo em dados novos. Em 2026 a Feira em Casa exporta o `churn_2026.csv`, três meses novos
de assinantes no mesmo formato, e a equipe de retenção quer as chances deles. O modelo da aula 5 é
ajustado exatamente como antes e depois perguntado sobre o arquivo novo. Salve isto como `by_hand.py`:

```python
# by_hand.py
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

from feira import CATEGORICAL, NUMERIC, by_time, load_churn

train, _ = by_time(load_churn())
new = load_churn("data/churn_2026.csv")
medians = train[NUMERIC].median()

def table(rows):
    numbers = rows[NUMERIC].fillna(medians)
    words = pd.get_dummies(rows[CATEGORICAL], drop_first=True, dtype=float)
    return pd.concat([numbers, words], axis=1)

scale = StandardScaler().fit(table(train))
model = LogisticRegression(max_iter=1000).fit(scale.transform(table(train)), train["churned"])
print(f"churn_2026.csv: {len(new):,} rows; plans {sorted(new['plan'].unique())}")
chance = model.predict_proba(scale.transform(table(new)))[:, 1]
```

```
ana@lab:~/ml$ python by_hand.py
churn_2026.csv: 13,154 rows; plans ['fortnightly', 'monthly', 'weekly']
Traceback (most recent call last):
  File "/home/ana/ml/by_hand.py", line 20, in <module>
    chance = model.predict_proba(scale.transform(table(new)))[:, 1]
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/sklearn/utils/_set_output.py", line 327, in wrapped
    data_to_wrap = f(self, X, *args, **kwargs)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/sklearn/preprocessing/_data.py", line 1111, in transform
    X = validate_data(
        ^^^^^^^^^^^^^^
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/sklearn/utils/validation.py", line 3016, in validate_data
    _check_feature_names(_estimator, X, reset=reset)
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/sklearn/utils/validation.py", line 2868, in _check_feature_names
    raise ValueError(message)
ValueError: The feature names should match those that were passed during fit.
Feature names unseen at fit time:
- plan_monthly
```

O arquivo novo tem um plano que o antigo nunca teve, o **mensal**, lançado em 2026. O `get_dummies` faz
colunas com os valores que a tabela à sua frente tiver, então no arquivo novo ele fez uma a mais,
`plan_monthly`, e a escala, que lembra as 22 colunas com que foi ajustada, recusou a 23ª. Leia a última
linha do erro, como a aula 1 disse: ela dá o nome da coluna.

O erro é o desfecho bom. Desfechos piores são fáceis de arranjar com o mesmo código:

- Se o arquivo novo tivesse **perdido** um valor, digamos nenhum assinante no boleto naquele mês, o
  `get_dummies` faria uma coluna a menos e as colunas depois dela andariam uma casa. Sem os nomes para
  conferir, um modelo alimentado com matrizes simples leria `plan_weekly` onde espera `payment_pix`, e
  não diria nada.
- As medianas moram numa variável. Um programa que as recalcula no arquivo novo, o que é uma linha
  descuidada, dá às linhas novas um preenchimento diferente daquele com que o modelo aprendeu.
- As sete colunas da aula 14 teriam de ser refeitas exatamente do mesmo jeito, pelo programa que pontua
  o arquivo novo, e mantidas em sincronia com o programa de treino por todo o tempo em que o modelo for
  usado.

Os três têm uma causa só. **A preparação faz parte do modelo**, e mora fora dele. O resto desta aula a
põe dentro, para que ajustar o modelo ajuste a preparação, e usar o modelo a aplique, do mesmo jeito
toda vez e em quaisquer linhas.
