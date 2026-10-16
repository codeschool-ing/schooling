---
title: transform, a resposta do grupo para cada linha
version: 1
---

**Uma agregação devolve uma linha por grupo; o `transform` devolve um valor por linha original, a
resposta do grupo espalhada de volta.** É como se compara uma linha com o próprio grupo: esta viagem
contra a viagem típica da estação, este dia contra o seu mês.

```python
station_median = trips.groupby("start_station")["minutes"].transform("median")
station_median.shape, trips["minutes"].shape
```

```
((33337,), (33337,))
```

O mesmo comprimento da tabela, então pode ficar ao lado dela como coluna. Cada viagem agora carrega a
duração mediana das viagens da sua estação de partida, e dividir dá uma razão que quer dizer a mesma
coisa em toda estação:

```python
trips["vs_station"] = trips["minutes"] / station_median
trips.loc[trips["vs_station"] > 5, ["start_station", "minutes", "vs_station"]].round(1).head(4)
```

```
     start_station  minutes  vs_station
749            S05     71.1         5.0
1337           S05     72.6         5.1
1523           S05     83.3         5.9
2024           S14     85.4         6.1
```

Viagens mais de cinco vezes a mediana da estação. Uma regra escrita contra a tabela inteira, "mais de
70 minutos", trataria todas as estações igual; uma regra escrita contra o grupo se adapta a cada uma.

## Frações dentro de um grupo

O outro uso comum é uma fração: cada parte sobre o total do seu grupo.

```python
daily = trips.groupby([trips["started_at"].dt.date, "plan"]).size().rename("trips").reset_index()
daily["share_of_day"] = daily["trips"] / daily.groupby("started_at")["trips"].transform("sum")
daily.head(4).round(3)
```

```
   started_at    plan  trips  share_of_day
0  2025-01-01  annual     85         0.802
1  2025-01-01     day     21         0.198
2  2025-01-02  annual     82         0.759
3  2025-01-02     day     26         0.241
```

`daily` tem uma linha por dia e plano. `transform("sum")` põe o total de cada dia nas duas linhas
dele, e dividir dá a fração de cada plano no seu dia. As duas frações de um dia somam 1, qualquer que
seja o tamanho do dia.
