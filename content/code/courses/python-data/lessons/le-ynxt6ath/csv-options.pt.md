---
title: Um CSV é texto, e o read_csv adivinha
version: 1
---

**Um arquivo CSV não carrega tipos: todo valor nele é texto, e o `read_csv` decide o que cada coluna
é olhando para ela.** Na maioria das vezes adivinha bem. As opções do `read_csv` existem para as
vezes em que não adivinha, e para ler menos que o arquivo inteiro.

O notebook desta aula lê, escreve e lê de volta, em `pydata`:

```python
import os
import sqlite3

import pandas as pd

trips = pd.read_csv("trips.csv")
trips.dtypes.value_counts()
```

```
str      6
int64    1
Name: count, dtype: int64
```

Uma coluna inteira e seis de texto, como a aula 9 encontrou. O palpite é feito por coluna a partir de
todos os valores dela: uma coluna de inteiros é `int64`, uma com ponto decimal ou campo vazio é
`float64`, e qualquer outra coisa é `str`.

## Lendo menos

```python
small = pd.read_csv("trips.csv", usecols=["trip_id", "plan", "bike"], nrows=1000)
small.shape, small.columns.tolist()
```

```
((1000, 3), ['trip_id', 'plan', 'bike'])
```

`usecols` lê só as colunas nomeadas e `nrows` para depois de tantas linhas. Num arquivo de poucos
megabytes não faz diferença; num de poucos gigabytes é a diferença entre carregar e não carregar, e a
aula 20 volta a isso.

## Dizendo quais são os tipos

```python
typed = pd.read_csv("trips.csv", dtype={"trip_id": "int32"}, parse_dates=["started_at", "ended_at"])
typed.dtypes
```

```
trip_id                   int32
started_at       datetime64[us]
ended_at         datetime64[us]
start_station               str
end_station                 str
plan                        str
bike                        str
dtype: object
```

`dtype` fixa o tipo de uma coluna em vez de deixar o `read_csv` escolher: aqui um inteiro menor.
`parse_dates` transforma colunas de texto em **datetimes**, o tipo de que a aula 12 trata. O
`ended_at` vazio das bicicletas que nunca voltaram virou `NaT`, "not a time", que é o `NaN` de um
datetime:

```python
gone = typed["ended_at"].isna()
gone.sum(), typed.loc[gone, "ended_at"].iloc[0]
```

```
(np.int64(146), NaT)
```

## O que conta como faltante

O `read_csv` lê como faltante um campo vazio, `NA`, `NaN`, `null` e uma dúzia de grafias
parecidas. Um arquivo que marca o faltante de outro jeito tem de dizer:

```python
with open("readings.csv", "w") as f:
    f.write("station,docks\nS01,14\nS02,-\nS03,12\n")
pd.read_csv("readings.csv").dtypes["docks"], pd.read_csv("readings.csv", na_values=["-"])["docks"].tolist()
```

```
(<StringDtype(na_value=nan)>, [14.0, nan, 12.0])
```

Com o traço não reconhecido, a coluna inteira foi lida como texto, porque `-` não é número; avisado
de que `-` quer dizer faltante, o `read_csv` lê números e um `NaN`. **Uma coluna numérica que volta
como `str` quase sempre tem um marcador assim em algum lugar**, e o `value_counts` dessa coluna o
encontra.
