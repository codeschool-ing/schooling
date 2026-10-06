---
title: As falhas que são respostas
version: 1
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
ana@lab:~/obs$ python outcomes.py
feature  release    requests  answered  refused refused % dangling
help     2026.09.4       595       481      114       19%        0
help     2026.10.1       331       232       99       30%        0
order    2026.09.4       194       123       71       37%        0
order    2026.10.1       101        37       64       63%        0
summary  2026.09.4        90        90        0        0%        0
summary  2026.10.1        34        34        0        0%        0
```

**Nenhuma citação solta a semana toda.** Isso é o extract-1: ele só cita as fontes que recebeu, por
construção. Um modelo de verdade inventa um `[4]` quando recebe três fontes vezes o bastante para valer
manter essa coluna.

**A taxa de recusa subiu com a versão, nas duas funcionalidades.** Help foi de 19% recusados para 30%.
Order foi de 37% para **63%**: sob o piso novo, quase dois em cada três clientes perguntando sobre o
próprio pedido ouviram que os documentos não tinham nada para eles. Uma recusa é a resposta certa para
uma pergunta que os documentos não respondem, e quatro tópicos do tráfego desta semana são assim. É a
resposta errada para o resto. Uma taxa não está certa ou errada por si só, mas uma taxa que pula no dia
de uma versão é uma versão que mudou o que os clientes recebem.

**E a funcionalidade de pedidos recusava mais que a de ajuda já antes.** 37% sob o piso antigo, contra
19%. A próxima seção descobre por quê, a partir de dois traces.
