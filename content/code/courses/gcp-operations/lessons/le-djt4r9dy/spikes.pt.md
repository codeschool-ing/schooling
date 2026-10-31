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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um gráfico de linha do custo diário da loja de 1º de setembro a 15 de outubro: cerca de 19 USD nos dias úteis e menos nos fins de semana. Uma segunda linha, o usual, a mediana dos 14 dias anteriores a cada dia, começa em 15 de setembro. Em 9 de outubro, marcado logs de debug ligados, o custo diário salta para cerca de 35 a 40 USD e fica ali, enquanto o usual mal se mexe.\"><defs><marker id=\"ah12\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"60\" y1=\"220\" x2=\"700\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"60\" y1=\"220\" x2=\"60\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><text x=\"54\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"54\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"54\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><line x1=\"60.0\" y1=\"141.2\" x2=\"74.54545454545455\" y2=\"142.4\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"74.54545454545455\" y1=\"142.4\" x2=\"89.0909090909091\" y2=\"142.36\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"89.0909090909091\" y1=\"142.36\" x2=\"103.63636363636363\" y2=\"140.76\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"103.63636363636363\" y1=\"140.76\" x2=\"118.18181818181819\" y2=\"160.95999999999998\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"118.18181818181819\" y1=\"160.95999999999998\" x2=\"132.72727272727275\" y2=\"161.95999999999998\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"132.72727272727275\" y1=\"161.95999999999998\" x2=\"147.27272727272725\" y2=\"143.84000000000003\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"147.27272727272725\" y1=\"143.84000000000003\" x2=\"161.8181818181818\" y2=\"140.96\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"161.8181818181818\" y1=\"140.96\" x2=\"176.36363636363637\" y2=\"142.4\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"176.36363636363637\" y1=\"142.4\" x2=\"190.9090909090909\" y2=\"143.6\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"190.9090909090909\" y1=\"143.6\" x2=\"205.45454545454547\" y2=\"141.56\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"205.45454545454547\" y1=\"141.56\" x2=\"220.0\" y2=\"161.32\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"220.0\" y1=\"161.32\" x2=\"234.54545454545453\" y2=\"161.32\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"234.54545454545453\" y1=\"161.32\" x2=\"249.0909090909091\" y2=\"143.39999999999998\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"249.0909090909091\" y1=\"143.39999999999998\" x2=\"263.6363636363636\" y2=\"141.15999999999997\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"263.6363636363636\" y1=\"141.15999999999997\" x2=\"278.1818181818182\" y2=\"141.64000000000001\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"278.1818181818182\" y1=\"141.64000000000001\" x2=\"292.72727272727275\" y2=\"143.88\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"292.72727272727275\" y1=\"143.88\" x2=\"307.27272727272725\" y2=\"141.60000000000002\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"307.27272727272725\" y1=\"141.60000000000002\" x2=\"321.8181818181818\" y2=\"162.48\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"321.8181818181818\" y1=\"162.48\" x2=\"336.3636363636364\" y2=\"160.68\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"336.3636363636364\" y1=\"160.68\" x2=\"350.90909090909093\" y2=\"142.27999999999997\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"350.90909090909093\" y1=\"142.27999999999997\" x2=\"365.45454545454544\" y2=\"145.36\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"365.45454545454544\" y1=\"145.36\" x2=\"380.0\" y2=\"141.12\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"380.0\" y1=\"141.12\" x2=\"394.54545454545456\" y2=\"145.64\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"394.54545454545456\" y1=\"145.64\" x2=\"409.09090909090907\" y2=\"140.36\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"409.09090909090907\" y1=\"140.36\" x2=\"423.6363636363636\" y2=\"160.84\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"423.6363636363636\" y1=\"160.84\" x2=\"438.1818181818182\" y2=\"159.16\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"438.1818181818182\" y1=\"159.16\" x2=\"452.72727272727275\" y2=\"142.44\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"452.72727272727275\" y1=\"142.44\" x2=\"467.27272727272725\" y2=\"145.52\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"467.27272727272725\" y1=\"145.52\" x2=\"481.8181818181818\" y2=\"142.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"481.8181818181818\" y1=\"142.0\" x2=\"496.3636363636364\" y2=\"146.92000000000002\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"496.3636363636364\" y1=\"146.92000000000002\" x2=\"510.90909090909093\" y2=\"143.04000000000002\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"510.90909090909093\" y1=\"143.04000000000002\" x2=\"525.4545454545455\" y2=\"159.39999999999998\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"525.4545454545455\" y1=\"159.39999999999998\" x2=\"540.0\" y2=\"156.68\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"540.0\" y1=\"156.68\" x2=\"554.5454545454545\" y2=\"144.56\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"554.5454545454545\" y1=\"144.56\" x2=\"569.090909090909\" y2=\"140.07999999999998\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"569.090909090909\" y1=\"140.07999999999998\" x2=\"583.6363636363636\" y2=\"144.56\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"583.6363636363636\" y1=\"144.56\" x2=\"598.1818181818181\" y2=\"141.24\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"598.1818181818181\" y1=\"141.24\" x2=\"612.7272727272727\" y2=\"62.00000000000003\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"612.7272727272727\" y1=\"62.00000000000003\" x2=\"627.2727272727273\" y2=\"81.19999999999999\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"627.2727272727273\" y1=\"81.19999999999999\" x2=\"641.8181818181819\" y2=\"82.44\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"641.8181818181819\" y1=\"82.44\" x2=\"656.3636363636364\" y2=\"62.079999999999984\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"656.3636363636364\" y1=\"62.079999999999984\" x2=\"670.9090909090909\" y2=\"63.56\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"670.9090909090909\" y1=\"63.56\" x2=\"685.4545454545455\" y2=\"63.879999999999995\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"685.4545454545455\" y1=\"63.879999999999995\" x2=\"700.0\" y2=\"62.95999999999998\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"263.6363636363636\" y1=\"142.9\" x2=\"278.1818181818182\" y2=\"142.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"278.1818181818182\" y1=\"142.9\" x2=\"292.72727272727275\" y2=\"142.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"292.72727272727275\" y1=\"142.9\" x2=\"307.27272727272725\" y2=\"143.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"307.27272727272725\" y1=\"143.5\" x2=\"321.8181818181818\" y2=\"143.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"321.8181818181818\" y1=\"143.5\" x2=\"336.3636363636364\" y2=\"143.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"336.3636363636364\" y1=\"143.5\" x2=\"350.90909090909093\" y2=\"143.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"350.90909090909093\" y1=\"143.5\" x2=\"365.45454545454544\" y2=\"142.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"365.45454545454544\" y1=\"142.9\" x2=\"380.0\" y2=\"143.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"380.0\" y1=\"143.5\" x2=\"394.54545454545456\" y2=\"143.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"394.54545454545456\" y1=\"143.5\" x2=\"409.09090909090907\" y2=\"143.64\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"409.09090909090907\" y1=\"143.64\" x2=\"423.6363636363636\" y2=\"143.64\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"423.6363636363636\" y1=\"143.64\" x2=\"438.1818181818182\" y2=\"143.64\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"438.1818181818182\" y1=\"143.64\" x2=\"452.72727272727275\" y2=\"143.64\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"452.72727272727275\" y1=\"143.64\" x2=\"467.27272727272725\" y2=\"143.16\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"467.27272727272725\" y1=\"143.16\" x2=\"481.8181818181818\" y2=\"144.62\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"481.8181818181818\" y1=\"144.62\" x2=\"496.3636363636364\" y2=\"144.62\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"496.3636363636364\" y1=\"144.62\" x2=\"510.90909090909093\" y2=\"145.44\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"510.90909090909093\" y1=\"145.44\" x2=\"525.4545454545455\" y2=\"145.44\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"525.4545454545455\" y1=\"145.44\" x2=\"540.0\" y2=\"145.44\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"540.0\" y1=\"145.44\" x2=\"554.5454545454545\" y2=\"145.44\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"554.5454545454545\" y1=\"145.44\" x2=\"569.090909090909\" y2=\"145.44\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"569.090909090909\" y1=\"145.44\" x2=\"583.6363636363636\" y2=\"145.04\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"583.6363636363636\" y1=\"145.04\" x2=\"598.1818181818181\" y2=\"145.04\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"598.1818181818181\" y1=\"145.04\" x2=\"612.7272727272727\" y2=\"144.56\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"612.7272727272727\" y1=\"144.56\" x2=\"627.2727272727273\" y2=\"144.56\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"627.2727272727273\" y1=\"144.56\" x2=\"641.8181818181819\" y2=\"143.8\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"641.8181818181819\" y1=\"143.8\" x2=\"656.3636363636364\" y2=\"142.74\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"656.3636363636364\" y1=\"142.74\" x2=\"670.9090909090909\" y2=\"142.52\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"670.9090909090909\" y1=\"142.52\" x2=\"685.4545454545455\" y2=\"141.62\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"685.4545454545455\" y1=\"141.62\" x2=\"700.0\" y2=\"140.66\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"612.7272727272727\" y1=\"220\" x2=\"612.7272727272727\" y2=\"44\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"606.7272727272727\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">9 out: logs de debug ligados</text><text x=\"292.72727272727275\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">usual: mediana dos 14 dias anteriores</text><text x=\"89.0909090909091\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">custo diário, USD</text><text x=\"60\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 set</text><text x=\"700\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">15 out</text></svg>", "caption": "O pico é evidente desde o primeiro dia; o usual mal começou a segui-lo."}
```

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
