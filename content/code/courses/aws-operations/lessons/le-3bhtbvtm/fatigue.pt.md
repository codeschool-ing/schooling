---
title: Medindo a fadiga de alertas
version: 1
---

**Fadiga de alertas** é o que acontece com pessoas chamadas por coisas que não pedem nada delas:
aprendem, com razão, que a maioria dos chamados pode ser ignorada, e então ignoram o único que não podia.
Ninguém decide parar de ler chamados. Acontece lá pelo quadragésimo chamado sobre um banco a 80% de CPU
que ninguém precisava saber, e aparece nos números muito antes de aparecer num incidente.

Os números são os próprios chamados. Um serviço de chamados os exporta; o mês da loja é inventado aqui,
por um programa, para ser o mesmo arquivo para todo mundo. Ele escreve uma linha por chamado: quando,
qual alarme e se a pessoa chamada **agiu**, quer dizer, fez qualquer coisa além de reconhecer e voltar a
dormir.

```python
# month.py: writes pages.csv, a made-up month of pages for the shop's API
import csv
import datetime as dt
import random

# alarm: (pages a day, share of pages somebody acted on, hours it tends to fire)
alarms = {
    "api-errors": (0.5, 0.8, range(24)),
    "api-latency": (0.6, 0.5, range(24)),
    "db-cpu": (1.5, 0.05, range(24)),
    "queue-depth": (0.8, 0.1, range(8, 20)),
    "disk-80": (1.0, 0.0, [3]),  # the nightly backup fills the disk for an hour
}
rand = random.Random(14)
start = dt.datetime(2026, 9, 14, tzinfo=dt.timezone(dt.timedelta(hours=-3)))
rows = []
for day in range(28):
    for name, (per_day, acted, hours) in alarms.items():
        for _ in range(int(per_day) + (rand.random() < per_day % 1)):
            at = start + dt.timedelta(days=day, hours=rand.choice(hours), minutes=rand.randrange(60))
            rows.append((at.isoformat(), name, "yes" if rand.random() < acted else "no"))
with open("pages.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["time", "alarm", "acted"])
    w.writerows(sorted(rows))
print(len(rows), "pages written")
```

A tabela no topo é a forma do mês, e é uma forma que plantões reais têm: dois alarmes sobre sintomas que
os clientes sentem, e três sobre causas que podem importar, um dos quais dispara toda noite porque um
backup enche o disco por uma hora.

```
ana@laptop:~/aws/oncall$ python3 month.py
121 pages written
ana@laptop:~/aws/oncall$ head -4 pages.csv
time,alarm,acted
2026-09-14T03:55:00-03:00,disk-80,no
2026-09-14T08:18:00-03:00,db-cpu,no
2026-09-14T14:25:00-03:00,queue-depth,no
```

Depois, um segundo programa conta quanto o mês custou:

```python
# fatigue.py: what a month of pages cost, alarm by alarm
# python3 fatigue.py [ALARM...] counts only the alarms named, if any
import collections
import csv
import datetime as dt
import sys

pages = collections.Counter()
acted = collections.Counter()
night = collections.Counter()
keep = set(sys.argv[1:])
for row in csv.DictReader(open("pages.csv")):
    if keep and row["alarm"] not in keep:
        continue
    hour = dt.datetime.fromisoformat(row["time"]).hour
    pages[row["alarm"]] += 1
    acted[row["alarm"]] += row["acted"] == "yes"
    night[row["alarm"]] += hour >= 22 or hour < 7

total = sum(pages.values())
print(f"{'alarm':<12} {'pages':>5} {'acted':>5} {'night':>5}")
for name, n in pages.most_common():
    print(f"{name:<12} {n:>5} {acted[name]:>5} {night[name]:>5}")
print(f"{'total':<12} {total:>5} {sum(acted.values()):>5} {sum(night.values()):>5}")
print(f"acted on: {sum(acted.values()) / total:.0%}, pages a week: {total / 4:.1f}")
```

```
ana@laptop:~/aws/oncall$ python3 fatigue.py
alarm        pages acted night
db-cpu          41     3    19
disk-80         28     0    28
queue-depth     22     2     0
api-errors      15    11     6
api-latency     15     7     4
total          121    23    57
acted on: 19%, pages a week: 30.2
```

Leia em três números. **121 chamados em quatro semanas** são trinta por semana, quatro por dia, quando o
teto do livro de SRE era dois incidentes num turno de doze horas. **57 à noite**, quase metade, e
`disk-80` mandou todos os seus 28 chamados entre 22:00 e 07:00. E o que mais importa: **alguém agiu em
19%**. Quatro chamados em cinco não pediam nada, e quem estava de plantão aprendeu essa lição trinta
vezes por semana.

A tabela diz de onde vem. `db-cpu` é o alarme mais barulhento e o menos útil, 3 ações em 41 chamados.
`api-errors` é o contrário: 11 de 15. Uma única medida os ordena, **a fração dos chamados de um alarme
em que alguém agiu**, e é o número a olhar na passagem semanal, alarme por alarme, e não só no total.

## O mesmo mês, chamando só por sintomas

A regra da lição 10 era chamar por sintomas e registrar causas. O programa recebe os alarmes a manter,
então a regra pode ser testada no mês passado antes de valer no mês que vem:

```
ana@laptop:~/aws/oncall$ python3 fatigue.py api-errors api-latency
alarm        pages acted night
api-errors      15    11     6
api-latency     15     7     4
total           30    18    10
acted on: 60%, pages a week: 7.5
```

**30 chamados em vez de 121**, 10 à noite em vez de 57, e 60% deles com ação. As 5 ações sobre causas
são a pergunta a fazer antes de mudar qualquer coisa: alguma delas tinha de acontecer à noite, ou
`api-errors` teria chamado de qualquer jeito se a causa tivesse chegado aos clientes? Quando a resposta
é a segunda, o alarme de causa vira um ticket, visto de manhã, e essa mudança é a próxima seção.
