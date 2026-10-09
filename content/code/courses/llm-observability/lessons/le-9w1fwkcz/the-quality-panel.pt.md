---
title: O painel de qualidade
version: 2
---

A aula 5 achou a versão do piso lendo a semana depois de ela acontecer. Um painel e um alerta são como
uma equipe acha a próxima enquanto ela está acontecendo. Os dois são feitos dos mesmos poucos números, e
esta aula os monta a partir da semana reproduzida, terminando onde o curso começou: com alguém sendo
avisado de que o assistente piorou, a tempo de fazer alguma coisa.

O `replies.py` transforma os spans raiz da semana num registro por resposta a cliente: quando, qual
versão, qual funcionalidade, se foi a recusa combinada, e o polegar, se houve um. O `series.py` é o
painel de qualidade de um dashboard em forma de números, uma linha a cada doze horas:

```python
"""replies.py: the week's answered and refused customer replies, one record each, from the root spans and the thumbs."""
import json
from datetime import datetime

import checks

thumbs = {f["trace"]: f["value"] for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"}


def week():
    out = []
    for s in map(json.loads, open("spans.jsonl")):
        a = s["attributes"]
        if s["name"] != "ask" or a["app.feature"] == "summary":
            continue
        out.append({"at": datetime.fromtimestamp(s["start"] / 1e9), "release": a["app.release"],
                    "feature": a["app.feature"], "refused": checks.is_refusal(a["app.reply"]),
                    "thumb": thumbs.get(s["trace"])})
    return sorted(out, key=lambda r: r["at"])
```

```python
"""series.py: the dashboard's quality panel as numbers: per twelve hours, how many replies, and how many refused."""
from collections import defaultdict

import replies

slots = defaultdict(list)
for r in replies.week():
    slots[r["at"].strftime("%a %d ") + f"{r['at'].hour // 12 * 12:02d}h"].append(r)
print("twelve hours from   replies  refused         thumbs down")
for slot, rs in slots.items():
    refused, voted = sum(r["refused"] for r in rs), [r for r in rs if r["thumb"]]
    down = sum(r["thumb"] == "down" for r in voted)
    release = " " + rs[-1]["release"] if rs[0]["release"] != rs[-1]["release"] else ""
    print(f"  {slot:16} {len(rs):8} {refused:6} {refused / len(rs):5.0%}   {down:4} of {len(voted):3}{release}")
```

```
ana@dev:~/obs$ python series.py
twelve hours from   replies  refused         thumbs down
  Mon 28 00h             14      2   14%      1 of   4
  Mon 28 12h             25      9   36%      2 of   6
  Tue 29 00h             14      4   29%      1 of   2
  Tue 29 12h             28      4   14%      0 of  11
  Wed 30 00h             16      3   19%      1 of   2
  Wed 30 12h             26      5   19%      0 of   7
  Thu 01 00h             16      5   31%      0 of   2 2026.10.1
  Thu 01 12h             33     20   61%      1 of   4
  Fri 02 00h             16      4   25%      0 of   5
  Fri 02 12h             24      9   38%      2 of   6
  Sat 03 00h             13      7   54%      1 of   1
  Sat 03 12h             19      7   37%      1 of   4
  Sun 04 00h             11      2   18%      0 of   3
  Sun 04 12h             21      7   33%      0 of   1
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Parcela de respostas recusadas a cada doze horas da semana, de segunda, 28 de setembro, a domingo, 4 de outubro, com a linha de base de 23,1% tracejada e o lançamento de quinta às 10h marcado. Antes do lançamento a parcela fica entre 14% e 36%. As doze horas depois dele chegam a 61%, e a parcela fica entre 18% e 54% até o fim da semana.\"><path d=\"M60 220 L700 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 220 L60 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M55 220.0 L60 220.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M55 170.0 L60 170.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M55 120.0 L60 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M55 70.0 L60 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><text x=\"105.714\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seg</text><text x=\"197.143\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ter</text><text x=\"288.571\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qua</text><text x=\"380.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qui</text><text x=\"471.429\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sex</text><text x=\"562.857\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sáb</text><text x=\"654.286\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dom</text><path d=\"M60 162.25 L700 162.25\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M70 60 L90 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"96\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linha de base 23,1%</text><path d=\"M372.38 220 L372.38 44\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"378.38\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2026.10.1 vai ao ar</text><path d=\"M82.86 185.0 L128.57 130.0 L174.29 147.5 L220.0 185.0 L265.71 172.5 L311.43 172.5 L357.14 142.5 L402.86 67.5 L448.57 157.5 L494.29 125.0 L540.0 85.0 L585.71 127.5 L631.43 175.0 L677.14 137.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"82.86\" cy=\"185.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"128.57\" cy=\"130.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"174.29\" cy=\"147.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"220.0\" cy=\"185.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"265.71\" cy=\"172.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"311.43\" cy=\"172.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"357.14\" cy=\"142.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"402.86\" cy=\"67.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"448.57\" cy=\"157.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"494.29\" cy=\"125.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"540.0\" cy=\"85.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"585.71\" cy=\"127.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"631.43\" cy=\"175.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"677.14\" cy=\"137.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle></svg>", "caption": "Recusadas, como parcela das respostas, a cada doze horas. As doze horas depois do lançamento recusam três perguntas em cinco."}
```

Quatro coisas fazem deste painel um painel que vale ter, e cada uma é uma regra de antes no curso:

- **O volume está ao lado da taxa.** Cada janela tem de 11 a 33 respostas, então uma recusa move uma
  janela de três a nove pontos. Os 54% da manhã de sábado são sete recusas em treze. A regra da aula 5:
  uma taxa sem contagem ao lado convida a uma leitura que ninguém deveria fazer.
- **A versão está nele.** A linha que nomeia a 2026.10.1 são as doze horas em que a versão mudou, e todo
  número depois dela pertence à versão nova. Um gráfico de qualidade sem a versão marcada pede a quem lê
  que se lembre do que foi ao ar e quando.
- **Os polegares são contados, e são poucos.** Entre 1 e 11 votos em doze horas, e dez polegares para
  baixo na semana inteira. Ninguém conseguiria alertar com base neles neste volume: é a aritmética da
  aula 9.
- **A recusa é contada pelo texto exato**, a regra da aula 8. Uma recusa com outras palavras seria
  invisível aqui, e é por isso que essa verificação roda em toda resposta.

O que o painel não consegue mostrar é uma resposta errada dada com confiança, a falha que as aulas 8 a
12 mediram. Isso precisa do pipeline de avaliação, com o seu juiz por amostragem e o seu n, num painel
próprio ao lado deste.
