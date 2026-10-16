---
title: O que dá para conferir no dia
version: 1
---

No dia 1º do mês, as respostas do modelo não podem ser avaliadas: ninguém saiu ainda. O que dá para
conferir é a entrada. O modelo aprendeu com uma população, e se os assinantes deste mês parecem
diferentes dessa população, as chances dele estão sendo aplicadas num lugar onde ele não esteve. Isso é
**deriva de dados** (*data drift*): as entradas mudam.

A medida comum para uma coluna é o **índice de estabilidade da população** (*population stability
index*). Corte os valores de treino em dez faixas com a mesma contagem, veja que parte dos valores deste
mês cai em cada uma e some quanto cada parte se mexeu, ponderado pelo quanto o movimento surpreende. Ele é 0
para uma coluna que não se mexeu; por uma regra prática muito usada em score de crédito, abaixo de 0,1 é
estável, de 0,1 a 0,25 vale uma olhada e acima de 0,25 é um deslocamento grande. Para uma coluna de
palavras as faixas são os valores dela. Salve isto como `inputs.py`:

```python
# inputs.py
import numpy as np
import pandas as pd

import stored
from feira import CATEGORICAL, NUMERIC, load_churn


def stability(before, after, bins=10):
    """Population stability index: how far a column has moved, 0 when not at all."""
    if before.dtype == "category":
        was = before.astype(str).value_counts(normalize=True)
        now = after.astype(str).value_counts(normalize=True)
        was, now = was.align(now, fill_value=0)
    else:
        before, after = before.dropna(), after.dropna()
        edges = np.unique(before.quantile(np.linspace(0, 1, bins + 1)))
        edges[0], edges[-1] = -np.inf, np.inf
        was = np.histogram(before, edges)[0] / len(before)
        now = np.histogram(after, edges)[0] / len(after)
    was, now = np.clip(was, 1e-4, None), np.clip(now, 1e-4, None)
    return float(np.sum((now - was) * np.log(now / was)))


_, card = stored.load("churn-2025-12")
train = load_churn(card["data"])
new = load_churn("data/churn_2026.csv")
months = {str(m.date())[:7]: rows for m, rows in new.groupby("snapshot")}

table = pd.DataFrame({m: {c: stability(train[c], rows[c]) for c in NUMERIC + CATEGORICAL}
                      for m, rows in months.items()})
print("stability index against the training rows (above 0.25 is a large shift):")
print(table.round(3).to_string())

for col in CATEGORICAL:
    unseen = {m: rows[col][~rows[col].isin(train[col].unique())] for m, rows in months.items()}
    for m, values in unseen.items():
        if len(values):
            print(f"{m}: {col} = {', '.join(values.unique())} in {len(values) / len(months[m]):.1%} of rows,"
                  f" never seen in training")
```

As linhas de treino vêm da ficha: `card["data"]` é o arquivo com que o modelo aprendeu, mais um motivo
para a aula 21 tê-lo anotado. O `1e-4` impede que uma faixa vazia vire uma divisão por zero, e é por isso
que um valor nunca visto dá um índice alto em vez de infinito.

```
ana@lab:~/ml$ python inputs.py
stability index against the training rows (above 0.25 is a large shift):
                   2026-01  2026-02  2026-03
age                  0.003    0.002    0.002
app_user             0.000    0.000    0.000
tenure_months        0.144    0.161    0.173
price_month          0.622    0.620    0.636
orders_90d           0.004    0.011    0.042
skips_90d            0.001    0.004    0.005
late_90d             0.002    0.002    0.002
complaints_90d       0.000    0.000    0.000
support_calls_90d    0.000    0.000    0.000
rating_90d           0.020    0.017    0.019
days_since_login     0.003    0.003    0.003
city                 0.001    0.001    0.001
payment              0.001    0.001    0.002
plan                 0.001    0.240    0.472
box                  0.000    0.000    0.001
channel              0.000    0.000    0.000
2026-02: plan = monthly in 4.0% of rows, never seen in training
2026-03: plan = monthly in 7.1% of rows, never seen in training
```

Três coisas se mexeram, e cada uma precisa de uma pessoa para dizer se importa:

- **`plan` pula de 0,001 para 0,240 e 0,472**, e as duas últimas linhas dizem por quê: um plano que o
  modelo nunca viu, 4,0% de fevereiro e 7,1% de março. É neste que se deve agir. O codificador da aula 15
  dá zeros a ele, a aula 19 mostrou que os zeros tornam as chances dele em parte um artefato, e uma parte
  que quase dobrou em um mês é uma parte que vai pesar.
- **`price_month` fica acima de 0,6 em todo mês.** É o aumento de preço de setembro: a maioria das linhas
  de treino é de antes dele, e todo preço de 2026 é 12% mais alto. O índice está certo, e o alarme é
  notícia velha. Um alarme que toca desde setembro vai ser ignorado em dezembro, e esse é o argumento
  para medir contra os meses **recentes** além das linhas de treino.
- **`tenure_months` fica entre 0,14 e 0,17**, vale uma olhada e nada mais: o negócio está crescendo,
  então cada mês tem um pouco mais de assinantes novos que os meses de treino tinham.

E uma coisa não se mexeu, o que importa tanto quanto: **`city` está em 0,001.** A mesma parte dos
assinantes mora em cada cidade, como sempre. Guarde isso: ele volta daqui a duas seções.

As conferências de entrada cobrem também o que esta tabela não mostra: uma coluna que de repente vem toda
vazia, um valor impossível, um arquivo com metade das linhas de costume. Esses são defeitos no caminho de
entrada, o desalinhamento da aula 21 de novo, e são a coisa mais comum que uma conferência mensal acha.
