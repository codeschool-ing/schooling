---
title: Os dados da Panela
version: 1
---

Toda análise deste curso roda sobre os números de uma única empresa. **A Panela não existe.** É um
negócio inventado de kits de refeição no Brasil: o cliente escolhe receitas no site e uma caixa de
ingredientes chega na porta, toda semana ou a cada quinze dias. Os dados de uma empresa real seriam
melhores e não podem ser publicados, então os da Panela são escritos por um programa, e o programa
está abaixo.

Salve-o como `panela.py` na pasta do curso. Ele não precisa de nada além do Python, nem dos
pacotes que você instalou na seção anterior, e escreve seis arquivos CSV:

| arquivo | o que é cada linha | linhas |
|---|---|---|
| `daily_orders.csv` | um dia de pedidos, de 2023 a 2025 | 1.096 |
| `snapshot.csv` | os mesmos dias, como um painel os viu em 31 de dezembro de 2025 | 1.096 |
| `experiment.csv` | um visitante num teste de uma página de checkout nova | 50.400 |
| `customers.csv` | um cliente que se cadastrou em 2024 ou 2025 | 6.214 |
| `orders.csv` | um pedido feito por um desses clientes | 103.986 |
| `sessions.csv` | uma visita ao site em março de 2025 | 55.800 |

As aulas de séries temporais, de 1 a 6, usam os dois primeiros. As aulas de teste A/B, de 7 a 11,
usam o `experiment.csv`. As aulas de coortes e segmentação, de 12 a 15, usam os clientes, os
pedidos deles e as visitas ao site, e as aulas de aprendizado de máquina do fim também.

```python
"""Panela's data, for the bi-techniques course.

Panela is an invented meal-kit company in Brazil: a customer picks recipes
on the website and a box of ingredients arrives at their door. Every
analysis in the course is run on the files this program writes:

    daily_orders.csv   orders per day, 2023 to 2025
    snapshot.csv       the same days as a dashboard saw them on 31 Dec 2025
    experiment.csv     one row per visitor in a checkout test, March 2025
    customers.csv      every customer who signed up in 2024 or 2025
    orders.csv         every order those customers placed
    sessions.csv       one row per website visit in March 2025

The random numbers come from fixed seeds, so every computer that runs
this program gets exactly the same data. It needs nothing but Python.
"""
import csv
import math
import random
from datetime import date, timedelta

START, END = date(2023, 1, 1), date(2025, 12, 31)
PRICE_RISE = date(2025, 9, 1)
WEEKDAY = [1.18, 1.08, 1.00, 0.98, 0.95, 0.86, 0.95]  # Monday first
CARNIVAL = [date(2023, 2, 21), date(2024, 2, 13), date(2025, 3, 4)]
BLACK_FRIDAY = [date(2023, 11, 24), date(2024, 11, 29), date(2025, 11, 28)]
REGIONS = {"Southeast": 0.74, "South": 0.13, "Northeast": 0.09, "North": 0.04}
CHANNELS = {"search": 0.40, "social": 0.35, "referral": 0.25}


def days(a, b):
    while a <= b:
        yield a
        a += timedelta(days=1)


def pick(rng, weights):
    return rng.choices(list(weights), list(weights.values()))[0]


def holiday(d):
    """How much busier than usual a day is, because of the calendar."""
    if any(0 <= (t - d).days <= 3 for t in CARNIVAL):
        return 0.62  # Saturday to Tuesday of Carnival: people travel
    if d in BLACK_FRIDAY:
        return 1.65
    if (d.month, d.day) in [(12, 24), (12, 25), (12, 31), (1, 1)]:
        return 0.45
    if d.month == 12 and 17 <= d.day <= 23:
        return 1.22  # the festive boxes
    return 1.0


def level(d):
    """The trend: growth that slows, and a drop when prices rise."""
    t = (d - START).days / 365.25
    base = 800 * (1 + 0.42 * t - 0.035 * t * t)
    return base * (0.86 if d >= PRICE_RISE else 1.0)


def season(d):
    """The year: quiet in the January holidays, busy towards December."""
    angle = 2 * math.pi * (d.timetuple().tm_yday - 15) / 365.25
    return 1 - 0.09 * math.cos(angle) - 0.04 * math.sin(2 * angle)


def daily_orders():
    rng = random.Random(1)
    rows = []
    for d in days(START, END):
        mean = level(d) * season(d) * WEEKDAY[d.weekday()] * holiday(d)
        rows.append((d, round(mean * math.exp(rng.gauss(0, 0.045)))))
    return rows


def snapshot(rows):
    """Late orders are counted when they are paid, so the last days look low."""
    seen = {END: 0.58, END - timedelta(1): 0.86, END - timedelta(2): 0.96}
    return [(d, round(n * seen.get(d, 1.0))) for d, n in rows]


def experiment():
    """A checkout test: 21 days, half the visitors see the new page."""
    rng = random.Random(2)
    rows, n = [], 0
    for day in range(21):
        for _ in range(2400):
            n += 1
            group = "new" if rng.random() < 0.5 else "old"
            device = "mobile" if rng.random() < 0.68 else "desktop"
            rate = 0.042
            if group == "new":
                rate += 0.004 + 0.012 * math.exp(-day / 3)  # novelty wears off
            day_ = date(2025, 3, 10) + timedelta(day)
            rows.append((f"v{n:06d}", day_, group, device, int(rng.random() < rate)))
    return rows


def customers_and_orders():
    rng = random.Random(3)
    customers, orders = [], []
    for d in days(date(2024, 1, 1), END):
        for _ in range(rng.choice([7, 8, 9, 10, 11]) if d < PRICE_RISE else rng.choice([5, 6, 7])):
            cid = f"c{len(customers) + 1:05d}"
            region, channel = pick(rng, REGIONS), pick(rng, CHANNELS)
            plan = "weekly" if rng.random() < 0.6 else "fortnightly"
            customers.append((cid, d, region, channel, plan))
            # A month's chance of leaving, which onboarding improved in 2025.
            leave = {"search": 0.10, "social": 0.17, "referral": 0.07}[channel]
            leave *= 0.75 if d >= date(2025, 1, 1) else 1.0
            gap = 7 if plan == "weekly" else 14
            if region == "North":
                gap += 7  # deliveries reach the North a week later
            appetite = rng.uniform(0.55, 0.95)
            people = 4 if rng.random() < 0.35 else 2
            when = d
            while when <= END:
                price = (279.90 if people == 4 else 159.90) * (1.1 if when >= PRICE_RISE else 1)
                if when == d or rng.random() < appetite:
                    orders.append((f"o{len(orders) + 1:06d}", cid, when, f"{price:.2f}"))
                when += timedelta(gap)
                if rng.random() < 1 - (1 - leave) ** (gap / 30):
                    break
    return customers, orders


def sessions():
    """Visits to the website: landing, menu, box, checkout, paid."""
    rng = random.Random(4)
    rows, n = [], 0
    for d in days(date(2025, 3, 1), date(2025, 3, 31)):
        for _ in range(1800):
            n += 1
            device = "mobile" if rng.random() < 0.68 else "desktop"
            visitor = f"v{rng.randrange(1, 32000):05d}"
            step = 1
            go_on = [0.62, 0.55, 0.71, 0.48 if device == "mobile" else 0.83]
            for p in go_on:
                if rng.random() >= p:
                    break
                step += 1
            rows.append((f"s{n:06d}", visitor, d, device, step))
    return rows


def write(name, header, rows):
    with open(name, "w", newline="") as f:
        out = csv.writer(f)
        out.writerow(header)
        out.writerows(rows)
    print(f"{name:18} {len(rows):7,} rows")


if __name__ == "__main__":
    daily = daily_orders()
    write("daily_orders.csv", ["date", "orders"], daily)
    write("snapshot.csv", ["date", "orders"], snapshot(daily))
    write("experiment.csv", ["visitor", "day", "group", "device", "converted"], experiment())
    people, bought = customers_and_orders()
    write("customers.csv", ["customer", "signup", "region", "channel", "plan"], people)
    write("orders.csv", ["order", "customer", "date", "value"], bought)
    write("sessions.csv", ["session", "visitor", "date", "device", "step"], sessions())
```

**Os números vêm de um gerador de números aleatórios iniciado numa semente fixa.**
`random.Random(1)` produz a mesma sequência em qualquer computador, então o arquivo que você
escreve é aquele em que estas aulas foram gravadas, até o último pedido. Esse é o único motivo de o
dado ser reprodutível, e tem uma consequência que vale saber cedo: os padrões dele foram escolhidos
por alguém. O padrão dos dias da semana é a lista `WEEKDAY`, o aumento de preço é a data
`PRICE_RISE`, e o Carnaval são três datas numa lista. Ler o programa diz o que as análises deveriam
encontrar, e é por isso que as aulas pedem que você encontre primeiro e leia o programa depois.

Rode-o a partir da pasta do curso:

```
ana@vm:~/bi$ python3 panela.py
daily_orders.csv     1,096 rows
snapshot.csv         1,096 rows
experiment.csv      50,400 rows
customers.csv        6,214 rows
orders.csv         103,986 rows
sessions.csv        55,800 rows
ana@vm:~/bi$ head -4 daily_orders.csv
date,orders
2023-01-01,337
2023-01-02,938
2023-01-03,806
```

Leva cerca de um segundo, e ele imprime uma linha por arquivo com o número de linhas que escreveu.
Os arquivos caem na pasta de onde você o rodou, que é a pasta de onde todo programa seguinte os
lê. O `head` mostra as primeiras linhas de um deles: um cabeçalho, depois uma data e uma contagem
por linha. O primeiro dia é baixo porque é o dia de Ano-Novo.
