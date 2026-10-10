---
title: Linhagem: rastrear um número de volta até onde ele nasceu
version: 1
---

**Linhagem é a resposta para "de onde veio este número?", dada como um caminho que pode ser
percorrido de trás para a frente, uma etapa por vez, até as linhas na origem.** É o ciclo de vida
lido na outra direção.

Marta lê o relatório da manhã e para na Rua XV. O supervisor da estação disse a ela que as docas de
lá destravaram mais bicicletas do que isso na segunda. Um dos dois está errado, e antes de alguém
discutir, o número do relatório tem de ser rastreado.

## Rastreando à mão

Como cada etapa grava a saída no seu próprio diretório, o rastreio é questão de contar a mesma coisa
em cada camada. Este programa faz a contagem para uma estação e um dia, e lista toda viagem que o
bruto tem e o limpo não:

```python
# lifecycle/trace.py
import csv
import json
import sqlite3
import sys

station, day = sys.argv[1], sys.argv[2]


def starting_here(path):
    with open(path, encoding="utf-8") as f:
        return [r for r in map(json.loads, f) if r["start_station"] == station]


with open(f"curated/date={day}/rides_per_station.csv", encoding="utf-8") as f:
    curated = next(r for r in csv.DictReader(f) if r["station_id"] == station)
clean = starting_here(f"clean/date={day}/rides.jsonl")
raw = starting_here(f"raw/date={day}/rides.jsonl")
app = sqlite3.connect("file:app.db?mode=ro", uri=True)
source = app.execute("SELECT count(*) FROM rides WHERE start_station = ? AND started_at LIKE ?",
                     (station, day + "%")).fetchone()[0]

print(f"curated {curated['rides']:>4}  curated/date={day}/rides_per_station.csv")
print(f"clean   {len(clean):>4}  clean/date={day}/rides.jsonl")
print(f"raw     {len(raw):>4}  raw/date={day}/rides.jsonl")
print(f"app.db  {source:>4}  table rides")
kept = {r["ride_id"] for r in clean}
for r in raw:
    if r["ride_id"] not in kept:
        print("dropped", r["ride_id"], r["started_at"], r["minutes"], "min")
```

Pergunte a ele sobre a Rua XV na segunda:

```
ana@lab:~/roda/lifecycle$ python trace.py ST02 2025-09-15
curated   29  curated/date=2025-09-15/rides_per_station.csv
clean     29  clean/date=2025-09-15/rides.jsonl
raw       31  raw/date=2025-09-15/rides.jsonl
app.db    31  table rides
dropped R000183 2025-09-15 06:33 1 min
dropped R000342 2025-09-15 19:51 0 min
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 352\" role=\"img\" aria-label=\"Cinco camadas, de cima para baixo: o relatório diz Rua XV 29; a linha curada diz ST02, Rua XV, 29; a zona limpa tem 29 viagens da ST02; a zona bruta tem 31; o banco do aplicativo tem 31. A ingestão copiou as 31; a transformação descartou 2 partidas falsas, R000183 e R000342; as 29 restantes viraram uma linha e foram lidas pelo relatório.\" data-fig=\"lineage\"><defs><marker id=\"lineage-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"134\" y=\"33.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o relatório</text><rect x=\"148\" y=\"14\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST02 Rua XV  29</text><text x=\"134\" y=\"101.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">curado</text><rect x=\"148\" y=\"82\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST02,Rua XV,29,610</text><text x=\"134\" y=\"169.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">limpo</text><rect x=\"148\" y=\"150\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">29 viagens da ST02</text><text x=\"134\" y=\"237.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">bruto</text><rect x=\"148\" y=\"218\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">31 viagens da ST02</text><text x=\"134\" y=\"305.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o aplicativo</text><rect x=\"148\" y=\"286\" width=\"240\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"305.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">31 viagens da ST02</text><line x1=\"268\" y1=\"82\" x2=\"268\" y2=\"54\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lineage-ah)\"></line><text x=\"408\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lido pelo relatório</text><line x1=\"268\" y1=\"150\" x2=\"268\" y2=\"122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lineage-ah)\"></line><text x=\"408\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">contadas: uma linha por estação</text><line x1=\"268\" y1=\"218\" x2=\"268\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lineage-ah)\"></line><text x=\"408\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a transformação descarta 2 partidas falsas</text><text x=\"408\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000183 1 min, R000342 0 min</text><line x1=\"268\" y1=\"286\" x2=\"268\" y2=\"258\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lineage-ah)\"></line><text x=\"408\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a ingestão copia todas</text></svg>", "caption": "As 29 viagens da Rua XV no relatório, rastreadas de volta até o aplicativo. Cada diferença entre duas camadas é uma regra num programa."}
```

Lida de baixo para cima, essa é a história inteira de um número. O aplicativo tem 31 viagens saindo
da Rua XV naquele dia; a ingestão copiou as 31, que é para isso que a ingestão serve; a transformação
descartou 2 delas como partidas falsas, e as 29 que sobraram são as 29 do relatório. **Cada
diferença entre duas camadas é explicada por uma regra num programa**, e as duas viagens que ele cita
podem ser consultadas e discutidas. A contagem do supervisor estava certa, e o relatório também:
eles contam coisas diferentes, e agora os dois lados conseguem ver quais.

## Por que isso importa além de uma discussão

- Confiança: um número que pode ser rastreado é um número que alguém consegue defender numa
  reunião. Um que não pode é uma opinião com casas decimais.
- Impacto: lido para a frente, o mesmo caminho responde a outra pergunta: se o time do aplicativo
  renomear `start_station`, que tabelas e que relatórios quebram? Sem linhagem, a resposta aparece na
  manhã seguinte.
- Eliminação: quando um cliente pede à Roda Livre que apague os dados dele, como a LGPD permite,
  alguém precisa saber todas as zonas a que as linhas dele chegaram. A linhagem é essa lista.

## Linhagem do tamanho de uma empresa

Aqui o caminho eram quatro diretórios e um programa que sabe onde eles estão. Numa empresa há
milhares de tabelas, e ninguém as rastreia à mão. Ferramentas registram a linhagem enquanto os
pipelines rodam, anotando que job leu que tabela e gravou qual outra, e a desenham como um grafo. As
mais completas descem até colunas individuais, e OpenLineage é um padrão aberto para descrevê-la. As ferramentas mudam
a escala e não a ideia: **todo número de um relatório é o fim de um caminho, e alguém tem de conseguir
percorrê-lo de volta.**
