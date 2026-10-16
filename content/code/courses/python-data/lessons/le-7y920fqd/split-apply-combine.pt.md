---
title: Dividir, aplicar, combinar
version: 1
---

**O `groupby` divide uma tabela em grupos pelos valores de uma coluna, aplica um cálculo a cada
grupo e combina as respostas num único resultado.** É a operação mais usada do pandas, porque quase
toda pergunta sobre dados é "este número, por aquilo": viagens por estação, minutos por plano, chuva
por mês.

O notebook desta aula prepara as viagens uma vez, com os tipos que a aula 12 lhes deu:

```python
import numpy as np
import pandas as pd

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
trips["ended_at"] = pd.to_datetime(trips["ended_at"], format=fmt)
trips["minutes"] = (trips["ended_at"] - trips["started_at"]).dt.total_seconds() / 60
trips["hour"] = trips["started_at"].dt.hour
trips["weekday"] = trips["started_at"].dt.day_name()
```

A duração média da viagem em cada plano, numa linha:

```python
trips.groupby("plan")["minutes"].mean().round(1)
```

```
plan
annual    14.1
day       22.6
Name: minutes, dtype: float64
```

Leia a linha na ordem em que ela funciona. **Dividir**: `groupby("plan")` separa as 33.337 linhas em
dois grupos, pelo valor de `plan`. **Aplicar**: `["minutes"].mean()` pega a coluna `minutes` de cada
grupo e calcula a média. **Combinar**: as duas médias voltam como uma Series indexada pelos valores
dos grupos. Os passes diários rodam mais tempo, que é o que o gerador da aula 8 os fez fazer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dividir: a tabela de viagens é separada em dois grupos por plano, annual e day. Aplicar: a média de minutes é calculada em cada grupo, 14.1 e 22.6. Combinar: as duas médias formam uma Series indexada por plano.\" data-fig=\"sac\"><defs><marker id=\"sac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"85\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dividir</text><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">aplicar</text><text x=\"620\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">combinar</text><rect x=\"20\" y=\"40\" width=\"130\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">trips</text><text x=\"85.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">33.337 linhas</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">plan == annual</text><text x=\"360.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">23.438 linhas</text><rect x=\"260\" y=\"150\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">plan == day</text><text x=\"360.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">9.899 linhas</text><line x1=\"154\" y1=\"110\" x2=\"256\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sac-ah)\"></line><line x1=\"154\" y1=\"160\" x2=\"256\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sac-ah)\"></line><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">média de minutes</text><rect x=\"540\" y=\"70\" width=\"160\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">annual</text><text x=\"660\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">14.1</text><text x=\"580\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">day</text><text x=\"660\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">22.6</text><line x1=\"464\" y1=\"80\" x2=\"536\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sac-ah)\"></line><line x1=\"464\" y1=\"190\" x2=\"536\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#sac-ah)\"></line></svg>", "caption": "trips.groupby(\"plan\")[\"minutes\"].mean(): dividir por plano, uma média por grupo, uma Series."}
```

## O objeto de grupos

O `groupby` sozinho não calcula nada. Ele devolve um objeto que sabe como as linhas estão divididas e
espera o cálculo:

```python
by_plan = trips.groupby("plan")
by_plan.ngroups, by_plan.size()
```

```
(2,
 plan
 annual    23438
 day        9899
 dtype: int64)
```

`size()` conta as linhas de cada grupo, inclusive as com valores faltantes; `count()` conta os
valores não faltantes de cada coluna em cada grupo, um número diferente onde quer que uma coluna tenha
buracos:

```python
by_plan[["minutes", "end_station"]].count()
```

```
        minutes  end_station
plan                        
annual    23333        23333
day        9858         9858
```

As bicicletas perdidas não têm `minutes` nem `end_station`, então o `count` é menor que o `size`
nos dois planos. **Use `size` para contar linhas, e `count` para contar valores.**
