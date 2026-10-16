---
title: O que os colchetes puros fazem, e por que isso não basta
version: 1
---

**Num DataFrame, colchetes puros fazem três coisas diferentes conforme o que se põe neles.** Essa
comodidade é o motivo de todo tutorial começar por eles, e a ambiguidade é o motivo de código
cuidadoso passar para `loc` e `iloc` em tudo além de escolher colunas.

O notebook desta aula:

```python
import pandas as pd

trips = pd.read_csv("trips.csv")
weather = pd.read_csv("weather.csv", index_col="date")
```

```python
trips["plan"].head(2)
```

```
0       day
1    annual
Name: plan, dtype: str
```

**Um nome seleciona uma coluna**, como Series. Uma lista de nomes seleciona várias, como DataFrame.
Agora uma Series booleana:

```python
trips[trips["plan"] == "day"].shape
```

```
(9899, 7)
```

**Uma Series booleana seleciona linhas.** Os mesmos colchetes, o outro eixo. E uma fatia de números:

```python
trips[2:4]
```

```
   trip_id           started_at             ended_at start_station  \
2        3  2025-01-01 03:09:39  2025-01-01 03:36:59           S16   
3        4  2025-01-01 07:17:40  2025-01-01 07:36:13           S14   

  end_station    plan      bike  
2         S03  annual  electric  
3         S05  annual   classic  
```

**Uma fatia seleciona linhas por posição**, numa tabela cujo índice calha de ser 0, 1, 2, então
posição e rótulo coincidem e ninguém percebe qual foi usado. No tempo, indexado por data, os mesmos
colchetes com uma fatia de rótulos selecionam linhas por rótulo:

```python
weather["2025-03-21":"2025-03-23"]
```

```
            rain_mm  temp_max
date                         
2025-03-21     14.3      30.8
2025-03-22     45.9      30.0
2025-03-23      0.0      30.3
```

Três comportamentos, escolhidos pelo tipo do que está dentro. Um código que lê `df[x]` não diz qual
deles quer, e quem lê precisa saber o que é `x` para descobrir. Os dois acessores das próximas
seções fazem uma coisa cada:

| você escreve | seleciona | por |
|---|---|---|
| `df.loc[linhas, colunas]` | linhas e colunas | **rótulos**, ou uma máscara booleana |
| `df.iloc[linhas, colunas]` | linhas e colunas | **posições**, de 0 a n − 1 |

Guarde os colchetes puros para o único caso que ninguém lê errado, uma coluna pelo nome, e use `loc`
ou `iloc` em todo o resto.
