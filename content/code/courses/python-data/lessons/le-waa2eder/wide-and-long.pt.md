---
title: Largo e longo, e o pivot entre os dois
version: 1
---

**Os mesmos números podem ser dispostos no formato longo, uma linha por observação, ou no largo, uma
linha por coisa com uma coluna por medida.** Nenhum dos dois é o formato certo em geral. Cada um é o
certo para alguma tarefa, e quase toda remodelagem no pandas é levar uma tabela do formato em que ela
chegou ao formato que o próximo passo quer.

O notebook desta aula prepara as viagens como a aula 13 fez, com o mês também:

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
trips["month"] = trips["started_at"].dt.month
order = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
```

Viagens por mês e plano, no formato que um `groupby` devolve:

```python
long = trips.groupby(["month", "plan"]).size().rename("trips").reset_index()
long.head(4)
```

```
   month    plan  trips
0      1  annual   2016
1      1     day    896
2      2  annual   1902
3      2     day    854
```

Isso é o **longo**: cada linha é uma observação, um mês, um plano e uma contagem, e os nomes das
colunas dizem o que cada valor é. É o formato que `groupby`, `merge` e seaborn querem, porque um
cálculo sobre "todas as contagens" é um cálculo sobre uma coluna.

O `pivot` o deixa **largo**: um valor de `index` por linha, um valor de `columns` por coluna, e
`values` nas células:

```python
wide = long.pivot(index="month", columns="plan", values="trips")
wide.head(3)
```

```
plan   annual  day
month             
1        2016  896
2        1902  854
3        1983  848
```

```python
long.shape, wide.shape
```

```
((24, 3), (12, 2))
```

Os mesmos 24 números, em 24 linhas de três colunas ou em 12 linhas de duas. O largo é o formato que
uma pessoa lê, porque os dois planos de um mês ficam lado a lado, e o formato para fazer contas **entre**
as colunas de uma linha:

```python
(wide["day"] / wide.sum(axis=1)).round(3).head(3)
```

```
month
1    0.308
2    0.310
3    0.300
dtype: float64
```

A fração dos passes diários em cada mês, numa divisão. No formato longo a mesma resposta precisa de
um `groupby` e de um `transform`, que é a fração dentro de um grupo da aula 13.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"As mesmas quatro contagens em dois formatos. Longo: quatro linhas, cada uma com um mês, um plano e um número de viagens. Largo: duas linhas, uma por mês, com uma coluna por plano. pivot vai do longo ao largo; melt volta.\" data-fig=\"shapes\"><defs><marker id=\"shapes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">longo</text><text x=\"570\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">largo</text><rect x=\"20\" y=\"40\" width=\"240\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">month</text><text x=\"140\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">plan</text><text x=\"220\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">trips</text><line x1=\"30\" y1=\"74\" x2=\"250\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"60\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"140\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">annual</text><text x=\"220\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2016</text><text x=\"60\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"140\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">day</text><text x=\"220\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">896</text><text x=\"60\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"140\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">annual</text><text x=\"220\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1902</text><text x=\"60\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"140\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">day</text><text x=\"220\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">854</text><rect x=\"450\" y=\"70\" width=\"240\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">month</text><text x=\"580\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">annual</text><text x=\"655\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">day</text><line x1=\"460\" y1=\"106\" x2=\"680\" y2=\"106\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"500\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2016</text><text x=\"655\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">896</text><text x=\"500\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"580\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1902</text><text x=\"655\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">854</text><line x1=\"280\" y1=\"110\" x2=\"430\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#shapes-ah)\"></line><text x=\"355\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">pivot</text><line x1=\"430\" y1=\"160\" x2=\"280\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#shapes-ah)\"></line><text x=\"355\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">melt</text><text x=\"355\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os mesmos quatro números</text></svg>", "caption": "O longo tem uma linha por observação; o largo tem uma linha por mês e uma coluna por plano."}
```

## Quando o pivot se recusa

O `pivot` só move valores. Ele nunca os combina, então cada par de `index` e `columns` tem que nomear
no máximo uma linha:

```python
trips.pivot(index="month", columns="plan", values="minutes")
```

```
ValueError: Index contains duplicate entries, cannot reshape
```

Cada mês e plano tem milhares de viagens, e o `pivot` não tem onde pôr todos os minutos delas numa
célula só. **O erro quer dizer que a tabela ainda não tem uma linha por célula**: agregue antes, com
`groupby` como o `long` fez, ou deixe o `pivot_table` agregar por você, que é a próxima seção.
