---
title: Olhando uma tabela antes de acreditar nela
version: 1
---

**Três chamadas dizem a maior parte do que uma tabela nova é: `info`, `describe` e
`value_counts`.** Elas respondem, nesta ordem: o que há nela, como são os números e quais são as
categorias. Rode-as em toda tabela que carregar, antes de qualquer análise.

```python
trips.info()
```

```
<class 'pandas.DataFrame'>
RangeIndex: 33337 entries, 0 to 33336
Data columns (total 8 columns):
 #   Column         Non-Null Count  Dtype
---  ------         --------------  -----
 0   trip_id        33337 non-null  int64
 1   started_at     33337 non-null  str  
 2   ended_at       33191 non-null  str  
 3   start_station  33337 non-null  str  
 4   end_station    33191 non-null  str  
 5   plan           33337 non-null  str  
 6   bike           33337 non-null  str  
 7   round_trip     33337 non-null  bool 
dtypes: bool(1), int64(1), str(6)
memory usage: 3.6 MB
```

`info` imprime em vez de devolver, então o texto dele é a saída. Ele lista cada coluna com a sua
contagem de valores **não nulos** e o seu dtype. Duas colunas têm 33.191 valores em vez de 33.337:
`ended_at` e `end_station` faltam em 146 viagens, as bicicletas que a aula 1 disse que nunca
voltaram. A contagem é como você percebe uma coluna com buracos sem procurá-los, e é o primeiro
número a conferir em qualquer tabela.

```python
trips.describe()
```

```
            trip_id
count  33337.000000
mean   16669.000000
std     9623.707298
min        1.000000
25%     8335.000000
50%    16669.000000
75%    25003.000000
max    33337.000000
```

`describe` resume as colunas numéricas: contagem, média, dispersão e quartis. Aqui só há uma coluna
numérica, `trip_id`, e o resumo dela não quer dizer nada: um id é um número que não é uma quantidade.
**O `describe` só é tão bom quanto os dtypes**; com os horários ainda em texto, os números
interessantes ainda não estão lá.

Para colunas de texto a pergunta é quais valores aparecem, e quantas vezes:

```python
trips["plan"].value_counts(), trips["bike"].value_counts(normalize=True).round(3)
```

```
(plan
 annual    23438
 day        9899
 Name: count, dtype: int64,
 bike
 classic     0.65
 electric    0.35
 Name: proportion, dtype: float64)
```

`value_counts` conta cada valor distinto, do mais comum para o menos; `normalize=True` dá frações em
vez de contagens. Sete viagens em dez foram num plano anual, e cerca de uma em três numa bicicleta
elétrica.

```python
trips["start_station"].nunique(), trips["start_station"].value_counts().head(3)
```

```
(20,
 start_station
 S05    4154
 S03    2728
 S07    2636
 Name: count, dtype: int64)
```

Vinte estações, como o `stations.csv` lista, e as três mais movimentadas. Um código de estação aqui
que o `stations.csv` não conhecesse seria o primeiro sinal de um problema para juntar os dois, que é
o assunto da aula 14.
