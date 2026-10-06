---
title: O painel de qualidade
version: 1
---

A aula 5 achou a versão do piso lendo a semana depois de ela acontecer. Um painel e um alerta são como
uma equipe acha a próxima enquanto ela acontece. Os dois são feitos dos mesmos poucos números, e esta
aula os monta a partir da semana reproduzida, terminando onde o curso começou: com alguém ficando
sabendo que o assistente piorou, a tempo de fazer alguma coisa.

O `replies.py` transforma os spans raiz da semana num registro por resposta a cliente: quando, que
versão, que funcionalidade, se era a recusa combinada, e o polegar se houve. O `series.py` é o painel de
qualidade de um dashboard em forma de números, uma linha a cada seis horas:

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
"""series.py: the dashboard's quality panel as numbers: per six hours, how many replies, and how many refused."""
from collections import defaultdict

import replies

slots = defaultdict(list)
for r in replies.week():
    slots[r["at"].strftime("%a %d ") + f"{r['at'].hour // 6 * 6:02d}h"].append(r)
print("six hours from      replies  refused         thumbs down")
for slot, rs in slots.items():
    refused, voted = sum(r["refused"] for r in rs), [r for r in rs if r["thumb"]]
    down = sum(r["thumb"] == "down" for r in voted)
    release = " " + rs[-1]["release"] if rs[0]["release"] != rs[-1]["release"] else ""
    print(f"  {slot:16} {len(rs):8} {refused:6} {refused / len(rs):5.0%}   {down:4} of {len(voted):3}{release}")
```

```
ana@lab:~/obs$ python series.py
six hours from      replies  refused         thumbs down
  Mon 28 00h              9      4   44%      0 of   0
  Mon 28 06h             52     11   21%      5 of   9
  Mon 28 12h             70     17   24%      1 of   9
  Mon 28 18h             47     15   32%      0 of   7
  Tue 29 00h             10      2   20%      0 of   3
  Tue 29 06h             62     18   29%      4 of  13
  Tue 29 12h             65     20   31%      5 of   9
  Tue 29 18h             50     10   20%      4 of   7
  Wed 30 00h              9      3   33%      0 of   1
  Wed 30 06h             61     15   25%      7 of  12
  Wed 30 12h             67     11   16%      2 of   9
  Wed 30 18h             49     10   20%      5 of  12
  Thu 01 00h             11      3   27%      0 of   1
  Thu 01 06h             63     11   17%      2 of  10
  Thu 01 12h             65     13   20%      3 of  10
  Thu 01 18h             52     15   29%      3 of   7
  Fri 02 00h             12      1    8%      0 of   0
  Fri 02 06h             64     15   23%      4 of   6 2026.10.1
  Fri 02 12h             75     31   41%      9 of  16
  Fri 02 18h             57     20   35%      3 of   9
  Sat 03 00h              4      2   50%      0 of   0
  Sat 03 06h             49     21   43%      4 of   7
  Sat 03 12h             48     21   44%      4 of   8
  Sat 03 18h             40     12   30%      5 of   6
  Sun 04 00h              3      0    0%      0 of   1
  Sun 04 06h             37     17   46%      3 of   8
  Sun 04 12h             55     18   33%      2 of   5
  Sun 04 18h             35     12   34%      4 of   6
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Parcela de respostas recusadas a cada seis horas da semana, de segunda, 28 de setembro, a domingo, 4 de outubro, com a linha de base de 24,7% tracejada e o lançamento de sexta às 10h marcado. Nas janelas diurnas a parcela fica entre 16% e 32% antes do lançamento e entre 30% e 46% depois. As janelas da madrugada têm de 3 a 12 respostas e pulam de 0% a 50%.\"><path d=\"M60 220 L700 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 220 L60 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M55 220 L60 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M55 160 L60 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M55 100 L60 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M55 40 L60 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><text x=\"105.714\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seg</text><text x=\"197.143\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ter</text><text x=\"288.571\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qua</text><text x=\"380\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qui</text><text x=\"471.429\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sex</text><text x=\"562.857\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sáb</text><text x=\"654.286\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dom</text><path d=\"M60 145.9 L700 145.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"696\" y=\"157.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linha de base 24,7%</text><path d=\"M463.81 220 L463.81 34\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"469.81\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2026.10.1 vai ao ar</text><path d=\"M71.4 86.7 L94.3 156.5 L117.1 147.1 L140.0 124.3 L162.9 160.0 L185.7 132.9 L208.6 127.7 L231.4 160.0 L254.3 120.0 L277.1 146.2 L300.0 170.7 L322.9 158.8 L345.7 138.2 L368.6 167.6 L391.4 160.0 L414.3 133.5 L437.1 195.0 L460.0 149.7 L482.9 96.0 L505.7 114.7 L528.6 70.0 L551.4 91.4 L574.3 88.8 L597.1 130.0 L620.0 220.0 L642.9 82.2 L665.7 121.8 L688.6 117.1\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"71.4286\" cy=\"86.6667\" r=\"3.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\"></circle><circle cx=\"94.2857\" cy=\"156.538\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"117.143\" cy=\"147.143\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"140\" cy=\"124.255\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"162.857\" cy=\"160\" r=\"3.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\"></circle><circle cx=\"185.714\" cy=\"132.903\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"208.571\" cy=\"127.692\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"231.429\" cy=\"160\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"254.286\" cy=\"120\" r=\"3.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\"></circle><circle cx=\"277.143\" cy=\"146.23\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"300\" cy=\"170.746\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"322.857\" cy=\"158.776\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"345.714\" cy=\"138.182\" r=\"3.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\"></circle><circle cx=\"368.571\" cy=\"167.619\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"391.429\" cy=\"160\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"414.286\" cy=\"133.462\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"437.143\" cy=\"195\" r=\"3.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\"></circle><circle cx=\"460\" cy=\"149.688\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"482.857\" cy=\"96\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"505.714\" cy=\"114.737\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"528.571\" cy=\"70\" r=\"3.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\"></circle><circle cx=\"551.429\" cy=\"91.4286\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"574.286\" cy=\"88.75\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"597.143\" cy=\"130\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"620\" cy=\"220\" r=\"3.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\"></circle><circle cx=\"642.857\" cy=\"82.1622\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"665.714\" cy=\"121.818\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"688.571\" cy=\"117.143\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"74\" cy=\"16\" r=\"3.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\"></circle><text x=\"84\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">madrugada: menos de 13 respostas</text></svg>", "caption": "Recusadas, como parcela das respostas, a cada seis horas. Os pontos vazados são as janelas da madrugada: tão poucas respostas que uma única recusa as move dez pontos."}
```

Quatro coisas fazem deste um painel que vale a pena ter, e cada uma é uma regra de antes no curso:

- **O volume está ao lado da taxa.** Cada janela da madrugada tem de 3 a 12 respostas, e a sua parcela
  oscila de 0% a 50% por causa de uma ou duas delas. A regra da aula 5: uma taxa sem contagem ao lado
  convida a uma leitura que ninguém deveria fazer.
- **A versão está nele.** A linha que nomeia a 2026.10.1 são as seis horas em que a versão mudou, e todo
  número depois dela pertence à versão nova. Um gráfico de qualidade sem a versão marcada pede a quem lê
  que lembre o que foi ao ar e quando.
- **Os polegares são contados, e são poucos.** Entre 0 e 16 votos em seis horas. Eles se mexem com as
  recusas, e ninguém conseguiria alertar só com eles neste volume: é a aritmética da aula 9.
- **A recusa é contada pelo texto exato**, a regra da aula 8. Uma recusa com outras palavras seria
  invisível aqui, e é por isso que essa verificação roda em toda resposta.

O que o painel não consegue mostrar é uma resposta errada dada com confiança, a falha que as aulas 8 a 12
mediram. Isso precisa do pipeline de avaliação, com o seu juiz amostrado e o seu n, num painel próprio ao
lado deste.
