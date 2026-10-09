---
title: Uma linha por dia
version: 2
---

Cada sinal até aqui era um script. No dia a dia, o que alguém de fato lê é uma tabela com todos eles,
uma linha por dia, e a versão ao lado de cada uma. O `daily.py` é essa tabela para as funcionalidades
de ajuda e de pedidos:

```python
"""daily.py: one line a day of the numbers that say how the assistant is doing."""
import json
from collections import Counter, defaultdict

import costs

rows = [r for r in costs.requests() if r["feature"] != "summary"]
day = {r["trace"]: r["at"].strftime("%a %d") for r in rows}
n, refused, releases = Counter(), Counter(), defaultdict(set)
for r in rows:
    d = day[r["trace"]]
    n[d] += 1
    refused[d] += r["outcome"] == "refused"
    releases[d].add(r["release"])
fb = defaultdict(Counter)
for f in map(json.loads, open("feedback.jsonl")):
    if f["trace"] in day:
        fb[day[f["trace"]]][f["kind"] + ("-" + f["value"] if f["kind"] == "thumbs" else "")] += 1
print(f"{'day':7} {'requests':>8} {'refused':>8} {'down/rated':>11} {'rephrased':>9} {'person':>7}  release")
for d in n:
    c = fb[d]
    rated = c["thumbs-up"] + c["thumbs-down"]
    print(f"{d:7} {n[d]:8} {refused[d] / n[d]:8.0%} {c['thumbs-down']:5}/{rated:<5} {c['rephrase'] / n[d]:9.0%} "
          f"{c['escalate'] / n[d]:7.0%}  {' '.join(sorted(releases[d]))}")
```

```
ana@dev:~/obs$ python daily.py
day     requests  refused  down/rated rephrased  person  release
Mon 28        39      28%     3/10           8%      0%  2026.09.4
Tue 29        42      19%     1/13           7%      0%  2026.09.4
Wed 30        42      19%     1/9            5%      0%  2026.09.4
Thu 01        49      51%     1/6           20%      2%  2026.09.4 2026.10.1
Fri 02        39      33%     1/11           5%      3%  2026.10.1
Sat 03        32      44%     2/5           16%      3%  2026.10.1
Sun 04        32      28%     0/4            6%      3%  2026.10.1
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três linhas sobre os sete dias da semana, em porcentagem dos pedidos. Recusados: 28, 19 e 19 de segunda a quarta, depois 51 na quinta, 33 na sexta, 44 no sábado e 28 no domingo. Reformulados: 8, 7, 5, depois 20, 5, 16 e 6. Pediram uma pessoa: 0, 0, 0, depois 2, 3, 3 e 3. Uma linha tracejada na quinta marca a versão de 1º de outubro às 10h.\"><path d=\"M62 220 L568 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M56 190 L62 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M56 160 L62 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M56 130 L62 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M56 100 L62 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M56 70 L62 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><text x=\"70.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mon 28</text><text x=\"151.667\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Tue 29</text><text x=\"233.334\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wed 30</text><text x=\"315.001\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Thu 01</text><text x=\"396.668\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Fri 02</text><text x=\"478.335\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sat 03</text><text x=\"560.002\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sun 04</text><path d=\"M308.2 40 L308.2 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"304.2\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">versão 2026.10.1</text><path d=\"M70.0 136 L151.667 163 L233.334 163 L315.001 67 L396.668 121 L478.335 88 L560.002 136\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"163\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"233.334\" cy=\"163\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"315.001\" cy=\"67\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"396.668\" cy=\"121\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"478.335\" cy=\"88\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"560.002\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"576\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusados</text><path d=\"M70.0 196 L151.667 199 L233.334 205 L315.001 160 L396.668 205 L478.335 172 L560.002 202\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"196\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"199\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"233.334\" cy=\"205\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"315.001\" cy=\"160\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"396.668\" cy=\"205\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"478.335\" cy=\"172\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"560.002\" cy=\"202\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"576\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">reformulados</text><path d=\"M70.0 220 L151.667 220 L233.334 220 L315.001 214 L396.668 211 L478.335 211 L560.002 211\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"220\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"220\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"233.334\" cy=\"220\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"315.001\" cy=\"214\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"396.668\" cy=\"211\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"478.335\" cy=\"211\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"560.002\" cy=\"211\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"576\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pediram uma pessoa</text><text x=\"315\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">% dos pedidos, help e order</text></svg>", "caption": "Três sinais que ninguém precisou pedir a um cliente, mexendo juntos no dia da versão."}
```

Leia como alguém leria na segunda-feira, 5 de outubro. De segunda a quarta, a taxa de recusa fica
entre 19% e 28%, as reformulações entre 5% e 8%, e ninguém pediu uma pessoa. **Na quinta os três
pulam**: 51% recusados, 20% reformulados, e o primeiro pedido de uma pessoa da semana. A quinta é o
único dia com duas versões. Dali em diante, alguém pede uma pessoa todo dia, e a taxa de recusa fica
acima da de terça e de quarta todos os dias. Os polegares quase não dizem nada, porque são entre
quatro e treze por dia.

## O que a semana diz, tudo junto

A aula 3 descobriu que o custo por pedido caiu pela metade ao longo da semana, e a maior parte disso
depois da versão de quinta. Esta aula descobre que, a partir do mesmo momento, os clientes foram
mais recusados, perguntaram de novo mais vezes, e começaram a desistir do assistente e a pedir uma
pessoa. **A versão deixou o assistente mais barato deixando-o pior**, e só uma visão com as duas
coisas mostra isso como um evento só, e não como duas notícias, uma boa e uma ruim.

A decisão vem em seguida: devolver o piso, e trabalhar as perguntas sobre pedido de outro jeito (as
seções anteriores apontaram para a busca). A aula 14 é onde uma mudança assim é testada contra o
conjunto de avaliação antes de ir ao ar, para que a próxima versão que suba um piso seja pega num pull
request e não um dia depois, em produção.

## O que esta visão ainda não vê

Todo número da tabela é sobre **comportamento**: o que foi recusado, o que as pessoas fizeram depois.
Nenhum deles diz se as respostas que não foram recusadas estavam certas. Uma resposta errada e confiante,
em que o cliente acredita e com base na qual age, não recebe polegar, nem reformulação, nem pedido de
uma pessoa. É a falha mais danosa que um assistente como este tem, e é invisível a tudo das aulas 1 a 5.
As aulas 8 a 13 constroem os instrumentos que a veem.
