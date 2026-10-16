---
title: Uma série no tempo
version: 1
---

**Uma série temporal é uma Series cujo índice é feito de momentos, um valor por momento, em ordem.**
Com um `DatetimeIndex`, o pandas conhece o calendário: fatia por datas escritas como texto, volta um
dia ou uma semana, e conta em janelas de tempo. Esta aula monta uma série e faz a ela as perguntas
que toda série no tempo recebe.

O notebook lê as viagens uma vez:

```python
import numpy as np
import pandas as pd

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
```

Viagens por dia, como uma série indexada por dia:

```python
daily = trips.set_index("started_at").resample("D").size()
daily.head(3)
```

```
started_at
2025-01-01    106
2025-01-02    108
2025-01-03    115
Freq: D, dtype: int64
```

`resample("D")` é um `groupby` no tempo: corta o índice em dias e conta as linhas de cada um. A
última seção desta aula é sobre ele; por enquanto, o que importa é o resultado. O índice tem uma
entrada por dia, e o `Freq: D` embaixo diz que o pandas sabe que as entradas estão a um dia de
distância, todas elas:

```python
len(daily), daily.index.min(), daily.index.max()
```

```
(365, Timestamp('2025-01-01 00:00:00'), Timestamp('2025-12-31 00:00:00'))
```

365 dias, de primeiro de janeiro a 31 de dezembro. Um dia sem viagens continuaria lá, com contagem 0,
porque os dias vêm do calendário e não dos dados. Essa diferença é o assunto da quarta seção.

## Pedindo datas

Com um `DatetimeIndex`, uma data escrita como texto seleciona pelo calendário. O dia mais chuvoso do
ano, 22 de março, e os dias em volta:

```python
daily["2025-03-20":"2025-03-24"]
```

```
started_at
2025-03-20     56
2025-03-21     90
2025-03-22     43
2025-03-23     63
2025-03-24    106
Freq: D, dtype: int64
```

43 viagens no dia em que caíram 45,9 mm de chuva, um sábado, quando um sábado seco tem umas setenta.
As duas pontas da fatia entram, como em toda fatia de `.loc` por rótulo. Uma string mais curta
seleciona tudo o que ela cobre, então `daily["2025-03"]` é março inteiro:

```python
daily["2025-03"].sum(), daily["2025-03"].idxmin()
```

```
(np.int64(2831), Timestamp('2025-03-22 00:00:00'))
```

O dia mais movimentado e o mais calmo do ano saem numa chamada cada:

```python
daily.idxmax(), daily.max(), daily.idxmin(), daily.min()
```

```
(Timestamp('2025-07-09 00:00:00'),
 np.int64(134),
 Timestamp('2025-05-17 00:00:00'),
 np.int64(28))
```

O mais calmo é um sábado de maio com quase 20 mm de chuva, e as duas coisas cortam viagens nestes
dados. Um dia sozinho é ruidoso, porém: um pico ou um vale fala daquele dia, e as perguntas sobre a
**tendência** precisam do resto desta aula.
