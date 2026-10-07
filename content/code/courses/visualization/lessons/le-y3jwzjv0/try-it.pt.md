---
title: Na prática: barras agrupadas e um eixo truncado
version: 1
---

## Colunas agrupadas numa planilha

Monte de novo a tabela dinâmica da aula 1, com **region** nas linhas, **month** agrupado por ano nas
colunas e a soma de **orders** nos valores. Ordene as linhas pela coluna de 2025, da maior para a
menor, e insira um **gráfico de colunas agrupadas**. Depois abra as opções de formatação do eixo
vertical e olhe o **mínimo**: deve ser 0, e se a sua planilha escolheu outra coisa sozinha, volte
para o zero.

## Colunas agrupadas em Python

```schooling-example
{"language": "python", "file": "grouped.py", "parts": [{"code": "import csv\nimport matplotlib.pyplot as plt\n"}, {"code": "totals = {\"2024\": {}, \"2025\": {}}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        year, region = row[\"month\"][:4], row[\"region\"]\n        totals[year][region] = totals[year].get(region, 0) + int(row[\"orders\"])\n", "note": "Soma os pedidos por região e por ano, a partir das mesmas 120 linhas que a aula 1 usou."}, {"code": "regions = sorted(totals[\"2025\"], key=totals[\"2025\"].get, reverse=True)\nfor r in regions:\n    before, after = totals[\"2024\"][r], totals[\"2025\"][r]\n    print(f\"{r:12} {before:7,} {after:7,}  {100 * (after / before - 1):+5.1f}%\")\n", "note": "Ordena as regiões pelo total de 2025, da maior para a menor, e imprime os dois anos e o crescimento. A ordem escolhida aqui é a ordem das colunas."}, {"code": "fig, ax = plt.subplots(figsize=(7, 3.5))\nx = range(len(regions))\nax.bar([i - 0.2 for i in x], [totals[\"2024\"][r] for r in regions], width=0.4, label=\"2024\")\nax.bar([i + 0.2 for i in x], [totals[\"2025\"][r] for r in regions], width=0.4, label=\"2025\")\nax.set_xticks(list(x), regions)\nax.set_ylabel(\"orders\")\nax.legend()\nprint(\"y axis from\", ax.get_ylim()[0])\nfig.savefig(\"grouped.png\", dpi=150, bbox_inches=\"tight\")\n", "note": "Duas colunas por região, cada uma com 0,4 de largura, deslocadas para a esquerda e para a direita da posição da região para ficarem lado a lado. O print antes de gravar pergunta aos eixos onde eles começam."}], "output": "Southeast     67,663  77,567  +14.6%\nNortheast     27,564  39,924  +44.8%\nSouth         28,279  34,926  +23.5%\nCentre-West   12,622  16,413  +30.0%\nNorth          7,384  11,852  +60.5%\ny axis from 0.0"}
```

```
ana@vm:~/viz$ .venv/bin/python grouped.py
Southeast     67,663  77,567  +14.6%
Northeast     27,564  39,924  +44.8%
South         28,279  34,926  +23.5%
Centre-West   12,622  16,413  +30.0%
North          7,384  11,852  +60.5%
y axis from 0.0
```

O matplotlib começa sozinho o eixo de um gráfico de barras no zero: uma barra tem base, e a base
entra no intervalo. **No matplotlib um eixo de barras truncado não acontece por acidente; alguém tem
de pedir.**

## Pedindo

```schooling-example
{"language": "python", "file": "truncated.py", "parts": [{"code": "import matplotlib.pyplot as plt\n"}, {"code": "northeast, south = 39924, 34926\nfloor = 34000\n", "note": "As duas regiões da figura, e o piso que alguém escolheu para o eixo."}, {"code": "fig, ax = plt.subplots(figsize=(3, 3.5))\nax.bar([\"Northeast\", \"South\"], [northeast, south])\nax.set_ylim(floor, 41000)\nfig.savefig(\"truncated.png\", dpi=150, bbox_inches=\"tight\")\n", "note": "Duas colunas, com o eixo cortado em 34.000. Nada mais no programa está errado, e esse é o ponto."}, {"code": "in_data = northeast / south\non_page = (northeast - floor) / (south - floor)\nprint(f\"in the data: {in_data:.2f} times\")\nprint(f\"on the page: {on_page:.2f} times\")\nprint(f\"lie factor:  {(on_page - 1) / (in_data - 1):.1f}\")\n", "note": "Compara a razão no dado com a razão das alturas desenhadas. A aula 16 dá nome e regra ao último número."}], "output": "in the data: 1.14 times\non the page: 6.40 times\nlie factor:  37.7"}
```

```
ana@vm:~/viz$ .venv/bin/python truncated.py
in the data: 1.14 times
on the page: 6.40 times
lie factor:  37.7
```

Abra o `truncated.png` ao lado do `grouped.png`. O Nordeste teve 14% mais pedidos que o Sul, e o
gráfico truncado desenha a coluna dele 6,4 vezes mais alta. A diferença que ele mostra é **37,7
vezes** a diferença no dado.

## O que procurar no trabalho

Em todo gráfico de barras ou colunas que chegar até você: **ache o pé do eixo de valores antes de
ler qualquer outra coisa.** Se não for zero, os comprimentos não são os números, e toda comparação
que você fizer de olho vai errar na mesma direção: na de uma diferença maior do que existe.
