---
title: Achando o dia em que o gasto mudou
version: 1
---

Um pico é um dia que custa mais que **o usual**, e o usual é o que precisa ser bem definido. O custo diário
da loja por serviço, por 45 dias, inventado pelo `days.py` para o arquivo ser o mesmo para todo mundo, com
algo errado a partir de 9 de outubro:

```python
# days.py: writes costs.csv, a made-up 45 days of the shop's daily cost by service
import csv
import datetime as dt
import random

rand = random.Random(25)
# service: USD on a weekday, USD on a weekend day
usual = {"EC2": (39.0, 31.0), "Data transfer": (6.2, 4.1), "CloudWatch": (1.9, 1.6),
         "S3": (2.0, 2.0), "WAF": (1.3, 1.0)}
start = dt.date(2026, 9, 1)
with open("costs.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["date", "service", "usd"])
    for n in range(45):
        day = start + dt.timedelta(days=n)
        weekend = day.weekday() >= 5
        for service, (weekday_usd, weekend_usd) in usual.items():
            usd = (weekend_usd if weekend else weekday_usd) * rand.uniform(0.92, 1.08)
            if service == "CloudWatch" and day >= dt.date(2026, 10, 9):
                usd += 35 * 0.90  # 35 GB a day of debug logs, left on after an incident
            w.writerow([day.isoformat(), service, f"{usd:.2f}"])
print("costs.csv: 45 days")
```

O `spike.py` compara cada dia com a **mediana dos catorze dias anteriores**: uma mediana ignora o único dia
estranho da janela, onde uma média seria puxada por ele. Um dia é um pico quando está 30% acima do usual
**e** mais de 10 USD acima dele, para que um dia barato dobrando de 2 para 4 USD não chame ninguém. Para
cada pico, ele nomeia o serviço cujo custo mais se mexeu contra a própria mediana:

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
    if total > usual * 1.3 and total - usual > 10:
        moved = max(daily[day], key=lambda s: daily[day][s] - statistics.median(daily[d][s] for d in before))
        extra = daily[day][moved] - statistics.median(daily[d][moved] for d in before)
        print(f"{day}  {total:7.2f} USD, usual {usual:6.2f}  {moved} +{extra:.2f}")

october = [d for d in days if d.startswith("2026-10")]
so_far = sum(sum(daily[d].values()) for d in october)
print(f"October so far: {so_far:.2f} USD in {len(october)} days, "
      f"{so_far / len(october) * 31:.2f} at this rate for the month")
```

```
ana@laptop:~/aws/bill$ python3 days.py
costs.csv: 45 days
ana@laptop:~/aws/bill$ python3 spike.py
2026-10-09    81.08 USD, usual  48.05  CloudWatch +31.55
2026-10-10    71.05 USD, usual  48.05  CloudWatch +31.23
2026-10-11    69.51 USD, usual  48.51  CloudWatch +31.27
2026-10-12    81.78 USD, usual  49.04  CloudWatch +31.60
2026-10-13    81.29 USD, usual  49.13  CloudWatch +31.38
2026-10-14    81.07 USD, usual  50.47  CloudWatch +31.43
2026-10-15    81.04 USD, usual  52.12  CloudWatch +31.54
October so far: 924.03 USD in 15 days, 1909.66 at this rate for the month
```

**Todo dia desde 9 de outubro está uns 31 USD acima do usual, e é tudo CloudWatch.** Trinta e um dólares
por dia a 0,90 USD por gigabyte, o preço de ingestão da lição 9, são trinta e cinco gigabytes de logs por
dia que não eram gravados antes. Isso não é uma questão de cobrança; é um incidente com causa, aqui um
nível de debug deixado ligado depois de um deploy, e ele passa pela lição 13 como qualquer outro:
declarado, mitigado baixando o nível de volta, revisado.

A última linha é a previsão do orçamento feita à mão: nesse ritmo outubro termina perto de 1.910 USD,
acima do orçamento de 1.600, que é a notificação da primeira seção disparando no dia 9 e não no dia 30.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um gráfico de linha do custo diário da loja de 1 de setembro a 15 de outubro, cerca de 48 USD nos dias úteis e menos nos fins de semana, com uma segunda linha para o usual, a mediana dos 14 dias anteriores a cada dia. Em 9 de outubro, marcado logs de debug ligados, o custo diário salta para cerca de 80 USD e fica lá, enquanto a linha do usual só começa a subir devagar.\"><defs><marker id=\"spk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 230 L690 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70 230 L70 50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"62\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"62\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><text x=\"62\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">80</text><path d=\"M70.0 129.7 L84.1 128.4 L98.2 129.9 L112.3 128.3 L126.4 151.9 L140.5 154.8 L154.5 130.7 L168.6 125.6 L182.7 130.1 L196.8 130.4 L210.9 129.7 L225.0 153.7 L239.1 154.1 L253.2 133.0 L267.3 127.8 L281.4 129.3 L295.5 133.3 L309.5 128.5 L323.6 153.4 L337.7 150.7 L351.8 128.3 L365.9 134.1 L380.0 126.9 L394.1 134.1 L408.2 125.8 L422.3 151.3 L436.4 147.5 L450.5 131.2 L464.5 134.9 L478.6 130.8 L492.7 135.7 L506.8 132.7 L520.9 151.6 L535.0 146.3 L549.1 134.5 L563.2 124.2 L577.3 133.3 L591.4 127.3 L605.5 67.8 L619.5 87.9 L633.6 91.0 L647.7 66.4 L661.8 67.4 L675.9 67.9 L690.0 67.9\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M267.3 130.2 L281.4 130.2 L295.5 130.2 L309.5 130.5 L323.6 130.5 L337.7 130.5 L351.8 130.5 L365.9 130.2 L380.0 131.7 L394.1 131.7 L408.2 133.2 L422.3 133.2 L436.4 133.2 L450.5 133.2 L464.5 132.3 L478.6 133.7 L492.7 133.7 L506.8 134.1 L520.9 134.1 L535.0 134.1 L549.1 134.1 L563.2 134.3 L577.3 134.3 L591.4 134.3 L605.5 133.9 L619.5 133.9 L633.6 133.0 L647.7 131.9 L661.8 131.7 L675.9 129.1 L690.0 125.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M605.5 230 L605.5 54.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"599.5\" y=\"58.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">9 out: logs de debug ligados</text><text x=\"351.8\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">usual: mediana dos 14 dias antes</text><text x=\"98.2\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">custo diário, USD</text><text x=\"70.0\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 set</text><text x=\"690.0\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">15 out</text><text x=\"605.5\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">9 out</text></svg>", "caption": "O pico fica claro desde o primeiro dia. O usual o segue, devagar, e depois de uma semana terá alcançado."}
```

## A janela que perdoa

Leia a coluna `usual`: ela sobe devagar de 48 para 52 USD. Cada dia de pico entra na janela; depois de
**sete** deles, metade de catorze, a mediana já está a meio caminho do pico, e a partir do dia 16 este
programa não reporta mais nada, como mostra rodá-lo num arquivo mais longo. Um pico deixado em paz vira o
novo normal de qualquer detector feito sobre uma base recente. **Detectar compra uma semana, não um
conserto**, e a semana é para alguém agir.
