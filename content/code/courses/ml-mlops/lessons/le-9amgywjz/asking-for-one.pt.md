---
title: Pedindo um membro
version: 1
---

O motivo de um armazenamento online existir é tempo. **Um serviço que pontua um membro enquanto a
página dele carrega tem poucos milissegundos**, não o tempo de calcular atributos a partir da tabela
de compras. Este programa mede os dois, na sua máquina. Salve-o como `lookup.py`:

```python
"""lookup.py: how long a service waits for one member's features, two ways."""
import sqlite3
import time

import features
from featurestore import STORE, get
from project import SHOP

with sqlite3.connect(STORE) as db:
    members = [m for (m,) in db.execute("SELECT member_id FROM online LIMIT 1000")]

start = time.perf_counter()
for m in members:
    get(m)
per_lookup = (time.perf_counter() - start) / len(members)
print(f"online store: {len(members)} lookups, {per_lookup * 1000:.2f} ms each")

start = time.perf_counter()
features.build("2026-02-28", SHOP)
print(f"computing from purchases: {time.perf_counter() - start:.2f} s, "
      "and it computes every member to answer one")
```

```
ana@dev:~/ml$ python lookup.py
online store: 1000 lookups, 0.17 ms each
computing from purchases: 0.06 s, and it computes every member to answer one
```

Uma busca no armazenamento online leva uma fração de milissegundo, porque é uma leitura indexada de
uma linha. Calcular os atributos a partir das compras leva dezenas de milissegundos, e **calcula
todos os membros ativos para responder sobre um**: o `features.build` não tem como pedir um membro
só, porque foi escrito para o treino.

Os seus números vão ser diferentes destes, e vão variar de uma rodada para outra na mesma máquina; o
que não muda é a distância de duas ou três ordens de grandeza entre eles. No tamanho da Ponto Final,
qualquer um caberia dentro de uma requisição web. Com cem vezes os membros, só um caberia, e é nesse
tamanho que um time deixa de conseguir dispensar o armazenamento online.

**O mesmo código escreveu as duas respostas.** A linha online do membro 2 veio de uma fotografia que
rodou o `features.py`; o site não tem mais a sua própria versão do `spend_180d` para errar. Isso fecha
a diferença da lição 5 por construção: não há nada sobre o que os dois lados possam discordar.
