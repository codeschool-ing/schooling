---
title: As falhas que são respostas
version: 2
---

A aula 4 contou erros: pedidos que o fornecedor recusou e pedidos que o cliente viu falhar. Nesta
semana não houve nenhum, e esse é o número menos informativo da aula. As falhas do assistente são quase
sempre **respostas**: uma recusa a uma pergunta que os documentos respondem, uma resposta que cita uma
fonte que não existe, uma resposta sobre a coisa errada. Nenhuma delas lança exceção, então nenhuma é
erro para qualquer coisa que conte erros. Elas têm de ser contadas de propósito.

O assistente já registra o resultado de cada pedido (`app.outcome`) e quantas das suas citações apontam
para fonte nenhuma (`app.citations.dangling`). O `outcomes.py` conta os dois por funcionalidade e
versão:

```python
"""outcomes.py: what the requests ended as, per feature and release."""
import json
from collections import Counter, defaultdict

import costs

rows = costs.requests()
dangling = {s["trace"] for s in map(json.loads, open("spans.jsonl"))
            if s["name"] == "check_citations" and s["attributes"]["app.citations.dangling"]}
by = defaultdict(Counter)
for r in rows:
    by[r["feature"], r["release"]][r["outcome"] or "error"] += 1
    by[r["feature"], r["release"]]["dangling"] += r["trace"] in dangling
print(f"{'feature':8} {'release':10} {'requests':>8} {'answered':>9} {'refused':>8} {'refused %':>9} {'dangling':>8}")
for (feature, release), c in sorted(by.items()):
    n = sum(v for k, v in c.items() if k != "dangling")
    print(f"{feature:8} {release:10} {n:8} {c['answered'] + c['summarised']:9} {c['refused']:8} "
          f"{c['refused'] / n:9.0%} {c['dangling']:8}")
```

```
ana@dev:~/obs$ python outcomes.py
feature  release    requests  answered  refused refused % dangling
help     2026.09.4       102        80       22       22%        0
help     2026.10.1       105        62       43       41%        0
order    2026.09.4        32        23        9       28%        0
order    2026.10.1        36        22       14       39%        0
summary  2026.09.4        16        16        0        0%        0
summary  2026.10.1        20        20        0        0%        0
```

**Nenhuma citação solta a semana toda.** O `llama3.2:3b` só citou fontes que recebeu, em cada uma
das suas 265 respostas. Vale saber, e vale conferir de novo depois de toda troca de modelo ou de
prompt: um modelo que recebe três fontes e inventa um `[4]` é uma falha conhecida, e esta coluna é o
único lugar onde ela apareceria.

**A taxa de recusa subiu com a versão, nas duas funcionalidades.** Help foi de 22% recusados para
**41%**: sob o piso novo, dois em cada cinco clientes fazendo uma pergunta ouviram que os documentos
não tinham nada para eles. Order foi de 28% para 39%. Uma recusa é a resposta certa para uma
pergunta que os documentos não respondem, e quatro assuntos do tráfego desta semana são assim. É a
resposta errada para o resto. Uma taxa não é certa nem errada sozinha, mas uma taxa que pula no dia
de uma versão é uma versão que mudou o que os clientes recebem.

**E a funcionalidade de pedidos recusava mais que a de ajuda já antes.** 28% sob o piso antigo,
contra 22%. A próxima seção descobre por quê, a partir de dois traces.