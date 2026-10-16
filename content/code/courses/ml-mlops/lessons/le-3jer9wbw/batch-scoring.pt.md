---
title: Um lote noturno de notas
version: 1
---

Um job de lote faz três coisas: **carrega o modelo que a produção deve usar, lê os atributos de
todos que pontua e grava uma linha por membro numa tabela** que outras pessoas leem. Salve isto como
`score_batch.py`:

```python
"""score_batch.py: tonight's lapse scores for every active member, by the champion.

    python score_batch.py 2026-02-28
"""
import sqlite3
import sys

import mlflow
import pandas as pd
from mlflow import MlflowClient

from featurestore import STORE
from model import COLUMNS
from project import ROOT

cutoff = sys.argv[1]
mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
version = MlflowClient().get_model_version_by_alias("lapse", "champion").version
model = mlflow.sklearn.load_model(f"models:/lapse/{version}")

with sqlite3.connect(STORE) as db:
    rows = pd.read_sql_query("SELECT * FROM offline WHERE as_of = ?", db, params=(cutoff,))
if rows.empty:
    sys.exit(f"refused: the feature store has no snapshot for {cutoff}")
rows["p_lapse"] = model.predict_proba(rows[COLUMNS])[:, 1]

with sqlite3.connect(ROOT / "scores.db") as db:
    db.execute("""CREATE TABLE IF NOT EXISTS lapse_scores (
                    member_id INTEGER, cutoff TEXT, p_lapse REAL, model_version TEXT,
                    PRIMARY KEY (member_id, cutoff))""")
    db.execute("DELETE FROM lapse_scores WHERE cutoff = ?", (cutoff,))   # a rerun replaces the night
    db.executemany("INSERT INTO lapse_scores VALUES (?, ?, ?, ?)",
                   [(int(m), cutoff, round(float(p), 4), version)
                    for m, p in zip(rows["member_id"], rows["p_lapse"])])
    total = db.execute("SELECT count(*) FROM lapse_scores").fetchone()[0]
print(f"{len(rows)} members scored as of {cutoff} by lapse version {version}; "
      f"{total} rows in lapse_scores")
```

Cada decisão ali vem de uma lição anterior:

- **o modelo é o campeão**, encontrado pelo apelido da lição 7 e depois carregado pelo número da
  versão, então o job sabe e registra exatamente qual versão escreveu cada linha;
- **os atributos vêm do armazenamento offline** da lição 6, a fotografia da noite que está sendo
  pontuada, então o lote lê os mesmos valores que o treino leria para aquele dia;
- **uma noite sem fotografia é recusada**, em vez de pontuada com o que estiver à mão;
- **a chave da tabela é membro e data de corte**, e a versão fica guardada ao lado de cada nota, as
  duas coisas que a lição 2 disse que uma resposta guardada precisa.

O programa lê `features.db` e grava `scores.db`, um terceiro arquivo SQLite que as ferramentas do
marketing leriam. Nenhum dos dois pertence ao Git, então acrescente-os ao `.gitignore`, junto com os
arquivos da borda que a seção 08 vai criar:

```sh
printf 'scores.db\nmodels/*.onnx\n' >> .gitignore
```

O armazenamento da lição 6 precisa conter a fotografia desta noite antes; se você rodou os comandos
dela, ele contém. Então:

```
ana@dev:~/ml$ python score_batch.py 2026-02-28
3355 members scored as of 2026-02-28 by lapse version 1; 3355 rows in lapse_scores
```
