---
title: Vários cálculos de uma vez, com nomes
version: 1
---

**O `agg` aplica vários cálculos a cada grupo numa passada, e a agregação nomeada deixa você dar
nome a cada coluna de resultado.** É como se monta uma tabela-resumo: uma linha por grupo, uma coluna
por estatística, com nomes que um leitor entende.

```python
summary = trips.groupby("start_station").agg(
    trips=("trip_id", "size"),
    median_minutes=("minutes", "median"),
    electric_share=("bike", lambda b: (b == "electric").mean()),
)
summary.sort_values("trips", ascending=False).head(4).round(3)
```

```
               trips  median_minutes  electric_share
start_station                                       
S05             4154          14.117           0.355
S03             2728          14.158           0.341
S07             2636          14.217           0.355
S09             2597          14.267           0.339
```

Cada argumento é `novo_nome=(coluna, função)`. A função pode ser um nome que o pandas conhece,
`"size"`, `"median"`, `"mean"`, `"max"`, `"nunique"`, ou qualquer função que receba uma Series e
devolva um valor, como o `lambda` aqui: a fração das viagens de cada estação feitas numa bicicleta
elétrica. O resultado é um DataFrame comum, indexado por estação, pronto para ordenar.

A estação mais movimentada, `S05`, tem mais ou menos metade a mais de viagens que a seguinte. A
viagem mediana e a fração elétrica dela ficam perto das de todas as outras, o que diz que a estação é
movimentada, não diferente.

## Um nome de função ou uma função

```python
trips.groupby("plan")["minutes"].agg(["mean", "median", "max"]).round(1)
```

```
        mean  median    max
plan                       
annual  14.1    12.4  108.0
day     22.6    19.9  175.1
```

Uma lista de nomes dá uma coluna por função, com o nome dela. Passar os nomes como texto não é só
mais curto que passar `np.mean`: o pandas tem versões rápidas embutidas das mais comuns, e as usa
quando reconhece o nome. Um `lambda` é chamado uma vez por grupo a partir do Python, o que é mais
lento, e a aula 17 é sobre quanto.

## Contar por grupo é contar categorias

```python
trips.groupby("bike").size(), trips["bike"].value_counts()
```

```
(bike
 classic     21682
 electric    11655
 dtype: int64,
 bike
 classic     21682
 electric    11655
 Name: count, dtype: int64)
```

As mesmas contagens. O `value_counts` é o caso especial de uma coluna do `groupby(...).size()`,
ordenado pela contagem em vez do grupo.
