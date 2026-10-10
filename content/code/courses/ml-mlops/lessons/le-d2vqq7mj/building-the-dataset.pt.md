---
title: A primeira etapa: um conjunto de dados, ou uma recusa
version: 1
---

A primeira etapa transforma a loja em exemplos para um corte e os grava num arquivo. Ela recebe o
corte e a saída como argumentos, então nada sobre a data fica dentro do código, e ela **recusa** um
corte cujos rótulos não terminaram, que era o quarto tipo de vazamento da lição 3. Salve-a como
`build_dataset.py`:

```python
"""build_dataset.py: the examples for one cutoff, refused if their labels are not finished.

    python build_dataset.py 2025-09-30 data/train.csv
"""
import datetime as dt
import sqlite3
import sys

import features
from project import LABEL_DAYS, ROOT, SHOP

cutoff, out = sys.argv[1], ROOT / sys.argv[2]

with sqlite3.connect(SHOP) as db:
    last_day = db.execute("SELECT max(day) FROM purchases").fetchone()[0]
closes = dt.date.fromisoformat(cutoff) + dt.timedelta(days=LABEL_DAYS)
if closes.isoformat() > last_day:
    sys.exit(f"refused: the labels for {cutoff} close on {closes}, "
             f"and the data ends on {last_day}")

rows = features.build(cutoff, SHOP)
rows.insert(0, "cutoff", cutoff)
out.parent.mkdir(exist_ok=True)
rows.to_csv(out, index=False)
print(f"{out.relative_to(ROOT)}: {len(rows)} members as of {cutoff}, "
      f"{rows['lapsed'].mean():.1%} lapsed")
```

O `features.build` recebe o caminho completo do banco a partir do `project.py`, e o caminho de saída
também é resolvido em relação ao projeto. **A recusa é calculada a partir dos dados, não da data de
hoje**: os rótulos de um corte fecham 90 dias depois, e a etapa compara isso com o último dia que a
tabela de compras de fato tem. Um banco carregado com atraso é pego do mesmo jeito que um corte mal
escolhido.

```
ana@dev:~/ml$ python build_dataset.py 2025-08-31 data/train.csv
data/train.csv: 2863 members as of 2025-08-31, 16.6% lapsed
ana@dev:~/ml$ python build_dataset.py 2025-11-30 data/test.csv
data/test.csv: 3130 members as of 2025-11-30, 16.9% lapsed
ana@dev:~/ml$ (cd /tmp && python ~/ml/build_dataset.py 2026-01-31 data/jan.csv); echo "exit status $?"
refused: the labels for 2026-01-31 close on 2026-05-01, and the data ends on 2026-02-28
exit status 1
ana@dev:~/ml$ ls data
test.csv
train.csv
```

O corte de treino é 31 de agosto e o de teste 30 de novembro, a distância honesta da lição 3 seção
07: o rótulo de treino mais novo fecha no dia antes do corte de teste. O último comando pede 31 de
janeiro, de outro diretório completamente diferente, e é recusado com o motivo, e **nada é
gravado**: nenhum arquivo meio rotulado fica para trás para uma etapa posterior pegar.

`sys.exit` com uma mensagem a imprime e termina o programa com um status de falha, o que importa
para a etapa depois da próxima: um pipeline para na primeira etapa que falha, e só consegue saber que
uma falhou se ela disser isso no seu status de saída.
