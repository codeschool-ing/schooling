---
title: pivot_table, um groupby disposto em grade
version: 1
---

**O `pivot_table` agrupa por duas chaves, agrega, e dispõe a resposta com uma chave na lateral e a
outra no topo.** É `groupby(...).agg(...).unstack()` numa chamada só, com argumentos para o que um
relatório precisa: o que fazer com células vazias, e totais.

Viagens por dia da semana e hora do dia:

```python
grid = trips.pivot_table(index="weekday", columns="hour", values="trip_id",
                         aggfunc="count", fill_value=0)
grid.shape
```

```
(7, 24)
```

Sete linhas, vinte e quatro colunas: cada hora de cada dia da semana. `aggfunc="count"` conta os
`trip_id` não faltantes de cada célula, que é o número de viagens, e `fill_value=0` escreve 0 em
qualquer célula a que nenhuma viagem chegou, em vez de `NaN`. Algumas horas, na ordem da semana:

```python
grid.loc[order, [7, 8, 12, 17, 18]]
```

```
hour        7    8    12   17   18
weekday                           
Monday     606  426  268  566  419
Tuesday    623  422  260  521  444
Wednesday  634  423  262  591  389
Thursday   601  477  252  565  385
Friday     597  440  258  585  389
Saturday   143  205  227  183  181
Sunday     192  210  251  196  200
```

A semana tem dois formatos. De segunda a sexta as horas mais movimentadas são 7 e 17, a ida ao
trabalho e a volta; no sábado e no domingo o pico da manhã some e as horas ficam planas. O `idxmax`
nomeia a hora mais movimentada de cada linha:

```python
grid.loc[order].idxmax(axis=1)
```

```
weekday
Monday        7
Tuesday       7
Wednesday     7
Thursday      7
Friday        7
Saturday     16
Sunday        9
dtype: int32
```

## Qualquer agregação, e os totais

O `aggfunc` aceita os nomes que o `groupby` aceita. A viagem mediana por plano e bicicleta, com
`margins=True` acrescentando uma linha e uma coluna de totais:

```python
trips.pivot_table(index="plan", columns="bike", values="minutes",
                  aggfunc="median", margins=True).round(1)
```

```
bike    classic  electric   All
plan                           
annual     13.4      10.8  12.4
day        21.4      17.2  19.9
All        15.3      12.3  14.2
```

Bicicletas elétricas fazem viagens mais curtas nos dois planos, e passes diários fazem viagens mais
longas nas duas bicicletas. **A linha e a coluna `All` são a mediana de todas as viagens daquela linha
ou coluna, não a mediana das células**: 14.2 é a mediana de todas as viagens, enquanto a mediana das
quatro células é 15.3. Para uma soma as duas coisas coincidem; para uma mediana, ou uma média de
grupos de tamanhos diferentes, não, e ler `All` como resumo das células é um erro que vale não cometer.
