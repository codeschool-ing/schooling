---
title: Custo por funcionalidade
version: 1
---

Uma conta com um número só diz quanto e nunca por quê. O primeiro corte que explica alguma coisa é por
**funcionalidade**, porque uma funcionalidade é algo que alguém decidiu construir e pode decidir mudar.
O `bill.py` agrupa os pedidos da semana por qualquer campo do span raiz:

```python
"""bill.py: the week's cost, grouped by one field of the request."""
import argparse
from collections import defaultdict
from decimal import Decimal

import costs

p = argparse.ArgumentParser()
p.add_argument("--by", default="feature", choices=["feature", "user", "day", "release", "outcome"])
p.add_argument("--top", type=int)
a = p.parse_args()

rows = costs.requests()
key = (lambda r: r["at"].strftime("%a %d")) if a.by == "day" else (lambda r: r[a.by])
groups = defaultdict(list)
for r in rows:
    groups[key(r)].append(r)
total = sum((r["cost"] for r in rows), Decimal(0))
spend = {g: sum((r["cost"] for r in rs), Decimal(0)) for g, rs in groups.items()}
order = list(groups) if a.by == "day" else sorted(groups, key=lambda g: -spend[g])
print(f"{a.by:18} {'requests':>8} {'input':>8} {'output':>7} {'cost US$':>9} {'per 1k':>7} {'share':>6}  features")
for g in order[:a.top]:
    rs = groups[g]
    features = "/".join(sorted({r["feature"] for r in rs}))
    print(f"{str(g):18} {len(rs):8} {sum(r['input'] for r in rs):8} {sum(r['output'] for r in rs):7} "
          f"{spend[g]:9.4f} {spend[g] / len(rs) * 1000:7.2f} {spend[g] / total:6.1%}  {features}")
print(f"{'total':18} {len(rows):8} {sum(r['input'] for r in rows):8} {sum(r['output'] for r in rows):7} "
      f"{total:9.4f} {total / len(rows) * 1000:7.2f}")
```

```
ana@lab:~/obs$ python bill.py --by feature
feature            requests    input  output  cost US$  per 1k  share  features
help                    926   205752   30907    0.5776    0.62  70.2%  help
order                   295    66232    9514    0.1851    0.63  22.5%  order
summary                 124     9088    6242    0.0602    0.49   7.3%  summary
total                  1345   281072   46663    0.8228    0.61
```

A funcionalidade `help` é 70% do custo e 69% dos pedidos: nenhuma surpresa. As três funcionalidades
custam mais ou menos o mesmo por pedido, entre 0,49 e 0,63 dólar por mil, o que também não é o que
alguém teria adivinhado. Esperava-se que os resumos da equipe de atendimento fossem os caros, porque
mandam uma conversa inteira, e eles são os mais baratos: as conversas desta semana têm quatro linhas e
os resumos têm no máximo quarenta palavras. O palpite era sobre conversas em geral, a medição sobre
estas.

**Um custo por funcionalidade é o número com que se toma uma decisão de produto.** "O assistente custa
0,82 por semana" não convida a nada. "Perguntas sobre pedido custam cada uma tanto quanto perguntas
de ajuda e são recusadas duas vezes mais" convida a uma conversa sobre se a funcionalidade de pedidos
deve existir nesta forma, que as próximas aulas vão ter.

## Uma média esconde uma dispersão

O `spread.py` olha dentro de cada funcionalidade o custo de um único pedido:

```python
"""spread.py: how the cost of one request is distributed, per feature."""
from collections import defaultdict

import costs

by = defaultdict(list)
for r in costs.requests():
    by[r["feature"]].append(r["cost"] * 1_000_000)
print(f"{'feature':8} {'requests':>8} {'no model call':>13}   cost of one request in millionths of a dollar")
print(f"{'':8} {'':>8} {'':>13}   {'min':>6} {'median':>6} {'p95':>6} {'max':>6}")
for feature, c in by.items():
    c.sort()
    pick = lambda q: c[min(len(c) - 1, int(q * len(c)))]
    free = sum(1 for x in c if x < 100)
    print(f"{feature:8} {len(c):8} {free:13}   {c[0]:6.0f} {pick(0.5):6.0f} {pick(0.95):6.0f} {c[-1]:6.0f}")
```

```
ana@lab:~/obs$ python spread.py
feature  requests no model call   cost of one request in millionths of a dollar
                                     min median    p95    max
help          926           175        0    610   1360   1400
summary       124             0      382    510    594    594
order         295            62        0    592   1249   1378
```

**O mínimo é zero** em duas funcionalidades por causa das recusas que a aula 1 achou: quando nada
passa do piso, o assistente responde sem chamar o modelo, e o pedido custa só o embedding, uma fração
de milionésimo. 175 dos 926 pedidos de help e 62 dos 295 de order não custaram nada em tokens de
modelo. Um resumo sempre chama o modelo, então o mínimo dele é 382.

**O percentil 95 é mais que o dobro da mediana** em `help` e `order`, e não é a resposta que faz isso.
Um pedido com três fontes no prompt paga por três trechos de texto; um pedido com uma paga por um. O
custo de um pedido é definido principalmente por **quanto foi recuperado**, que é o `k` e o piso,
configurações do `releases.json` que ninguém pensaria como decisão de custo.
