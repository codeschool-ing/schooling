---
title: O seu primeiro gráfico
version: 1
---

Todo gráfico deste curso é desenhado a partir de um arquivo de dados. Salve o programa abaixo como
`horta.py` na pasta do curso. Ele inventa dois anos de vendas de um mercado: **a Horta não existe**,
e todo número que ele escreve vem de um gerador de números aleatórios iniciado com uma semente fixa.
É isso que faz o dado ser o mesmo no seu computador e no computador em que as aulas foram gravadas,
até o último pedido.

```python
"""Horta's data, for the visualization course.

Horta is an invented online grocer. Every chart in the course is drawn from
the numbers this file makes, and running it writes them as CSV files that a
spreadsheet or a plotting library can open:

    python3 horta.py

The random numbers come from a fixed seed, so every computer that runs this
gets exactly the same data.
"""
import csv
import math
import random

REGIONS = ["Southeast", "South", "Northeast", "Centre-West", "North"]
MONTHS = [f"{y}-{m:02d}" for y in (2024, 2025) for m in range(1, 13)]

# Revenue in 2025 by product category, in thousands of reais.
CATEGORIES = {"Vegetables": 412, "Fruit": 386, "Dairy": 351,
              "Bakery": 298, "Drinks": 274, "Pantry": 239}

# Orders in 2025 and population in millions (2022 census, rounded) by state.
STATES = {
    "SP": (61040, 44.4), "MG": (19310, 20.5), "RJ": (21950, 16.1),
    "BA": (9120, 14.1), "PR": (14760, 11.4), "RS": (12980, 10.9),
    "PE": (6870, 9.1), "CE": (6010, 8.8), "PA": (3020, 8.1),
    "SC": (11240, 7.6), "GO": (6650, 7.1), "MA": (2110, 6.8),
    "AM": (1830, 3.9), "ES": (4120, 3.8), "PB": (2390, 4.0),
    "RN": (2260, 3.3), "MT": (3310, 3.7), "AL": (1540, 3.1),
    "PI": (1290, 3.3), "DF": (5480, 2.8), "MS": (2610, 2.8),
    "SE": (1310, 2.2), "RO": (820, 1.6), "TO": (610, 1.5),
    "AC": (190, 0.8), "AP": (160, 0.7), "RR": (140, 0.6),
}


def normal(rng, mean, sd):
    """One draw from a bell curve, built from random() alone."""
    u, v = rng.random(), rng.random()
    return mean + sd * math.sqrt(-2 * math.log(1 - u)) * math.cos(2 * math.pi * v)


def monthly_orders():
    """Orders per region per month: a trend, a December peak and noise."""
    rng = random.Random(2024)
    base = {"Southeast": 5200, "South": 2100, "Northeast": 1900,
            "Centre-West": 900, "North": 480}
    growth = {"Southeast": 0.012, "South": 0.018, "Northeast": 0.031,
              "Centre-West": 0.022, "North": 0.040}
    rows = []
    for i, month in enumerate(MONTHS):
        peak = 1.25 if month.endswith("-12") else 1.0
        for region in REGIONS:
            mean = base[region] * (1 + growth[region]) ** i * peak
            rows.append({"month": month, "region": region,
                         "orders": round(normal(rng, mean, mean * 0.04))})
    return rows


def deliveries(n=400):
    """One row per delivery: distance, items, rain, basket and minutes."""
    rng = random.Random(400)
    rows = []
    for i in range(n):
        region = REGIONS[min(4, int(rng.random() ** 1.6 * 5))]
        km = round(0.8 - 4.5 * math.log(1 - rng.random()), 1)
        items = 1 + int(rng.random() * 9) + int(rng.random() * 9)
        rain = 1 if rng.random() < 0.22 else 0
        minutes = 16 + 2.1 * km + 0.6 * items + 7 * rain + normal(rng, 0, 4.5)
        basket = 9.5 * items + normal(rng, 0, 12) + 20
        rows.append({"id": i + 1, "region": region, "km": km, "items": items,
                     "rain": rain, "basket": round(max(basket, 8), 2),
                     "minutes": round(max(minutes, 9), 1)})
    return rows


def hourly_orders():
    """Orders in an ordinary week, by weekday and hour of the day."""
    rng = random.Random(7)
    rows = []
    for d, day in enumerate(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]):
        weekend = d >= 5
        for hour in range(8, 23):
            lunch = math.exp(-((hour - 12) / 1.6) ** 2)
            evening = math.exp(-((hour - 19) / 1.8) ** 2)
            mean = (40 + 60 * lunch + 110 * evening if not weekend
                    else 55 + 120 * math.exp(-((hour - 11) / 2.5) ** 2) + 40 * evening)
            rows.append({"day": day, "hour": hour,
                         "orders": round(normal(rng, mean, 6))})
    return rows


def write(name, rows):
    with open(name, "w", newline="") as f:
        out = csv.DictWriter(f, fieldnames=list(rows[0]))
        out.writeheader()
        out.writerows(rows)
    print(f"wrote {name}: {len(rows)} rows")


if __name__ == "__main__":
    write("monthly.csv", monthly_orders())
    write("deliveries.csv", deliveries())
    write("hourly.csv", hourly_orders())
    write("categories.csv", [{"category": k, "revenue": v} for k, v in CATEGORIES.items()])
    write("states.csv", [{"state": k, "orders": o, "population": p}
                         for k, (o, p) in STATES.items()])
```

Você não precisa lê-lo. O que importa é o que ele escreve: cinco arquivos CSV, um para cada
conjunto de dados que o curso usa.

```
ana@vm:~/viz$ .venv/bin/python horta.py
wrote monthly.csv: 120 rows
wrote deliveries.csv: 400 rows
wrote hourly.csv: 105 rows
wrote categories.csv: 6 rows
wrote states.csv: 27 rows
ana@vm:~/viz$ head -4 monthly.csv
month,region,orders
2024-01,Southeast,5168
2024-01,South,2154
2024-01,Northeast,1884
```

| arquivo | uma linha é | usado a partir da |
|---|---|---|
| `monthly.csv` | uma região num mês, de 2024 a 2025 | esta aula |
| `deliveries.csv` | uma entrega: distância, itens, chuva, cesta, minutos | aula 5 |
| `hourly.csv` | uma hora de um dia da semana | aula 7 |
| `categories.csv` | a receita de uma categoria de produto em 2025 | aula 2 |
| `states.csv` | os pedidos e a população de um estado brasileiro | aula 8 |

Os nomes das colunas e das regiões dentro dos arquivos ficam em inglês, como o próprio programa:
`Southeast` é o Sudeste, `North` é o Norte.

## Numa planilha

Abra o `monthly.csv` no LibreOffice Calc ou no Excel. Insira uma tabela dinâmica com **region** nas
linhas e a soma de **orders** nos valores, filtrando **month** para as linhas de 2025, e depois
insira um gráfico de barras a partir da tabela dinâmica. Você vai ter os mesmos cinco números que
aparecem abaixo, e um gráfico deles.

## Em Python

Salve isto como `bars.py` ao lado do `horta.py`:

```schooling-example
{"language": "python", "file": "bars.py", "parts": [{"code": "import csv\nimport matplotlib.pyplot as plt\n", "note": "Duas bibliotecas. `csv` vem com o Python e lê o arquivo; `pyplot` é a parte do matplotlib que desenha."}, {"code": "totals = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        if row[\"month\"].startswith(\"2025\"):\n            region = row[\"region\"]\n            totals[region] = totals.get(region, 0) + int(row[\"orders\"])\n", "note": "Soma os pedidos de cada região nos doze meses de 2025. O arquivo tem uma linha por região por mês, então é este passo que transforma 120 linhas em cinco números."}, {"code": "regions = sorted(totals, key=totals.get)\nvalues = [totals[r] for r in regions]\nfor region, value in zip(regions, values):\n    print(f\"{region:12} {value:7,}\")\n", "note": "Ordena as regiões pelo total e imprime. Imprimir os números que você vai desenhar é um hábito que vale manter: é assim que você percebe que um gráfico está errado."}, {"code": "fig, ax = plt.subplots(figsize=(6, 3))\nax.barh(regions, values, color=\"#2b52c9\")\nax.set_xlabel(\"orders in 2025\")\n", "note": "Uma figura de seis polegadas por três, com um par de eixos. `barh` desenha barras horizontais, uma por região, e o rótulo diz o que o comprimento significa."}, {"code": "fig.savefig(\"bars.png\", dpi=150, bbox_inches=\"tight\")\nprint(\"saved bars.png\")\n", "note": "Grava o gráfico num arquivo em vez de uma janela, para que o mesmo programa funcione num servidor, numa máquina virtual e numa conexão remota."}], "output": "North         11,852\nCentre-West   16,413\nSouth         34,926\nNortheast     39,924\nSoutheast     77,567\nsaved bars.png"}
```

E rode:

```
ana@vm:~/viz$ .venv/bin/python bars.py
North         11,852
Centre-West   16,413
South         34,926
Northeast     39,924
Southeast     77,567
saved bars.png
ana@vm:~/viz$ file bars.png
bars.png: PNG image data, 891 x 441, 8-bit/color RGBA, non-interlaced
```

Abra o `bars.png` em qualquer visualizador de imagens. É o gráfico da primeira seção desta aula, sem
as notas.

## Como as figuras deste curso são desenhadas

Os gráficos destas páginas não são capturas de tela do matplotlib. São desenhados pelo curso nas
cores desta página, para que acompanhem os temas claro e escuro, **a partir dos mesmos números que
os seus programas leem**. Onde uma figura e o seu `bars.png` diferem, a diferença é de estilo: a
fonte, a cor, o espaçamento das marcas do eixo. As barras têm o mesmo comprimento.
