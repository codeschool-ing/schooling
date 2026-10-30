---
title: Achando o dia em que o gasto mudou
version: 1
---

Um pico é um dia que custa mais que **o usual**, e o usual é o que precisa ser definido com cuidado. O custo diário da
loja por serviço, por 45 dias, inventado pelo `days.py` para que o arquivo seja o mesmo para todo mundo, com algo
errado a partir de 9 de outubro. Trabalhe em `~/gcp/bill` (`mkdir -p ~/gcp/bill && cd ~/gcp/bill`):

```python
# days.py: writes costs.csv, a made-up 45 days (or as many as asked) of the shop's daily cost by service
import csv
import datetime as dt
import random
import sys

rand = random.Random(25)
days = int(sys.argv[1]) if len(sys.argv) > 1 else 45
# service: USD on a weekday, USD on a weekend day
usual = {"Cloud Run": (11.5, 8.0), "Compute Engine": (5.2, 5.2), "Cloud Logging": (1.3, 1.0),
         "Cloud Build": (0.9, 0.2), "Cloud Storage": (0.6, 0.6)}
start = dt.date(2026, 9, 1)
with open("costs.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["date", "service", "usd"])
    for n in range(days):
        day = start + dt.timedelta(days=n)
        weekend = day.weekday() >= 5
        for service, (weekday_usd, weekend_usd) in usual.items():
            usd = (weekend_usd if weekend else weekday_usd) * rand.uniform(0.92, 1.08)
            if service == "Cloud Logging" and day >= dt.date(2026, 10, 9):
                usd += 40 * 0.50  # 40 GiB a day of debug logs, left on after a deployment
            w.writerow([day.isoformat(), service, f"{usd:.2f}"])
print(f"costs.csv: {days} days")
```

O `spike.py` compara cada dia com a **mediana dos catorze dias anteriores**: uma mediana ignora o único dia estranho
da janela, onde uma média seria puxada para cima por ele. Um dia é pico quando está 30% acima do usual **e** mais de
5 USD acima dele, para que um dia barato dobrando de 1 para 2 USD não acione ninguém. Para cada pico ele nomeia o
serviço cujo custo mais se mexeu contra a sua própria mediana:

```python
# spike.py: the days whose cost left the usual, and the service that moved
import collections
import csv
import statistics

daily = collections.defaultdict(dict)
for row in csv.DictReader(open("costs.csv")):
    daily[row["date"]][row["service"]] = float(row["usd"])
days = sorted(daily)

for i, day in enumerate(days):
    if i < 14:
        continue  # two weeks of history before judging anything
    before = days[i - 14:i]
    total = sum(daily[day].values())
    usual = statistics.median(sum(daily[d].values()) for d in before)
    if total > usual * 1.3 and total - usual > 5:
        moved = max(daily[day], key=lambda s: daily[day][s] - statistics.median(daily[d][s] for d in before))
        extra = daily[day][moved] - statistics.median(daily[d][moved] for d in before)
        print(f"{day}  {total:6.2f} USD, usual {usual:5.2f}  {moved} +{extra:.2f}")

october = [d for d in days if d.startswith("2026-10")]
so_far = sum(sum(daily[d].values()) for d in october)
print(f"October so far: {so_far:.2f} USD in {len(october)} days, "
      f"{so_far / len(october) * 31:.2f} at this rate for the month")
```

```
ana@laptop:~/gcp/bill$ python3 days.py
costs.csv: 45 days
ana@laptop:~/gcp/bill$ python3 spike.py
2026-10-09   39.50 USD, usual 18.86  Cloud Logging +20.04
2026-10-10   34.70 USD, usual 18.86  Cloud Logging +19.72
2026-10-11   34.39 USD, usual 19.05  Cloud Logging +19.75
2026-10-12   39.48 USD, usual 19.32  Cloud Logging +20.06
2026-10-13   39.11 USD, usual 19.37  Cloud Logging +19.91
2026-10-14   39.03 USD, usual 19.59  Cloud Logging +19.96
2026-10-15   39.26 USD, usual 19.84  Cloud Logging +20.03
October so far: 411.35 USD in 15 days, 850.12 at this rate for the month
```

**Todo dia desde 9 de outubro está cerca de 20 USD acima do usual, e tudo isso é Cloud Logging.** Vinte dólares por
dia a 0,50 USD por gibibyte, o preço de ingestão da lição 9, são quarenta gibibytes de logs por dia que não eram
escritos antes. Isso não é uma pergunta de faturamento; é um incidente com causa, aqui um nível de debug esquecido
ligado depois de uma implantação, e ele passa pela lição 15 como qualquer outro: declarado, mitigado baixando o nível
de novo, revisado.

A última linha é a previsão do orçamento feita à mão: nesse ritmo outubro termina perto de 850 USD, acima do orçamento
de 700 da lição 24, que é a regra de previsão disparando no dia 9 em vez de no dia 30.

## A janela que perdoa

Leia a coluna `usual`: ela sobe devagar de 18,86 para 19,84 USD. Cada dia de pico entra na janela, e depois de
**sete** deles, metade de catorze, a mediana já está indo em direção ao pico. Rodar o mesmo programa sobre sessenta
dias mostra onde isso termina:

```
ana@laptop:~/gcp/bill$ python3 days.py 60
costs.csv: 60 days
ana@laptop:~/gcp/bill$ python3 spike.py | tail -3
2026-10-15   39.26 USD, usual 19.84  Cloud Logging +20.03
2026-10-16   38.98 USD, usual 27.19  Cloud Logging +10.10
October so far: 983.65 USD in 30 days, 1016.44 at this rate for the month
```

**O dia 16 é o último relatado.** A partir do dia 17 os logs de debug são o usual, e nada mais é relatado. Um pico
deixado em paz vira o novo normal de qualquer detector construído sobre uma linha de base recente. **A detecção compra
uma semana, não um conserto**, e a semana é para alguém agir.
