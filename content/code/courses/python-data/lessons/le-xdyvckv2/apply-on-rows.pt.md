---
title: apply em linhas, e quanto custa
version: 1
---

**O `DataFrame.apply(f, axis=1)` chama uma função Python uma vez por linha, e cada chamada recebe a
linha como uma Series nova.** Ele se lê do jeito que uma pessoa pensa, uma viagem por vez, e é o jeito
mais lento que o pandas tem de fazer quase qualquer coisa. Esta aula mede quanto, e mostra o que
escrever no lugar.

O notebook lê as viagens com os seus horários, e nada mais por enquanto:

```python
import numpy as np
import pandas as pd

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
trips["ended_at"] = pd.to_datetime(trips["ended_at"], format=fmt)
stations = pd.read_csv("stations.csv")
```

A duração de cada viagem, escrita como função de uma linha:

```python
def minutes_of(row):
    return (row["ended_at"] - row["started_at"]).total_seconds() / 60

by_row = trips.apply(minutes_of, axis=1)
by_row.head(3)
```

```
0    34.416667
1    16.866667
2    27.333333
dtype: float64
```

Funciona, e os números estão certos. O mesmo cálculo em colunas inteiras, como a aula 12 o escreveu:

```python
by_column = (trips["ended_at"] - trips["started_at"]).dt.total_seconds() / 60
by_row.equals(by_column)
```

```
True
```

Os mesmos 33.337 valores, com o `NaN` das bicicletas perdidas. Agora o tempo de cada um, com o
`%timeit` como na aula 5:

```python
rows = %timeit -o -q trips.apply(minutes_of, axis=1)
cols = %timeit -o -q (trips["ended_at"] - trips["started_at"]).dt.total_seconds() / 60
round(rows.average * 1000), round(cols.average * 1000, 1), round(rows.average / cols.average)
```

```
(329, 0.7, 479)
```

O primeiro número são os milissegundos da versão por linha, o segundo da versão por colunas, e o
terceiro quantas vezes a versão por linha é mais lenta. Os seus números vão ser outros; a razão deve
continuar na casa das centenas, porque o que a produz é o mesmo em toda máquina. Um terço de segundo
parece nada até a tabela ter três milhões de linhas, ou a célula rodar dentro de um laço, e aí é a
diferença entre um notebook que você roda de novo sem pensar e um que você tem medo de mexer.

## Para onde vai o tempo

A versão por colunas subtrai dois arrays de 33.337 timestamps em código compilado, uma vez. A versão
por linha faz, 33.337 vezes: monta uma Series para a linha, procura dois rótulos nela, subtrai dois
objetos timestamp do Python, chama um método, divide, e devolve a resposta. Cada passo é Python comum,
e o laço em volta deles também. É o laço da aula 5 com um objeto do pandas montado a cada volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois jeitos de calcular durações de viagem. À esquerda, o apply com axis=1 monta uma Series para cada uma das 33.337 linhas e chama uma função Python nela, uma linha por vez. À direita, duas colunas inteiras são subtraídas uma vez, em código compilado.\" data-fig=\"loop\"><defs><marker id=\"loop-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">apply(minutes_of, axis=1)</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">ended_at - started_at</text><rect x=\"20\" y=\"50\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">linha 0</text><line x1=\"134\" y1=\"66\" x2=\"196\" y2=\"66\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#loop-ah)\"></line><rect x=\"200\" y=\"50\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">minutes_of(row)</text><rect x=\"20\" y=\"92\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">linha 1</text><line x1=\"134\" y1=\"108\" x2=\"196\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#loop-ah)\"></line><rect x=\"200\" y=\"92\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">minutes_of(row)</text><rect x=\"20\" y=\"134\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">linha 2</text><line x1=\"134\" y1=\"150\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#loop-ah)\"></line><rect x=\"200\" y=\"134\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">minutes_of(row)</text><text x=\"75\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">… 33.337 vezes</text><text x=\"180\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma Series montada, e uma chamada Python, por linha</text><line x1=\"380\" y1=\"40\" x2=\"380\" y2=\"230\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"420\" y=\"60\" width=\"100\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ended_at</text><text x=\"470.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">33.337</text><rect x=\"560\" y=\"60\" width=\"100\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">started_at</text><text x=\"610.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">33.337</text><text x=\"540\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">−</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma subtração, em código compilado</text></svg>", "caption": "O apply com axis=1 é um laço Python que monta uma linha a cada chamada; uma expressão de colunas é uma chamada só."}
```

**Antes de escrever `apply(..., axis=1)`, pergunte se o cálculo é o mesmo para toda linha.** Se for,
quase sempre dá para escrevê-lo em colunas: aritmética, comparações, `.dt` e `.str`, `np.where`. O
resto desta aula pega um por um os motivos comuns que levam alguém ao `apply`.
