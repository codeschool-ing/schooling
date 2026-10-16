---
title: Lançando uma versão nova sem apostar todo mundo nela
version: 1
---

Uma versão nova pode passar em todos os testes offline e ainda assim se comportar diferente em
pedidos reais. **O jeito seguro de descobrir é dar a ela uma fatia pequena e fixa do tráfego e
comparar**, o que se chama **canário**, por causa dos pássaros que antigamente desciam às minas como
alarme. O aprendizado por reforço da lição 1 já trouxe a mesma ideia: testar uma opção nova custa
alguma coisa, então ela é testada em poucos.

Duas regras tornam um canário confiável. **A divisão é decidida pelo membro, não por sorte a cada
pedido**, para que uma pessoa não receba a versão 1 às dez e dez e a versão 2 às dez e quinze. E
**ninguém escolhe quem entra nele**, senão o grupo do canário difere do resto por motivos que nada
têm a ver com o modelo. Um hash do id do membro dá as duas coisas. Este programa divide os membros
desta noite como um serviço faria, pontua o canário com a versão 2 e todos os outros com a versão 1,
e compara os dois grupos. Salve-o como `canary.py`:

```python
"""canary.py: send one member in ten to a new version, and compare the two groups."""
import sqlite3
import zlib

import mlflow
import pandas as pd

from featurestore import STORE
from model import COLUMNS
from project import ROOT

CANARY_PERCENT = 10


def arm(member_id):
    """The same member always lands in the same group, and nobody chooses which."""
    return "canary" if zlib.crc32(str(member_id).encode()) % 100 < CANARY_PERCENT else "stable"


mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
versions = {"stable": mlflow.sklearn.load_model("models:/lapse/1"),
            "canary": mlflow.sklearn.load_model("models:/lapse/2")}

with sqlite3.connect(STORE) as db:
    rows = pd.read_sql_query("SELECT * FROM offline WHERE as_of = '2026-02-28'", db)
rows["arm"] = rows["member_id"].map(arm)
for name, model in versions.items():
    group = rows["arm"] == name
    rows.loc[group, "p_lapse"] = model.predict_proba(rows.loc[group, COLUMNS])[:, 1]

summary = rows.groupby("arm").agg(members=("member_id", "size"), mean_p=("p_lapse", "mean"),
                                  over_0_2=("p_lapse", lambda p: (p > 0.2).mean()))
print(summary.round(3).to_string())
```

`zlib.crc32` transforma o id num número que parece aleatório e é sempre o mesmo para o mesmo id; os
seus dois últimos dígitos decidem o grupo.

```
ana@dev:~/ml$ python canary.py
        members  mean_p  over_0_2
arm                              
canary      335   0.421     0.869
stable     3020   0.175     0.243
```

335 membros foram para o canário, perto dos 10% pedidos, sem lista guardada em lugar nenhum. **E o
canário pegou a versão 2 na hora**: os membros dele receberam uma probabilidade média de 0,421 contra
0,175, e 86,9% deles passaram de 0,2, o melhor limiar da lição 4, contra 24,3% dos outros. Os dois
grupos saem dos mesmos membros por um hash, então a diferença é do modelo.

Ninguém precisa esperar 90 dias pelos rótulos para ver isso. **O que um canário observa primeiro é o
que o modelo diz, não se ele acertou**, e uma versão cujas saídas não se parecem em nada com as da
versão estável é parada antes de chegar aos outros 90%. A lição 9 transforma essa comparação numa
checagem que roda toda noite, e a lição 10 trata do caso mais raro em que a versão nova é a que está
dizendo a verdade.

Uma implantação **sombra** é a prima cautelosa: a versão nova também pontua cada pedido, mas as suas
respostas são só registradas, nunca usadas. Custa o dobro de processamento e não arrisca nada.
