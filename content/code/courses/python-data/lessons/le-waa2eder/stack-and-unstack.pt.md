---
title: stack e unstack, e as células que nunca existiram
version: 1
---

**O `unstack` leva um nível do índice das linhas para as colunas, e o `stack` traz as colunas de
volta para o índice.** São o `pivot` e o `melt` de uma tabela cujas chaves já estão no índice, que é o
que um `groupby` com várias chaves devolve.

As bicicletas perdidas, por estação de partida e mês:

```python
lost = trips[trips["end_station"].isna()]
per = lost.groupby(["start_station", "month"]).size()
len(per)
```

```
107
```

146 bicicletas, mas só 107 linhas: um `groupby` devolve as combinações que **ocorreram**, e a maioria
das estações não perdeu bicicleta na maioria dos meses. Desempilhadas numa grade de 20 estações por
12 meses, as combinações que nunca ocorreram também precisam ser desenhadas:

```python
table = per.unstack("month")
table.iloc[:4, :6]
```

```
month            1    2    3    4    5    6
start_station                              
S01            NaN  NaN  NaN  2.0  NaN  1.0
S02            1.0  NaN  NaN  NaN  1.0  NaN
S03            2.0  1.0  NaN  2.0  1.0  4.0
S04            1.0  NaN  1.0  1.0  NaN  NaN
```

**Toda combinação que não ocorreu é `NaN`**, e as contagens viraram floats para guardá-lo, a regra da
aula 12 de novo. Para uma contagem, combinação ausente quer dizer zero, e o `fill_value` diz isso:

```python
table = per.unstack("month", fill_value=0)
table.iloc[:4, :6]
```

```
month          1  2  3  4  5  6
start_station                  
S01            0  0  0  2  0  1
S02            1  0  0  0  1  0
S03            2  1  0  2  1  4
S04            1  0  1  1  0  0
```

```python
int(table.to_numpy().sum())
```

```
146
```

Ainda 146, agora com um 0 honesto em cada célula vazia. Se uma célula faltante é 0 depende do que se
mede: para uma contagem é; para uma duração mediana de viagem não é, porque nenhuma viagem não é uma
duração de zero.

## De volta

O `stack` transforma a grade de volta numa Series com índice de dois níveis:

```python
table.stack().shape, per.unstack("month").stack().shape
```

```
((240,), (240,))
```

As duas dão 240 linhas, uma por estação e mês, onde o `per` tinha 107. **Depois que a grade desenhou
as células vazias, elas ficam**: como zeros na primeira, e como linhas `NaN` na segunda, porque o
`stack` do pandas 3 mantém os faltantes em vez de descartá-los. Versões anteriores os descartavam por
padrão, e esse é mais um lugar em que um notebook pode dar outra resposta depois de uma atualização.
Um `.dropna()` depois do `stack` devolve as 107 que ocorreram.
