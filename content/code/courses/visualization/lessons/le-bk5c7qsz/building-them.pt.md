---
title: Construindo
version: 1
---

Toda biblioteca de gráficos tem um jeito de desenhar uma grade de painéis, e as planilhas têm um
improviso.

## Em Python

```schooling-example
{"language": "python", "file": "multiples.py", "parts": [{"code": "import csv\nimport sys\nimport matplotlib.pyplot as plt\n"}, {"code": "shared = sys.argv[1:] != [\"free\"]\n", "note": "Rode sem argumento para escalas compartilhadas e com `free` para uma escala por painel."}, {"code": "series = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        series.setdefault(row[\"region\"], []).append(int(row[\"orders\"]))\nregions = sorted(series, key=lambda r: series[r][-1], reverse=True)\n", "note": "Lê os 24 valores mensais de cada região e ordena as regiões pelo último mês, da maior para a menor. Essa é a ordem dos painéis."}, {"code": "fig, axes = plt.subplots(1, len(regions), figsize=(12, 2.5), sharey=shared)\nfor ax, region in zip(axes, regions):\n    for other in regions:\n        ax.plot(series[other], color=\"lightgrey\", linewidth=0.8)\n    ax.plot(series[region], color=\"#2b52c9\", linewidth=2)\n    ax.set_title(region)\n    if not shared:\n        ax.set_ylim(min(series[region]) * 0.95, max(series[region]) * 1.05)\n    low, high = ax.get_ylim()\n    print(f\"{region:12} axis {low:6.0f} to {high:6.0f}\")\nfig.savefig(\"multiples.png\", dpi=150, bbox_inches=\"tight\")\n", "note": "O `subplots` com `sharey` faz todos os painéis usarem uma escala vertical só. Em cada painel as outras regiões vêm primeiro, em cinza claro, e depois a própria região do painel por cima; com escalas livres a faixa de cada painel vem do próprio dado, e todo painel imprime a faixa com que ficou."}], "output": "Southeast    axis   4910 to   8612\nNortheast    axis   1746 to   5139\nSouth        axis   1894 to   4292\nCentre-West  axis    856 to   2055\nNorth        axis    423 to   1517"}
```

Com as escalas compartilhadas:

```
ana@vm:~/viz$ .venv/bin/python multiples.py
Southeast    axis     57 to   8590
Northeast    axis     57 to   8590
South        axis     57 to   8590
Centre-West  axis     57 to   8590
North        axis     57 to   8590
```

Todo painel relata a mesma faixa, então as alturas se comparam entre painéis. Com escalas livres:

```
ana@vm:~/viz$ .venv/bin/python multiples.py free
Southeast    axis   4910 to   8612
Northeast    axis   1746 to   5139
South        axis   1894 to   4292
Centre-West  axis    856 to   2055
North        axis    423 to   1517
```

Cada painel agora cobre a faixa da sua região. O do Sudeste começa em 4.910 e o do Norte termina em
1.517, e **a mesma altura na página quer dizer um número diferente em cada painel**. Na versão livre as
linhas cinza das outras regiões saem pelas bordas de cada painel, o que é mais um sinal de que escalas
livres e linhas de contexto não combinam.

Abra o `multiples.png` depois de cada execução e compare com as duas figuras desta aula.

## Numa planilha

As planilhas não têm gráfico de pequenos múltiplos. O improviso é **fazer um gráfico, formatá-lo por
completo, e depois copiá-lo** uma vez por região, mudando só a faixa de dados de cada cópia. Antes de
copiar, fixe à mão o mínimo e o máximo do eixo vertical, para as cópias dividirem uma escala: deixado
no automático, cada gráfico escolhe a sua faixa e a grade vira um conjunto de escalas livres sem que
ninguém tenha decidido isso.

Ferramentas de BI como Power BI e Tableau têm, com nomes como **pequenos múltiplos** (*small
multiples*) ou **trellis**; a aula 20 volta às ferramentas.
