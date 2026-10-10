---
title: A coluna da tabela de hoje
version: 1
---

A maioria dos warehouses mantém um resumo por cliente, reconstruído toda noite: última visita, total
gasto, número de pedidos. É a tabela certa para um painel, que quer o presente. **É a tabela errada
para treino, que quer o passado**, e é o primeiro lugar onde um engenheiro de dados vai buscar um
atributo, porque ele já está lá.

Este programa treina o modelo de afastamento duas vezes. Uma com o `recency_days` do `features.py`,
calculado em relação ao corte. Outra com a mesma coluna calculada a partir de um resumo noturno da
visita mais recente de cada membro, do jeito que essa tabela estaria em 28 de fevereiro. Salve-o
como `leak.py`:

```python
"""leak.py: the same model, given one column read from today's table instead of the cutoff's."""
import sqlite3

import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

import features

# a summary table the way many warehouses keep one: rebuilt every night, one row
# per member, holding their latest visit as of the last night it was rebuilt
LATEST = "SELECT member_id, max(day) AS last_visit FROM purchases GROUP BY member_id"


def examples(cutoff, leaky):
    rows = features.build(cutoff)
    if leaky:
        with sqlite3.connect("shop.db") as db:
            latest = pd.read_sql_query(LATEST, db)
        rows = rows.merge(latest, on="member_id")
        rows["recency_days"] = (pd.Timestamp(cutoff) - pd.to_datetime(rows["last_visit"])).dt.days
    return rows


for leaky in (False, True):
    train, test = examples("2025-09-30", leaky), examples("2025-11-30", leaky)
    model = LogisticRegression(max_iter=1000).fit(train[features.NUMERIC], train["lapsed"])
    p = model.predict_proba(test[features.NUMERIC])[:, 1]
    print(f"recency from {'the summary table' if leaky else 'the cutoff       '}: "
          f"test AUC {roc_auc_score(test['lapsed'], p):.3f}")

# in production the summary table can only hold the past, so the model meets
# the honest column it was never trained on
train, live = examples("2025-09-30", True), examples("2025-11-30", False)
model = LogisticRegression(max_iter=1000).fit(train[features.NUMERIC], train["lapsed"])
p = model.predict_proba(live[features.NUMERIC])[:, 1]
print(f"trained on the summary table, used in production: AUC {roc_auc_score(live['lapsed'], p):.3f}, "
      f"members predicted to lapse {(p > 0.5).sum()} of {len(live)}, actually {live['lapsed'].sum()}")

print(examples("2025-11-30", True)[["member_id", "last_visit", "recency_days", "lapsed"]]
      .head(3).to_string(index=False))
```

```
ana@dev:~/ml$ python leak.py
recency from the cutoff       : test AUC 0.790
recency from the summary table: test AUC 0.994
trained on the summary table, used in production: AUC 0.787, members predicted to lapse 2450 of 3130, actually 530
 member_id last_visit  recency_days  lapsed
         1 2025-12-14           -14       0
         2 2026-02-25           -87       0
         3 2026-02-27           -89       0
```

**0,994.** O segundo modelo é quase perfeito no seu conjunto de teste, e as três últimas linhas
dizem como. A visita mais recente do membro 1, como o resumo a guarda, é 14 de dezembro, depois do
corte de 30 de novembro, então a recência dele sai **negativa**: -14 dias. Uma recência negativa quer
dizer "voltou", que é o rótulo. O modelo aprendeu a lê-lo, e as linhas de teste, montadas a partir do
mesmo resumo, o recompensaram.

**Depois vem a terceira linha, que é o que a produção teria feito.** Na noite de um corte de verdade o
resumo só pode guardar visitas até aquela noite, então a recência nunca é negativa, e o modelo
encontra uma coluna com a qual nunca foi treinado. Ele ainda ordena os membros mais ou menos na
ordem certa, AUC 0,787, mas as probabilidades dele são absurdas: **ele prevê que 2.450 de 3.130
membros vão se afastar, quando 530 se afastaram.** Qualquer limiar escolhido a partir dos resultados
de teste dele, qualquer orçamento de vouchers, qualquer previsão de receita perdida estaria errada
por um fator de quatro.

## A correção está nos dados, não no modelo

O modelo não fez nada errado. **Um atributo precisa ser calculado em relação ao momento da
predição**, e para isso a plataforma precisa ou do histórico para calculá-lo (a tabela de compras,
que é o que o `features.py` lê) ou de fotografias do resumo como ele estava a cada noite, guardadas
em vez de sobrescritas. A lição 6 chama o resultado de junção no ponto do tempo (*point-in-time
join*), e o constrói.

A verificação que pega esse tipo de vazamento custa uma consulta: **para cada atributo, o valor dele
na data do corte poderia ter sido calculado na data do corte?** Uma recência negativa, um "total de
pedidos" maior que os pedidos antes do corte, uma coluna de status com um valor que ainda não
existia: cada um é um vazamento com a sua impressão digital deixada nas linhas.
