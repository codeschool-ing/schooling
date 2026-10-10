---
title: Your data, and the program that makes it
version: 1
---

**The course works on one data set from beginning to end**, so that by lesson 14 you know it well
enough to notice when a join has done something wrong to it. It belongs to **Maré Bikes**, a
bike-share scheme in Recife that does not exist: twenty stations from the old centre to Boa
Viagem, and every trip anybody took on one of its bikes in 2025.

You do not download it. You make it, with the program below, and that is a decision rather than a
convenience. A file from somewhere else is a file you cannot reproduce: if yours differs from the
course's, nobody can say which is right. A program with a fixed seed writes **the same 33,337 trips
on every computer**, so every number in every lesson is one you can get yourself. Lesson 8 is
about how a seed does that.

Save it as `make_data.py` inside `pydata`. In JupyterLab, the launcher's **Python File** button
opens an empty one; paste the program, save it with that name, and close it.

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

Then run it, in the terminal, inside `pydata` with the environment active:

@@capture:make@@

Three files, and nothing in them you could not read with a text editor:

@@capture:look@@

| file | one row is | columns |
|---|---|---|
| `stations.csv` | a station, as it was named from a date onwards | `station_id`, `name`, `docks`, `valid_from` |
| `weather.csv` | a day in Recife | `date`, `rain_mm`, `temp_max` |
| `trips.csv` | one ride, from the dock it left to the dock it reached | `trip_id`, `started_at`, `ended_at`, `start_station`, `end_station`, `plan`, `bike` |

`plan` is `annual` for a subscriber and `day` for somebody who bought a day pass; `bike` is
`classic` or `electric`. A trip with no `ended_at` and no `end_station` is a bike that never came
back to a dock, and there are a few of them on purpose.

There are other things in these files on purpose too, of the kind any real data set has. They are
not listed here, because finding them is what several lessons are about. The program itself will
read clearly to you by lesson 16; until then it is enough that it runs, and that it prints what it
printed here.
