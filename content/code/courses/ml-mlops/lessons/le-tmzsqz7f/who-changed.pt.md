---
title: Quem mudou
version: 1
---

Um boletim para todo mundo esconde uma mudança em alguém. **Divida o mesmo boletim pelos grupos que o
negócio reconhece**, loja de origem e idade aqui, e compare o que o modelo disse com o que aconteceu
em cada um. Salve isto como `segments.py`:

```python
"""segments.py: one night's report card, split by home shop and age, to find who changed.

    python segments.py 2026-03-29
"""
import datetime as dt
import sqlite3
import sys

import pandas as pd

from featurestore import STORE
from project import LABEL_DAYS, ROOT, SHOP

night = sys.argv[1]
closes = (dt.date.fromisoformat(night) + dt.timedelta(days=LABEL_DAYS)).isoformat()
with sqlite3.connect(SHOP) as db:
    bought = pd.read_sql_query("SELECT DISTINCT member_id FROM purchases "
                               "WHERE day > ? AND day <= ?", db, params=(night, closes))
with sqlite3.connect(ROOT / "scores.db") as db:
    scores = pd.read_sql_query("SELECT * FROM lapse_scores WHERE cutoff = ?", db, params=(night,))
with sqlite3.connect(STORE) as db:
    who = pd.read_sql_query("SELECT member_id, home_shop, age_band FROM offline WHERE as_of = ?",
                            db, params=(night,))

rows = scores.merge(who, on="member_id")
rows["lapsed"] = (~rows["member_id"].isin(bought["member_id"])).astype(int)
rows["age"] = rows["age_band"].where(rows["age_band"].isin(["18-24", "25-34"]), "35+")
table = rows.groupby(["home_shop", "age"]).agg(members=("member_id", "size"),
                                               said=("p_lapse", "mean"),
                                               happened=("lapsed", "mean"))
table["gap"] = table["happened"] - table["said"]
print(table.round(3).sort_values("gap", ascending=False).to_string())
```

Membros de 35 anos ou mais formam um grupo só, porque as faixas jovens são onde uma mudança de hábito
aparece primeiro e as faixas mais velhas ficam pequenas demais em algumas lojas. `gap` é o que
aconteceu menos o que foi dito: positivo onde mais membros saíram do que o modelo esperava. As seis
maiores:

```
ana@dev:~/ml$ python segments.py 2026-03-29 | head -n 8
                 members   said  happened    gap
home_shop age                                   
Pinheiros 25-34      130  0.182     0.508  0.325
Paulista  25-34      162  0.160     0.432  0.272
          18-24       74  0.208     0.473  0.265
Cambuí    18-24       34  0.280     0.382  0.102
Batel     25-34       66  0.207     0.273  0.066
          18-24       42  0.351     0.405  0.054
```

**Três grupos se destacam, e têm duas coisas em comum**: são jovens, e pertencem às duas lojas de São
Paulo. Membros de 25 a 34 anos de Pinheiros receberam em média 18% e metade deles saiu. Em todo o
resto as diferenças são de alguns pontos para cada lado, o que é ruído para grupos desse tamanho.

Isso é deriva de conceito com endereço. As entradas desses membros parecem as de sempre, então
nenhuma checagem de entrada poderia tê-la achado; os desfechos deles mudaram, a partir de abril, e a
assinatura rival lançada em São Paulo em 1º de abril é a suspeita óbvia. Uma equipe de dados levaria
esta tabela ao marketing, que saberia do rival antes de qualquer modelo. **A tabela não explica a
mudança; ela diz onde perguntar.**
