---
title: Regras para um primeiro palpite
version: 1
---

Estatísticos escreveram fórmulas que sugerem uma largura de intervalo a partir do dado. Nenhuma
acerta para todo conjunto de dados, e nenhuma pretende ser a última palavra. Elas são **um ponto de
partida**, e saber o que cada uma supõe diz quando desconfiar dela.

| regra | número de intervalos | o que supõe |
|---|---|---|
| **Sturges** (1926) | 1 + log₂ *n* | uma distribuição mais ou menos em sino; intervalos de menos para dados grandes ou assimétricos |
| **raiz quadrada** | √*n* | nada; uma regra grosseira, rápida de aplicar à mão |
| **Freedman–Diaconis** (1981) | largura = 2 × IIQ ÷ ∛*n* | usa o intervalo interquartil, então uma cauda longa não estica os intervalos |

*n* é o número de valores e IIQ é o intervalo interquartil, a distância entre o primeiro e o terceiro
quartis, a metade do meio dos dados.

## O que elas dizem das entregas da Horta

O numpy implementa as três, e perguntar a ele é mais rápido que fazer a conta. Os nomes das regras no
código ficam em inglês: `sturges`, `sqrt`, `fd`.

```schooling-example
{"language": "python", "file": "bins.py", "parts": [{"code": "import csv\nimport numpy as np\n"}, {"code": "with open(\"deliveries.csv\") as f:\n    minutes = np.array([float(row[\"minutes\"]) for row in csv.DictReader(f)])\n", "note": "Lê os 400 tempos de entrega num array do numpy, que é o que as regras do numpy esperam."}, {"code": "print(f\"{len(minutes)} deliveries, from {minutes.min()} to {minutes.max()} minutes\")\nq1, median, q3 = np.percentile(minutes, [25, 50, 75])\nprint(f\"median {median:.2f}, quartiles {q1:.2f} and {q3:.2f}\")\n", "note": "Imprime antes a faixa e os quartis. As regras abaixo usam esses números."}, {"code": "for rule in [\"sturges\", \"sqrt\", \"fd\"]:\n    edges = np.histogram_bin_edges(minutes, bins=rule)\n    print(f\"{rule:8} {len(edges) - 1:3} bins of {edges[1] - edges[0]:5.2f} minutes\")\n", "note": "Pede ao numpy as bordas que cada regra escolheria, e imprime quantos intervalos isso dá e a largura de cada um."}], "output": "400 deliveries, from 12.2 to 101.3 minutes\nmedian 33.05, quartiles 27.00 and 39.82\nsturges   10 bins of  8.91 minutes\nsqrt      20 bins of  4.46 minutes\nfd        26 bins of  3.43 minutes"}
```

```
ana@vm:~/viz$ .venv/bin/python bins.py
400 deliveries, from 12.2 to 101.3 minutes
median 33.05, quartiles 27.00 and 39.82
sturges   10 bins of  8.91 minutes
sqrt      20 bins of  4.46 minutes
fd        26 bins of  3.43 minutes
```

**Sturges pede 10 intervalos de quase 9 minutos**, o que fica perto da figura em blocos de 15
minutos: ela foi feita para dados em sino, e estes não são. **A raiz quadrada e Freedman–Diaconis
ficam entre 3,4 e 4,5 minutos**, perto dos 5 minutos que pareceram certos na seção anterior.
Arredondando para uma largura que o leitor consiga dizer, as duas dizem 5.

Freedman–Diaconis é a regra a lembrar para dados assimétricos: o intervalo interquartil de 12,8
minutos descreve o grosso e ignora a cauda, então uma entrega de 101 minutos não alarga todos os
intervalos.

## Desenhando as três larguras

```schooling-example
{"language": "python", "file": "histogram.py", "parts": [{"code": "import csv\nimport matplotlib.pyplot as plt\n"}, {"code": "with open(\"deliveries.csv\") as f:\n    minutes = [float(row[\"minutes\"]) for row in csv.DictReader(f)]\n", "note": "Lê os tempos como números simples; o matplotlib aceita uma lista."}, {"code": "fig, axes = plt.subplots(1, 3, figsize=(10, 3), sharey=False)\nfor ax, width in zip(axes, [2, 5, 15]):\n    edges = list(range(0, 106, width))\n    counts, _, _ = ax.hist(minutes, bins=edges, edgecolor=\"white\")\n    ax.set_title(f\"bins of {width} minutes\")\n    print(f\"width {width:2}: {len(edges) - 1:2} bins, tallest holds {int(max(counts))}\")\nfig.savefig(\"histograms.png\", dpi=150, bbox_inches=\"tight\")\n", "note": "Três histogramas lado a lado, um por largura. As bordas são escritas em minutos inteiros a partir do 0, então todo intervalo começa num número redondo, e o `hist` devolve as contagens que desenhou."}], "output": "width  2: 52 bins, tallest holds 38\nwidth  5: 21 bins, tallest holds 87\nwidth 15:  7 bins, tallest holds 194"}
```

```
ana@vm:~/viz$ .venv/bin/python histogram.py
width  2: 52 bins, tallest holds 38
width  5: 21 bins, tallest holds 87
width 15:  7 bins, tallest holds 194
```

Abra o `histograms.png`. Os três painéis são as três figuras da seção anterior, e as contagens
impressas acima são as barras mais altas de cada um.

## Numa planilha

O Excel e o LibreOffice desenham histogramas a partir de uma coluna de valores. Procure a
configuração de **largura do intervalo** ou **número de intervalos** nas opções do eixo horizontal e
mude à mão: a escolha automática vem de uma regra como as de cima, e você acabou de ver o quanto essas
regras discordam.
