---
title: Números em cartões
version: 1
---

A fileira de cima da maioria dos painéis é um conjunto de **cartões**, cada um com um número. Um
cartão é o gráfico mais simples que existe, e ainda assim precisa ser desenhado, porque um número
sozinho não se julga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 190\" role=\"img\" data-fig=\"l18-kpi\" aria-label=\"Três versões de um cartão dos pedidos em 2025, 180.682. O primeiro mostra só o número. O segundo acrescenta uma comparação embaixo: alta de 25,9% sobre 2024. O terceiro acrescenta embaixo disso uma linha pequena dos 24 totais mensais, com o último ponto marcado.\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um número</text><rect x=\"20.0\" y=\"32.0\" width=\"180.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">pedidos em 2025</text><text x=\"32.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"var(--paper)\">180.682</text><text x=\"216.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">e uma comparação</text><rect x=\"216.0\" y=\"32.0\" width=\"180.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"224.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">pedidos em 2025</text><text x=\"228.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"var(--paper)\">180.682</text><text x=\"228.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">▲ 25,9% sobre 2024</text><text x=\"412.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">e a tendência</text><rect x=\"412.0\" y=\"32.0\" width=\"180.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"420.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">pedidos em 2025</text><text x=\"424.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"var(--paper)\">180.682</text><text x=\"424.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">▲ 25,9% sobre 2024</text><path d=\"M424.0 160.0 L430.5 159.8 L437.0 158.5 L443.6 157.9 L450.1 157.0 L456.6 157.0 L463.1 156.2 L469.7 154.7 L476.2 153.7 L482.7 153.1 L489.2 153.5 L495.7 138.1 L502.3 149.9 L508.8 150.1 L515.3 148.2 L521.8 147.9 L528.3 147.6 L534.9 143.9 L541.4 145.7 L547.9 143.3 L554.4 142.4 L561.0 141.6 L567.5 141.4 L574.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"574.0\" cy=\"124.0\" r=\"3.0\" fill=\"var(--phosphor)\"></circle></svg>", "caption": "Um número sozinho não se julga: 180.682 só é bom ou ruim comparado com algo. A comparação dá a direção; a linha pequena, uma sparkline, mostra se é uma subida constante ou um mês bom."}
```

180.682 pedidos é bom? Ninguém sabe dizer até compará-lo com algo. Um cartão precisa de três partes:

1. **Um rótulo que diz o que o número é**, com o período: "pedidos em 2025", não "pedidos".
2. **O número**, grande, arredondado ao que o leitor consegue usar (aula 15).
3. **Uma comparação**: com o ano passado, com o mesmo mês do ano passado, ou com uma meta. Escreva a
   direção e o tamanho, "▲ 25,9% sobre 2024", e não só uma cor (aula 14).

Uma quarta parte é opcional e muitas vezes vale a pena: uma **sparkline**, o nome que Tufte deu a um
gráfico de linha do tamanho de uma palavra, sem eixos. Ela mostra se o número chegou ali por uma
subida constante ou por um pico, o que a comparação não mostra.

## Montando um no matplotlib

Aqui está o topo do painel da Horta montado a partir dos arquivos CSV: três cartões, a tendência
embaixo deles ocupando dois terços da largura, e o crescimento por região ao lado.

```schooling-example
{"language": "python", "file": "dashboard.py", "parts": [{"code": "import csv\nimport statistics\nimport matplotlib.pyplot as plt\n"}, {"code": "months, total = [], {}\nby_region = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        m, n = row[\"month\"], int(row[\"orders\"])\n        total[m] = total.get(m, 0) + n\n        year = by_region.setdefault(row[\"region\"], {\"2024\": 0, \"2025\": 0})\n        year[m[:4]] += n\nmonths = sorted(total)\n", "note": "Soma os pedidos de cada mês somando as regiões, e os pedidos de cada região por ano, numa passada pelo arquivo."}, {"code": "with open(\"deliveries.csv\") as f:\n    minutes = [float(row[\"minutes\"]) for row in csv.DictReader(f)]\n", "note": "Os tempos de entrega, para o terceiro cartão."}, {"code": "y24 = sum(v for m, v in total.items() if m.startswith(\"2024\"))\ny25 = sum(v for m, v in total.items() if m.startswith(\"2025\"))\nkpis = [\n    (\"orders in 2025\", f\"{y25:,}\", f\"{y25 / y24 - 1:+.1%} on 2024\"),\n    (\"orders in December\", f\"{total['2025-12']:,}\", f\"{total['2025-12'] / total['2024-12'] - 1:+.1%} on Dec 2024\"),\n    (\"median delivery\", f\"{statistics.median(minutes):.0f} min\",\n     f\"{sum(m > 45 for m in minutes) / len(minutes):.1%} over 45 min\"),\n]\nfor label, value, compare in kpis:\n    print(f\"{label:20} {value:>10}   {compare}\")\n", "note": "Calcula os três cartões como rótulo, valor e comparação, e os imprime. Cada comparação diz contra o que é."}, {"code": "fig = plt.figure(figsize=(9, 5.5))\ngrid = fig.add_gridspec(2, 3, height_ratios=[1, 3], hspace=0.4, wspace=0.5)\nfor i, (label, value, compare) in enumerate(kpis):\n    ax = fig.add_subplot(grid[0, i])\n    ax.axis(\"off\")\n    ax.text(0, 0.75, label, fontsize=10, color=\"#5a6274\")\n    ax.text(0, 0.3, value, fontsize=22, fontweight=\"bold\")\n    ax.text(0, 0.0, compare, fontsize=9, color=\"#5a6274\")\n", "note": "Uma grade de duas linhas e três colunas, a de cima com um terço da altura da de baixo. Cada cartão é um subplot com os eixos desligados e três linhas de texto: o rótulo pequeno e cinza, o número grande e em negrito, a comparação pequena embaixo."}, {"code": "trend = fig.add_subplot(grid[1, :2])\ntrend.plot(range(len(months)), [total[m] for m in months], color=\"#2b52c9\", linewidth=2)\ntrend.set_xticks([0, 6, 12, 18, 23], [months[i] for i in (0, 6, 12, 18, 23)])\ntrend.set_title(\"Orders per month\", loc=\"left\")\ntrend.spines[[\"top\", \"right\"]].set_visible(False)\n", "note": "A tendência ocupa as duas primeiras colunas da linha de baixo, então tem o dobro da largura de qualquer outra coisa."}, {"code": "growth = {r: v[\"2025\"] / v[\"2024\"] - 1 for r, v in by_region.items()}\nnames = sorted(growth, key=growth.get)\nside = fig.add_subplot(grid[1, 2])\nside.barh(names, [100 * growth[r] for r in names], color=\"#767676\")\nside.set_title(\"Growth, 2025 on 2024 (%)\", loc=\"left\")\nside.spines[[\"top\", \"right\"]].set_visible(False)\nfig.savefig(\"dashboard.png\", dpi=120, bbox_inches=\"tight\")\n", "note": "O crescimento por região na última coluna, ordenado para a barra mais longa ficar em cima, em cinza porque apoia o gráfico principal em vez de competir com ele."}]}
```

```
ana@vm:~/viz$ .venv/bin/python dashboard.py
orders in 2025          180,682   +25.9% on 2024
orders in December       20,586   +23.5% on Dec 2024
median delivery          33 min   14.5% over 45 min
```

O programa imprime os cartões antes de desenhá-los. Vale copiar isso: a linha impressa é algo para
conferir contra o dado, e a imagem só está certa se os números nela estiverem.

## Escolha comparações justas

- **Igual com igual.** Dezembro contra o dezembro anterior, não contra novembro (aula 16).
- **Diga qual é a comparação.** "+23,5%" sozinho deixa o leitor adivinhando "sobre o quê?".
- **Pinte a mudança só se a cor tiver significado.** Verde para cima está errado quando subir é ruim,
  como no tempo de entrega.
