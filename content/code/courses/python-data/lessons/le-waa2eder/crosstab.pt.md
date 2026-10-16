---
title: crosstab, contagens de duas categorias
version: 1
---

**O `pd.crosstab` conta quantas vezes cada par de valores de duas colunas ocorre, em grade.** É o
jeito mais curto de perguntar se duas categorias andam juntas, e com `normalize` ele responde em
frações.

```python
pd.crosstab(trips["plan"], trips["bike"])
```

```
bike    classic  electric
plan                     
annual    15226      8212
day        6456      3443
```

As mesmas contagens que um `groupby(["plan", "bike"]).size().unstack()` daria, numa chamada que se lê
como a pergunta. As contagens brutas quase só repetem que há mais assinantes que passes diários. A
pergunta é se os dois tipos de ciclista escolhem bicicletas de modo diferente, e isso pede cada linha
em frações:

```python
pd.crosstab(trips["plan"], trips["bike"], normalize="index").round(3)
```

```
bike    classic  electric
plan                     
annual    0.650     0.350
day       0.652     0.348
```

`normalize="index"` divide cada linha pelo seu total, então cada linha soma 1. Os dois planos pegam
uma bicicleta elétrica uns 35% das vezes: **plano e bicicleta são independentes aqui**, que é o que o
gerador fez, escolhendo a bicicleta sem olhar o plano. `normalize="columns"` dividiria pelos totais
das colunas, respondendo "das viagens elétricas, que fração foi de passes diários", e
`normalize=True` divide pelo total geral.

**Para que lado normalizar é a pergunta que você está fazendo.** "Quem tem passe diário prefere
bicicleta elétrica?" compara as linhas, então divide pelos totais das linhas; "quem anda nas
bicicletas elétricas?" compara as colunas. As duas tabelas vêm das mesmas contagens e respondem a
perguntas diferentes.

`margins=True` acrescenta os totais:

```python
pd.crosstab(trips["weekday"], trips["plan"], margins=True).loc[order + ["All"]]
```

```
plan       annual   day    All
weekday                       
Monday       4050  1344   5394
Tuesday      3954  1364   5318
Wednesday    4157  1316   5473
Thursday     3880  1329   5209
Friday       4087  1266   5353
Saturday     1543  1572   3115
Sunday       1767  1708   3475
All         23438  9899  33337
```

A tabela de dia da semana por plano da aula 13, com os totais, e o mesmo sábado e domingo em que os
passes diários superam ou quase igualam os assinantes.
