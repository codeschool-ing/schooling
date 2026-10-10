---
title: Seus dados, e o programa que os cria
version: 1
---

**O curso trabalha sobre um único conjunto de dados do começo ao fim**, para que na aula 14 você o
conheça bem o bastante para perceber quando uma junção fez algo errado com ele. Ele pertence à
**Maré Bikes**, um sistema de bicicletas compartilhadas no Recife que não existe: vinte estações,
do centro antigo até Boa Viagem, e cada viagem que alguém fez numa das suas bicicletas em 2025.

Você não o baixa. Você o cria, com o programa abaixo, e isso é uma decisão e não uma comodidade.
Um arquivo vindo de outro lugar é um arquivo que você não consegue reproduzir: se o seu difere do
do curso, ninguém sabe dizer qual está certo. Um programa com uma semente fixa escreve **as mesmas
33.337 viagens em qualquer computador**, então cada número de cada aula é um número que você
consegue obter. A aula 8 é sobre como uma semente faz isso.

Salve-o como `make_data.py` dentro de `pydata`. No JupyterLab, o botão **Python File** do
lançador abre um arquivo vazio; cole o programa, salve com esse nome e feche.

```py
"""Maré Bikes, 2025: the three files this course reads."""
import numpy as np
import pandas as pd

rng = np.random.default_rng(2025)

names = ["Praça do Arsenal", "Marco Zero", "Rua da Aurora", "Parque 13 de Maio",
         "Praça do Derby", "Jaqueira", "Rua da Hora", "Casa Forte", "Madalena", "Torre",
         "Cidade Universitária", "Pina", "Segundo Jardim", "Praça de Boa Viagem",
         "Parque Dona Lindu", "Setúbal", "Graças", "Aflitos", "Encruzilhada", "Afogados"]
stations = pd.DataFrame({
    "station_id": [f"S{i:02d}" for i in range(1, 21)],
    "name": names,
    "docks": rng.integers(10, 21, size=20),
    "valid_from": "2025-01-01",
})
renamed = stations.iloc[[6]].assign(name="Espinheiro", valid_from="2025-07-01")
pd.concat([stations, renamed]).to_csv("stations.csv", index=False)

days = pd.date_range("2025-01-01", "2025-12-31", freq="D")
wet = days.month.isin([4, 5, 6, 7])
rain = np.where(rng.random(365) < np.where(wet, 0.7, 0.3), rng.gamma(1.2, 9, 365), 0)
weather = pd.DataFrame({
    "date": days.strftime("%Y-%m-%d"),
    "rain_mm": rain.round(1),
    "temp_max": (30.5 - 1.5 * wet + rng.normal(0, 0.8, 365)).round(1),
})
weather.loc[rng.choice(365, size=6, replace=False), "rain_mm"] = np.nan
weather.to_csv("weather.csv", index=False)

weekend = days.dayofweek >= 5
per_day = rng.poisson(np.where(weekend, 70, 110) * np.where(rain > 10, 0.55, 1.0))
day = np.repeat(np.arange(365), per_day)
n = len(day)
commute = np.array([1, 1, 1, 1, 2, 5, 10, 16, 12, 6, 5, 6, 7, 6, 5, 6, 10, 15, 11, 6, 4, 3, 2, 1])
leisure = np.array([1, 1, 1, 1, 1, 2, 4, 6, 8, 9, 9, 9, 9, 9, 9, 9, 9, 8, 7, 5, 4, 3, 2, 1])
hour = np.where(weekend[day], rng.choice(24, n, p=leisure / leisure.sum()),
                rng.choice(24, n, p=commute / commute.sum()))
start = days[day] + pd.to_timedelta(hour * 3600 + rng.integers(0, 3600, n), unit="s")
popularity = rng.dirichlet(np.full(20, 2.0))
plan = np.where(rng.random(n) < np.where(weekend[day], 0.5, 0.25), "day", "annual")
bike = np.where(rng.random(n) < 0.35, "electric", "classic")
minutes = rng.lognormal(2.6, 0.5, n) * np.where(bike == "electric", 0.8, 1) * np.where(plan == "day", 1.6, 1)
trips = pd.DataFrame({
    "trip_id": np.arange(1, n + 1),
    "started_at": start,
    "ended_at": start + pd.to_timedelta((minutes * 60).round(), unit="s"),
    "start_station": stations["station_id"].to_numpy()[rng.choice(20, n, p=popularity)],
    "end_station": stations["station_id"].to_numpy()[rng.choice(20, n, p=popularity)],
    "plan": plan,
    "bike": bike,
})
lost = rng.random(n) < 0.004
trips.loc[lost, ["ended_at", "end_station"]] = None
trips.to_csv("trips.csv", index=False)
print(f"{len(stations) + 1} station rows, {len(weather)} days, {n} trips")
```

Depois rode-o, no terminal, dentro de `pydata` e com o ambiente ativo:

```
(.venv) ana@lab:~/pydata$ python make_data.py
21 station rows, 365 days, 33337 trips
```

Três arquivos, e nada neles que você não consiga ler num editor de texto:

```
(.venv) ana@lab:~/pydata$ ls -l
total 2232
-rw-r--r-- 1 ana ana    2727 Oct 10 04:05 make_data.py
-rw-r--r-- 1 ana ana     674 Oct 10 04:06 stations.csv
-rw-r--r-- 1 ana ana 2267957 Oct 10 04:06 trips.csv
-rw-r--r-- 1 ana ana    7367 Oct 10 04:06 weather.csv
(.venv) ana@lab:~/pydata$ head -3 stations.csv weather.csv trips.csv
==> stations.csv <==
station_id,name,docks,valid_from
S01,Praça do Arsenal,14,2025-01-01
S02,Marco Zero,20,2025-01-01

==> weather.csv <==
date,rain_mm,temp_max
2025-01-01,0.0,29.9
2025-01-02,6.8,30.0

==> trips.csv <==
trip_id,started_at,ended_at,start_station,end_station,plan,bike
1,2025-01-01 12:22:38,2025-01-01 12:57:03,S07,S05,day,electric
2,2025-01-01 20:08:24,2025-01-01 20:25:16,S20,S07,annual,electric
```

| arquivo | uma linha é | colunas |
|---|---|---|
| `stations.csv` | uma estação, com o nome que teve a partir de uma data | `station_id`, `name`, `docks`, `valid_from` |
| `weather.csv` | um dia no Recife | `date`, `rain_mm`, `temp_max` |
| `trips.csv` | uma viagem, da doca de onde saiu até a doca aonde chegou | `trip_id`, `started_at`, `ended_at`, `start_station`, `end_station`, `plan`, `bike` |

`plan` é `annual` para um assinante e `day` para quem comprou um passe de um dia; `bike` é
`classic` ou `electric`. Uma viagem sem `ended_at` e sem `end_station` é uma bicicleta que
nunca voltou a uma doca, e há algumas de propósito.

Há outras coisas de propósito nesses arquivos, do tipo que todo conjunto de dados real tem. Elas
não estão listadas aqui, porque encontrá-las é o assunto de várias aulas. O programa em si vai se
ler com clareza para você na aula 16; até lá, basta que ele rode e imprima o que imprimiu aqui.
