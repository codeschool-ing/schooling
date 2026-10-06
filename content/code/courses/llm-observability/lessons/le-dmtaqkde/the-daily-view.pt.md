---
title: Uma linha por dia
version: 1
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
ana@lab:~/obs$ python daily.py
day     requests  refused  down/rated rephrased  person  release
Mon 28       178      26%     6/25          13%      4%  2026.09.4
Tue 29       187      27%    13/32          17%      5%  2026.09.4
Wed 30       186      21%    14/34          17%      5%  2026.09.4
Thu 01       191      22%     8/28          14%      3%  2026.09.4
Fri 02       208      32%    16/31          23%      9%  2026.09.4 2026.10.1
Sat 03       141      40%    13/21          23%     11%  2026.10.1
Sun 04       130      36%     9/20          19%      7%  2026.10.1
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três linhas ao longo dos sete dias da semana, em porcentagem dos pedidos. Recusados: 26, 27, 21, 22, depois 32 na sexta, 40 no sábado, 36 no domingo. Reformulados: 13, 17, 17, 14, depois 23, 23 e 19. Pediram uma pessoa: 4, 5, 5, 3, depois 9, 11 e 7. Uma linha tracejada na sexta marca a versão de 2 de outubro às 10h.\"><path d=\"M62 220 L568 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M56 180 L62 180\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M56 140 L62 140\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M56 100 L62 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M56 60 L62 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><text x=\"70\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mon 28</text><text x=\"151.667\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Tue 29</text><text x=\"233.333\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wed 30</text><text x=\"315\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Thu 01</text><text x=\"396.667\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Fri 02</text><text x=\"478.333\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sat 03</text><text x=\"560\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sun 04</text><path d=\"M384.667 40 L384.667 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"380.667\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">versão 2026.10.1</text><path d=\"M70 116 L151.667 112 L233.333 136 L315 132 L396.667 92 L478.333 60 L560 76\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70\" cy=\"116\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"112\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"233.333\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"315\" cy=\"132\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"396.667\" cy=\"92\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"478.333\" cy=\"60\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"560\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"576\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusados</text><path d=\"M70 168 L151.667 152 L233.333 152 L315 164 L396.667 128 L478.333 128 L560 144\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70\" cy=\"168\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"152\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"233.333\" cy=\"152\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"315\" cy=\"164\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"396.667\" cy=\"128\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"478.333\" cy=\"128\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"560\" cy=\"144\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"576\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">reformulados</text><path d=\"M70 204 L151.667 200 L233.333 200 L315 208 L396.667 184 L478.333 176 L560 192\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70\" cy=\"204\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"200\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"233.333\" cy=\"200\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"315\" cy=\"208\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"396.667\" cy=\"184\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"478.333\" cy=\"176\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"560\" cy=\"192\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"576\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pediram uma pessoa</text><text x=\"315\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">% dos pedidos, help e order</text></svg>", "caption": "Três sinais que ninguém precisou pedir a um cliente, mexendo juntos no dia da versão."}
```

Leia como alguém leria na segunda-feira, 5 de outubro. De segunda a quinta, a taxa de recusa fica entre
21% e 27%, as reformulações entre 13% e 17%, os pedidos de uma pessoa entre 3% e 5%. **Na sexta os três
pulam**, e no sábado estão mais altos ainda: 40% recusados, 23% reformulados, 11% pedindo uma pessoa. A
sexta é o único dia com duas versões. Os polegares dizem o mesmo, com menos clareza, porque são só uns
vinte e cinco por dia.

## O que a semana diz, tudo junto

A aula 3 descobriu que o custo por pedido caiu pela metade ao longo da semana, e a maior parte disso
depois da versão de sexta. Esta aula descobre que, a partir do mesmo momento, os clientes foram mais
recusados, perguntaram de novo mais vezes, e desistiram do assistente duas vezes mais. **A versão deixou
o assistente mais barato deixando-o pior**, e só uma visão com as duas coisas mostra isso como um evento
só, e não como duas notícias, uma boa e uma ruim.

A decisão vem em seguida: devolver o piso, e trabalhar as perguntas sobre pedido de outro jeito (as
seções anteriores apontaram para a busca). A aula 14 é onde uma mudança assim é testada contra o
conjunto de avaliação antes de ir ao ar, para que a próxima versão que suba um piso seja pega num pull
request e não num sábado.

## O que esta visão ainda não vê

Todo número da tabela é sobre **comportamento**: o que foi recusado, o que as pessoas fizeram depois.
Nenhum deles diz se as respostas que não foram recusadas estavam certas. Uma resposta errada e confiante,
em que o cliente acredita e com base na qual age, não recebe polegar, nem reformulação, nem pedido de
uma pessoa. É a falha mais danosa que um assistente como este tem, e é invisível a tudo das aulas 1 a 5.
As aulas 8 a 13 constroem os instrumentos que a veem.
