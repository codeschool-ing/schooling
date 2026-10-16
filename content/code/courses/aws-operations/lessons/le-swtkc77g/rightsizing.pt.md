---
title: Ajustando o tamanho a partir de duas semanas de uso
version: 1
---

Uma instância com o dobro do tamanho necessário custa o dobro toda hora, e nada na conta diz isso.
**Rightsizing** é escolher o tamanho pelo que a carga usa, e não pelo que alguém chutou no lançamento.
Precisa do uso, e dois números por instância respondem à maior parte: **a CPU nas horas mais cheias**, e
**o máximo de memória que ela já ocupou**.

As duas semanas da loja, inventadas por um programa para o arquivo ser o mesmo para todo mundo, quatro
instâncias hora a hora:

```python
# fortnight.py: writes usage.csv, two made-up weeks of the shop's instances, hour by hour
import csv
import random

rand = random.Random(23)
# name, size, typical CPU % in working hours and at night, memory % in use
fleet = [("api-1", "m7g.xlarge", 22, 6, 35), ("api-2", "m7g.xlarge", 24, 7, 36),
         ("worker", "m7g.2xlarge", 70, 55, 62), ("reports", "m7g.xlarge", 9, 2, 71)]
with open("usage.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["hour", "instance", "size", "cpu", "memory"])
    for hour in range(14 * 24):
        busy = 9 <= hour % 24 < 18 and hour // 24 % 7 < 5
        for name, size, day, night, mem in fleet:
            cpu = (day if busy else night) * rand.uniform(0.6, 1.6)
            w.writerow([hour, name, size, round(min(cpu, 100), 1), round(mem * rand.uniform(0.9, 1.1), 1)])
print("usage.csv:", 14 * 24 * len(fleet), "rows")
```

E a regra, em `rightsize.py`:

```python
# rightsize.py: a size for each instance from two weeks of CPU and memory
import collections
import csv

PRICE = {"m7g.large": 0.1301, "m7g.xlarge": 0.2601, "m7g.2xlarge": 0.5202}  # USD an hour, on demand
SMALLER = {"m7g.xlarge": "m7g.large", "m7g.2xlarge": "m7g.xlarge"}

cpu, memory, size = collections.defaultdict(list), collections.defaultdict(list), {}
for row in csv.DictReader(open("usage.csv")):
    cpu[row["instance"]].append(float(row["cpu"]))
    memory[row["instance"]].append(float(row["memory"]))
    size[row["instance"]] = row["size"]

print(f"{'instance':<9} {'size':<12} {'p95 cpu':>7} {'max mem':>7}  advice")
saved = 0.0
for name in sorted(cpu):
    p95 = sorted(cpu[name])[int(len(cpu[name]) * 0.95)]
    top = max(memory[name])
    smaller = SMALLER.get(size[name])
    # half the size doubles both: it must still leave room in the busiest hours
    if p95 >= 90:
        advice = "up: the busiest hours are at the limit"
    elif smaller and p95 * 2 < 80 and top * 2 < 85:
        advice = f"down to {smaller}, {(PRICE[size[name]] - PRICE[smaller]) * 730:.2f} USD a month less"
        saved += (PRICE[size[name]] - PRICE[smaller]) * 730
    elif smaller and p95 * 2 < 80:
        advice = "keep: memory would not fit in half"
    else:
        advice = "keep"
    print(f"{name:<9} {size[name]:<12} {p95:>6.1f}% {top:>6.1f}%  {advice}")
print(f"saved a month: {saved:.2f} USD")
```

```
ana@laptop:~/aws/rightsize$ python3 fortnight.py
usage.csv: 1344 rows
ana@laptop:~/aws/rightsize$ python3 rightsize.py
instance  size         p95 cpu max mem  advice
api-1     m7g.xlarge     31.1%   38.4%  down to m7g.large, 94.90 USD a month less
api-2     m7g.xlarge     34.1%   39.6%  down to m7g.large, 94.90 USD a month less
reports   m7g.xlarge     12.6%   78.0%  keep: memory would not fit in half
worker    m7g.2xlarge   100.0%   68.2%  up: the busiest hours are at the limit
saved a month: 189.80 USD
```

## Por que esses números

**O percentil 95 da CPU, e não a média.** Uma média de duas semanas conta noites e fins de semana, e a
média da API fica abaixo de 15%; dimensionada por ela, a API cairia todo dia útil às onze. O p95 são as
horas mais cheias menos os picos mais raros. **O máximo da memória, e não um percentil**, porque um
processo que fica sem memória não fica lento, é morto.

Cortar o tamanho pela metade corta tanto as vCPUs quanto a memória, então as duas porcentagens dobram. A
API com p95 de 31% rodaria a uns 62% na metade da máquina, com folga para uma semana mais cheia; a memória
dela, de 38%, vira 77%, dentro do limite. **Duas instâncias, 94,90 USD por mês cada**, pelas linhas `m7g` da
lista de preços.

`reports` quase não usa CPU e usa três quartos da memória: cortá-la pela metade não deixaria folga. A
resposta real para ela é outra família, `r7g`, com o dobro de memória por vCPU, que é uma escolha que uma
tabela de tamanhos não mostra. E `worker` é o caso oposto: as horas mais cheias dele estão em 100%, ou
seja, **subdimensionado**. O rightsizing acha esses também, e uma equipe que só lê a coluna *para baixo*
roda o serviço mais ocupado numa máquina pequena demais.

## O que este programa não vê

**Memória não é uma métrica que o EC2 informa.** CPU, rede e disco vêm do hipervisor; a memória está
dentro do sistema operacional, e o CloudWatch só a tem se o agente do CloudWatch a publicar de dentro
da instância. Sem ele, qualquer rightsizing, o do Compute Optimizer inclusive, decide só pela CPU e pode
recomendar um tamanho em que a memória da carga não cabe. É a primeira coisa a instalar antes de confiar
numa recomendação para baixo.
