---
title: Regressão, quando a resposta é uma quantia
version: 1
---

**Regressão responde com uma quantidade.** A pergunta desta seção: quanto cada membro ativo vai
gastar nos 90 dias depois do corte? São os mesmos membros e os mesmos atributos do modelo de
afastamento, e um rótulo diferente, que o `features.py` não calcula. Então o programa o acrescenta
com uma consulta própria. Salve-o como `regress.py`:

```python
"""regress.py: how much will each active member spend in the next 90 days?"""
import sqlite3

import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error

import features

SPEND_AFTER = """
SELECT p.member_id, sum(l.price_cents) AS spend_next_90d
FROM purchases p JOIN lines l USING (purchase_id)
WHERE p.day > :cutoff AND p.day <= date(:cutoff, '+90 days')
GROUP BY p.member_id
"""


def examples(cutoff):
    rows = features.build(cutoff)
    with sqlite3.connect("shop.db") as db:
        after = pd.read_sql_query(SPEND_AFTER, db, params={"cutoff": cutoff})
    rows = rows.merge(after, on="member_id", how="left")
    rows["spend_next_90d"] = rows["spend_next_90d"].fillna(0)   # no visit: spent nothing
    return rows


if __name__ == "__main__":
    train, test = examples("2025-09-30"), examples("2025-11-30")
    model = LinearRegression().fit(train[features.NUMERIC], train["spend_next_90d"])
    test["predicted"] = model.predict(test[features.NUMERIC]).round()

    print(test[["member_id", "visits_180d", "spend_180d", "predicted", "spend_next_90d"]]
          .head(4).to_string(index=False))
    print(f"mean absolute error: R$ {mean_absolute_error(test['spend_next_90d'], test['predicted']) / 100:.2f}")
```

`examples` junta o gasto depois do corte aos atributos antes dele. **A linha `fillna(0)` é uma
decisão, não uma arrumação**: um membro sem visita nos 90 dias não tem linha na consulta, e "não
gastou nada" é o valor verdadeiro para ele, então faltante vira zero. Em outro conjunto de dados um
valor faltante quer dizer "não sabemos", e preenchê-lo com zero ensinaria ao modelo algo falso.

A linha `if __name__ == "__main__":` faz o treino abaixo dela rodar quando você digita
`python regress.py`, e não quando outro programa importa `examples` dele, o que a próxima seção faz.

`LinearRegression` ajusta um peso por atributo e os soma, sem probabilidade no fim.

```
ana@dev:~/ml$ python regress.py
 member_id  visits_180d  spend_180d  predicted  spend_next_90d
         1            5       32930    28375.0          8980.0
         2            4       33940    29732.0          3990.0
         3            4       33940    27933.0         22960.0
         7            7       56900    34937.0         69880.0
mean absolute error: R$ 179.49
```

Leia as quatro linhas uma contra a outra. Os membros 2 e 3 tinham histórias idênticas, quatro
visitas e R$ 339,40, e o modelo previu quase o mesmo para os dois, uns R$ 297 e R$ 279. Um depois
gastou R$ 39,90 e o outro R$ 229,60. **Nenhum modelo que só vê o passado conseguiria distinguir esses
dois**, e esse é o estado normal de uma regressão: o erro se espalha em volta da verdade, e a
pergunta útil é o quão largo.

O **erro absoluto médio** é a resposta mais simples: a distância média entre predição e verdade, na
unidade do rótulo. Aqui ele é de R$ 179,49 por membro. Se isso é bom não é algo que o número
consegue dizer sozinho, e esse é o assunto da próxima seção.
