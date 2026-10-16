---
title: O boletim, e por que ele atrasa
version: 1
---

A quarta pergunta, se o modelo acertou, só pode ser respondida sobre uma noite cujos desfechos já
chegaram. **Um boletim junta as notas guardadas de uma noite com o que cada membro fez depois**:
comprou de novo em 90 dias, ou não. É a mesma conta do `evaluate.py` da lição 5, aplicada a notas
que foram de fato produzidas em vez de a um conjunto de teste. Salve-o como `report_card.py`:

```python
"""report_card.py: one night's stored scores against what the members then did.

    python report_card.py 2025-11-30
"""
import datetime as dt
import json
import sqlite3
import sys

import pandas as pd
from sklearn.metrics import average_precision_score, roc_auc_score

from project import LABEL_DAYS, ROOT, SHOP

night = sys.argv[1]
closes = (dt.date.fromisoformat(night) + dt.timedelta(days=LABEL_DAYS)).isoformat()
with sqlite3.connect(SHOP) as db:
    last_day = db.execute("SELECT max(day) FROM purchases").fetchone()[0]
    if closes > last_day:
        sys.exit(f"not yet: the outcomes of {night} close on {closes}, "
                 f"and the data ends on {last_day}")
    bought = pd.read_sql_query("SELECT DISTINCT member_id FROM purchases "
                               "WHERE day > ? AND day <= ?", db, params=(night, closes))
with sqlite3.connect(ROOT / "scores.db") as db:
    scores = pd.read_sql_query("SELECT * FROM lapse_scores WHERE cutoff = ?", db, params=(night,))

scores["lapsed"] = (~scores["member_id"].isin(bought["member_id"])).astype(int)
p, lapsed = scores["p_lapse"], scores["lapsed"]
print(json.dumps({
    "night": night,
    "model_version": ", ".join(sorted(scores["model_version"].unique())),
    "members": len(scores),
    "lapsed": int(lapsed.sum()),
    "roc_auc": round(roc_auc_score(lapsed, p), 3),
    "average_precision": round(average_precision_score(lapsed, p), 3),
    "lapsed_in_top_300": int(lapsed[p.nlargest(300).index].sum()),
    "said": round(p.mean(), 3),
    "happened": round(lapsed.mean(), 3),
}, indent=2))
```

O desfecho é calculado aqui a partir das compras, com a mesma regra do `features.py`: afastado se
nada foi comprado nos 90 dias depois da noite. **E o programa recusa uma noite cujos 90 dias ainda
não
passaram**, pelo mesmo motivo que a lição 3 recusou treinar com rótulos inacabados: um membro sem
compra ainda pode simplesmente não ter voltado ainda.

O conjunto de teste do campeão foi a noite de 30 de novembro de 2025, então pontue essa noite com o
lote e peça os dois boletins:

```
ana@dev:~/ml$ python score_batch.py 2025-11-30
3130 members scored as of 2025-11-30 by lapse version 1; 19733 rows in lapse_scores
ana@dev:~/ml$ python report_card.py 2025-11-30
{
  "night": "2025-11-30",
  "model_version": "1",
  "members": 3130,
  "lapsed": 530,
  "roc_auc": 0.793,
  "average_precision": 0.522,
  "lapsed_in_top_300": 190,
  "said": 0.177,
  "happened": 0.169
}
ana@dev:~/ml$ python report_card.py 2026-02-28
not yet: the outcomes of 2026-02-28 close on 2026-05-29, and the data ends on 2026-02-28
```

**O primeiro boletim é o teste, reproduzido**: AUC de 0,793, precisão média de 0,522, 190 membros
afastados entre os 300 primeiros, 0,177 dito contra 0,169 acontecido. São os números da lição 5 até
o
último dígito. Isso não é uma descoberta sobre o modelo, já que a noite é a mesma em que ele foi
testado. É uma conferência do próprio boletim: um monitor que discorda de um número em que você
já confia tem um bug, e achá-lo agora sai mais barato do que achá-lo em maio.

**O segundo boletim recusa.** As notas de 28 de fevereiro fecham em 29 de maio de 2026, e os dados
da
loja terminam na noite em que elas foram feitas. O boletim de cada noite vence 90 dias depois dela,
e
até lá o vigia da seção 06 é tudo o que existe. A lição 10 avança o calendário até maio e lê o
boletim
que importa.
