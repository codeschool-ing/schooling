---
title: Uma Series é um array com rótulos
version: 1
---

**Uma Series do pandas é um array NumPy com um segundo array ao lado, o índice, que dá nome a cada
elemento.** Todo o resto do pandas se constrói sobre esse par. As aulas de NumPy guardavam as datas
num array e a chuva em outro, e os mantinham em passo com cuidado; uma Series os mantém em passo
por construção.

Desta aula em diante, os notebooks começam com o pandas:

```python
import numpy as np
import pandas as pd

weather = pd.read_csv("weather.csv")
rain = pd.Series(weather["rain_mm"].to_numpy(), index=weather["date"], name="rain_mm")
rain.head()
```

```
date
2025-01-01     0.0
2025-01-02     6.8
2025-01-03     7.9
2025-01-04    15.7
2025-01-05     0.0
Name: rain_mm, dtype: float64
```

A coluna da esquerda é o índice, as datas; a da direita são os valores; a última linha dá o nome e
o dtype. `head()` mostra os cinco primeiros. A Series foi montada à mão aqui, a partir de um array
NumPy e de um índice, para mostrar as duas metades. Lê-la direto de uma tabela é trabalho das
próximas seções.

```python
rain.values[:3], rain.index[:3], rain.dtype, rain.name
```

```
(array([0. , 6.8, 7.9]),
 Index(['2025-01-01', '2025-01-02', '2025-01-03'], dtype='str', name='date'),
 dtype('float64'),
 'rain_mm')
```

`values` é o array NumPy por baixo, do mesmo tipo com que as aulas 4 a 8 trabalharam. `index` é
um objeto próprio, um `Index`. Repare no dtype do índice, `str`: no pandas 3, texto tem um tipo
próprio, que a aula 3 encontrou em dois ambientes e a aula 12 explica.

## Por rótulo, e por posição

Uma Series pode ser consultada pelo rótulo ou pela posição, e são perguntas diferentes, com métodos
diferentes:

```python
rain.loc["2025-03-22"], rain.iloc[80]
```

```
(np.float64(45.9), np.float64(45.9))
```

`loc` procura o rótulo: o dia chamado `2025-03-22`, o mais chuvoso do ano. `iloc` conta posições
a partir de 0, como o NumPy: o 81º elemento, que aqui calha de ser o mesmo dia. A aula 11 trata de
`loc` e `iloc` por inteiro; por enquanto, **diga qual dos dois você quer**, porque colchetes puros
numa Series mudaram de significado entre versões do pandas e não vale a pena adivinhar.

Tudo o que o NumPy faz com os valores continua funcionando, e mantém o índice:

```python
(rain > 40).sum(), rain[rain > 40]
```

```
(np.int64(4),
 date
 2025-03-22    45.9
 2025-06-17    41.0
 2025-07-01    41.4
 2025-09-03    40.9
 Name: rain_mm, dtype: float64)
```

A máscara da aula 7, com as datas presas à resposta, que é o ponto.
