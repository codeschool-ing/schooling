---
title: merge, duas tabelas por uma chave
version: 1
---

**O `merge` põe duas tabelas lado a lado casando os valores de uma coluna-chave.** Cada linha de uma
tabela é pareada com as linhas da outra cuja chave é igual, e cada par vira uma linha do resultado. É
o `JOIN` do SQL com grafia do pandas, e quase toda análise precisa de um: as viagens sabem o código
de uma estação mas não o nome, e os dias sabem as suas viagens mas não a sua chuva.

O notebook desta aula lê os três arquivos uma vez:

```python
import numpy as np
import pandas as pd

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
stations = pd.read_csv("stations.csv")
weather = pd.read_csv("weather.csv")
```

Viagens por dia, com o dia como coluna, que é o que a aula 13 ensinou:

```python
daily = trips.groupby(trips["started_at"].dt.normalize()).size().rename("trips")
daily = daily.rename_axis("date").reset_index()
daily.head(3)
```

```
        date  trips
0 2025-01-01    106
1 2025-01-02    108
2 2025-01-03    115
```

E o tempo ao lado, unido por `date`:

```python
daily.merge(weather, on="date")
```

```
ValueError: You are trying to merge on datetime64[us] and str columns for key 'date'. If you wish to proceed you should use pd.concat
```

**As chaves precisam ser do mesmo tipo.** `daily["date"]` é datetime, porque veio de `started_at`;
`weather["date"]` é texto, porque nada disse outra coisa ao `read_csv`. Um datetime nunca é igual a
uma string, então o pandas se recusa em vez de devolver uma tabela em que nada casou. A correção é a
que a aula 12 ensinou, no momento da leitura:

```python
weather["date"] = pd.to_datetime(weather["date"], format="%Y-%m-%d")
days = daily.merge(weather, on="date", validate="one_to_one")
days.shape
```

```
(365, 4)
```

```python
days.head(3)
```

```
        date  trips  rain_mm  temp_max
0 2025-01-01    106      0.0      29.9
1 2025-01-02    108      6.8      30.0
2 2025-01-03    115      7.9      30.7
```

Uma linha por dia, 365 delas, com as viagens e o tempo de cada um. `on="date"` dá o nome da chave,
que tem o mesmo nome nas duas tabelas; quando os nomes diferem, `left_on=` e `right_on=` nomeiam cada
lado. `validate="one_to_one"` é uma promessa que o pandas confere: cada data aparece no máximo uma vez
de cada lado. Custa um argumento, e a seção depois da próxima é sobre o dia em que ela falha.

A tabela unida responde a uma pergunta que nenhuma das duas respondia sozinha:

```python
days[["trips", "rain_mm"]].corr().round(2)
```

```
         trips  rain_mm
trips     1.00    -0.56
rain_mm  -0.56     1.00
```

A correlação é negativa: dias mais chuvosos têm menos viagens. O programa que a aula 8 leu de ponta a
ponta corta as viagens de um dia para mais ou menos a metade quando chovem mais de 10 mm, e o merge é
como você enxerga isso.
