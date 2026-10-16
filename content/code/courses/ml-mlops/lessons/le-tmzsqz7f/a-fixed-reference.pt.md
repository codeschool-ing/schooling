---
title: Uma referência que não se move
version: 1
---

**A referência fixa são os dados com que o campeão aprendeu**, `data/train.csv`, os membros em 31 de
agosto de 2025. Comparar uma noite com eles responde a pergunta que a deriva faz: quão longe a
população desta noite está daquela que o modelo conhece? Este programa mede isso para cada entrada,
nas noites que receber. Salve-o como `drift.py`:

```python
"""drift.py: how far each input has moved from the data the champion learned from.

    python drift.py 2026-03-01 2026-04-26 2026-06-28
"""
import sqlite3
import sys

import numpy as np
import pandas as pd
from scipy.stats import ks_2samp

import features
from featurestore import STORE
from project import DATA

learned = pd.read_csv(DATA / "train.csv")
nights = sys.argv[1:]
with sqlite3.connect(STORE) as db:
    seen = {night: pd.read_sql_query("SELECT * FROM offline WHERE as_of = ?", db, params=(night,))
            for night in nights}


def shares(values, bins):
    counts = values.value_counts() if bins is None else pd.Series(np.histogram(values, bins)[0])
    return (counts / len(values)).clip(lower=0.0001)       # an empty bin would divide by zero


def psi(before, after, numeric):
    """Population stability index: 0 is unchanged, above 0.25 is a different population."""
    bins = None
    if numeric:
        bins = np.unique(np.quantile(before, np.linspace(0, 1, 11)))   # ten slices of the past
        bins[0], bins[-1] = -np.inf, np.inf
    b, a = shares(before, bins), shares(after, bins)
    b, a = b.align(a, fill_value=0.0001)
    return float(((a - b) * np.log(a / b)).sum())


print(f"{'':16}" + "".join(f"{night:>22}" for night in nights))
print(f"{'':16}" + "".join(f"{'PSI':>14}{'KS':>8}" for _ in nights))
for column in features.NUMERIC + features.CATEGORICAL:
    numeric = column in features.NUMERIC
    cells = []
    for night in nights:
        after = seen[night][column]
        ks = f"{ks_2samp(learned[column], after).statistic:.3f}" if numeric else "-"
        cells.append(f"{psi(learned[column], after, numeric):>14.3f}{ks:>8}")
    print(f"{column:16}" + "".join(cells))
```

Ele usa duas medidas, porque cada uma é fácil de ler errado sozinha:

- **o índice de estabilidade populacional, PSI**, corta os valores do treino em dez fatias de mesmo
  tamanho, conta a fração dos membros desta noite em cada fatia e soma o quanto cada fração se
  moveu, pesado pelo logaritmo da razão. 0 é sem mudança; a regra de bolso da análise de crédito, de
  onde o índice vem, lê abaixo de 0,1 como estável, de 0,1 a 0,25 como digno de uma olhada, e acima
  de 0,25 como outra população. Ele funciona também para categorias, uma fatia por categoria;
- **a estatística de Kolmogorov-Smirnov, KS**, do SciPy, é a maior distância entre as duas
  distribuições acumuladas, entre 0 e 1. O valor-p fica de fora de propósito: com três mil membros
  de cada lado, qualquer diferença é "significativa", e um teste que é sempre significativo não diz
  nada.

Numa noite uma semana depois do começo do curso, numa dois meses depois, e na última:

```
ana@dev:~/ml$ python drift.py 2026-03-01 2026-04-26 2026-06-28
                            2026-03-01            2026-04-26            2026-06-28
                           PSI      KS           PSI      KS           PSI      KS
tenure_days              0.142   0.146         0.197   0.176         0.259   0.212
recency_days             0.004   0.029         0.010   0.040         0.040   0.087
visits_180d              0.002   0.012         0.010   0.025         0.006   0.023
spend_180d               0.011   0.014         0.007   0.019         0.009   0.027
basket_avg               0.004   0.018         0.008   0.016         0.008   0.021
online_share             0.014   0.042         0.168   0.193         0.602   0.324
shops_180d               0.004   0.018         0.007   0.032         0.062   0.062
channel                  0.420       -         0.602       -         0.756       -
age_band                 0.000       -         0.001       -         0.002       -
home_shop                0.013       -         0.022       -         0.032       -
```

Três entradas se moveram, e são três histórias diferentes:

- **`online_share` foi de 0,014 a 0,602**, além de qualquer limite, e quase tudo depois de março. É o
  frete grátis: membros que antes entravam numa loja agora pedem online. O modelo nunca viu essa
  população.
- **`channel` já estava em 0,420 na primeira noite.** O aplicativo chegou em setembro de 2025,
  depois do corte do treino, então o modelo aprendeu com membros sem nenhum canal `app`, e o
  codificador dele transforma `app` em zeros. O vigia noturno nunca o apontou, porque `app` estava em
  todas as suas janelas de quatro semanas.
- **`tenure_days` derivou sem parar até 0,259**, porque a base de membros envelhece todo dia. Isso é
  deriva e não faz mal: nada nos membros mudou além do calendário.

**Deriva é um motivo para olhar, não um veredito.** O PSI diz que a população se moveu; se o modelo
piorou nela é uma pergunta que só os desfechos respondem, e é a próxima seção.
