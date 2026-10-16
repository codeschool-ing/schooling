---
title: Uma tarde movimentada, de propósito
version: 1
---

Um pedido de cada vez diz quão rápido o serviço é quando ninguém mais o usa. **O que os membros
sentem é quão rápido ele é quando todo mundo usa**, e o único jeito de saber isso antes deles é
fazer o tráfego você mesmo. Este programa manda vários pedidos, com alguns em voo ao mesmo tempo, para
ids de membros sorteados, como páginas se abrindo pela loja fariam. Salve-o como `load.py`:

```python
"""load.py: send the service many requests at once, as a busy afternoon would.

    python load.py 2000 8      # 2,000 requests, 8 at a time
"""
import random
import sys
import time
import urllib.error
import urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor

total, at_once = int(sys.argv[1]), int(sys.argv[2])
members = random.Random(9).choices(range(1, 4601), k=total)


def ask(member_id):
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:8000/lapse/{member_id}") as answer:
            return answer.status
    except urllib.error.HTTPError as refused:
        return refused.code


started = time.perf_counter()
with ThreadPoolExecutor(at_once) as pool:
    statuses = Counter(pool.map(ask, members))
seconds = time.perf_counter() - started
print(f"{total} requests in {seconds:.1f} s, {total / seconds:.0f} a second; "
      f"status {dict(sorted(statuses.items()))}")
```

`ThreadPoolExecutor(at_once)` mantém essa quantidade de pedidos esperando o serviço a cada momento, e
o `urllib` é o cliente HTTP do próprio Python, então o programa não precisa de nada instalado. Um 404
chega como exceção no `urllib`, e o programa o conta como a resposta que ele é.

Depois, um programa para ler o log que o serviço gravou. Salve-o como `latency.py`:

```python
"""latency.py: what requests.log says about speed and errors.

    python latency.py          # every request logged
    python latency.py 600      # only the last 600
"""
import sys

import pandas as pd

from project import ROOT

log = pd.read_json(ROOT / "requests.log", lines=True)
if len(sys.argv) > 1:
    log = log.tail(int(sys.argv[1]))
errors = (log["status"] >= 500).sum()
print(f"{len(log)} requests, {errors} errors; status {log['status'].value_counts().sort_index().to_dict()}")
ms = log["ms"]
print(f"mean {ms.mean():6.1f} ms")
for q in (50, 95, 99):
    print(f"p{q}  {ms.quantile(q / 100):6.1f} ms")
print(f"max  {ms.max():6.1f} ms")
```

**Um erro é um status 500 ou acima, e um 404 não é um.** Aqui, um 404 é o serviço recusando
corretamente um membro para quem não tem nada fresco; contar recusas como erros faria a taxa de erro
subir toda vez que o armazenamento online deixasse mais gente de fora, e ensinaria quem a lê a
ignorar o número. Com o serviço ainda rodando, 2.000 pedidos, oito por vez:

```
ana@dev:~/ml$ python load.py 2000 8
2000 requests in 20.5 s, 98 a second; status {200: 1354, 404: 646}
ana@dev:~/ml$ python latency.py 2000
2000 requests, 0 errors; status {200: 1354, 404: 646}
mean   68.7 ms
p50    81.3 ms
p95   120.3 ms
p99   140.6 ms
max   283.4 ms
```

Cerca de cem pedidos por segundo, nenhum erro, e um terço das respostas foram recusas: os ids vão
até 4.600, e o armazenamento online guarda 3.372 membros frescos o bastante para servir. **Depois, as
quatro linhas que importam, e elas discordam entre si.** A média diz 68,7 milissegundos. Metade dos
pedidos levou mais de 81,3 (a mediana, `p50`), um em cada vinte mais de 120,3 (`p95`), um em cada
cem mais de 140,6 (`p99`), e o mais lento 283,4.

**A média fica abaixo da mediana, o que um único tipo de pedido não faria.** O log guarda dois:
recusas, que leem uma linha e param, e respostas, que também rodam o modelo. A média de duas
populações não descreve nenhuma delas, e a próxima seção olha para o que descreve.
