---
title: As mesmas linhas, toda vez
version: 1
---

Uma feature store merece o seu lugar por uma propriedade: **perguntada sobre as linhas de treino de
um corte passado, ela devolve exatamente o que o código dos atributos teria calculado naquele dia**,
hoje e no ano que vem. Isso é verificável, e este programa verifica, depois mostra o que acontece
sem isso. Salve-o como `reproduce.py`:

```python
"""reproduce.py: training rows from the feature store, against features.py and against a shortcut."""
import sqlite3

import pandas as pd
from sklearn.metrics import roc_auc_score

import features
from featurestore import STORE, historical
from model import COLUMNS, make_model


def labelled(cutoff):
    return features.build(cutoff)[["member_id", "lapsed"]].assign(at=cutoff)


test = historical(labelled("2025-11-30"))
print(f"30 November from the store equals features.py: "
      f"{test[COLUMNS].equals(features.build('2025-11-30')[COLUMNS])}")

with sqlite3.connect(STORE) as db:
    latest = pd.read_sql_query("SELECT * FROM online", db)
train = labelled("2025-08-31")
for name, rows in (("as of each row", historical(train)),
                   ("latest values", train.merge(latest, on="member_id"))):
    model = make_model().fit(rows[COLUMNS], rows["lapsed"])
    p = model.predict_proba(test[COLUMNS])[:, 1]
    print(f"trained on {name:15} {len(rows):5} rows, test AUC {roc_auc_score(test['lapsed'], p):.3f}")
```

`labelled` monta a pergunta a fazer ao armazenamento: cada membro ativo num corte, o corte como
momento, e o rótulo ao lado. Os rótulos vêm do `features.py` porque não estão no armazenamento, e
nada mais dessa chamada é usado.

```
ana@dev:~/ml$ python reproduce.py
30 November from the store equals features.py: True
trained on as of each row   2863 rows, test AUC 0.793
trained on latest values    2536 rows, test AUC 0.645
```

**`True` é a propriedade.** Todo atributo de todo membro em 30 de novembro, lido do armazenamento por
junção no ponto do tempo, é idêntico ao que o `features.py` calcula para aquele corte, até a última
casa decimal. Um modelo treinado com as linhas do armazenamento para 31 de agosto tira então
**0,793**, o número que o pipeline da lição 5 imprimiu. Mesmas linhas, mesmo modelo, mesma nota.

**O atalho é a segunda linha.** Junte os rótulos de 31 de agosto aos valores mais novos do
armazenamento online, que é a consulta fácil e a que uma tabela de painel convida, e duas coisas dão
errado de uma vez. **327 membros caem fora**, porque não estão ativos hoje e o armazenamento online não
tem nada novo para eles. E o modelo aprende com os atributos de fevereiro ao lado dos desfechos de
agosto, o vazamento da tabela de resumo numa forma nova: **a AUC dele cai para 0,645.** Nada falhou;
ele só aprendeu de um momento em que ninguém estava prevendo.
