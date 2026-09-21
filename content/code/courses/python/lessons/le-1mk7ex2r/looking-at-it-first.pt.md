---
title: Cinco minutos antes de qualquer análise
version: 1
---

```python
df.head(3)        # como é uma linha
df.shape          # (8, 5)
df.info()         # tipos, e quantos valores não estão faltando
df.describe()     # faixas, para as colunas numéricas
df["pais"].value_counts()
```

**Rode os cinco antes de escrever qualquer outra coisa.** Levam um minuto e pegam as coisas que de
outro jeito aparecem como um número errado três horas depois.

## O `info()` é o que merece o lugar

```sh
 #   Column    Non-Null Count  Dtype
---  ------    --------------  -----
 0   id        8 non-null      int64
 1   cliente   8 non-null      str
 2   pais      8 non-null      str
 3   centavos  7 non-null      float64
 4   pago_em   7 non-null      str
```

Dois fatos por coluna: **o tipo**, e **quantos valores estão de fato lá**. O `centavos` é um float
e tem sete de oito — os dois problemas da seção anterior, visíveis numa linha.

## `describe()`

```sh
            id      centavos
count  8.00000      7.000000
mean   4.50000  10141.428571
min    1.00000   3200.000000
max    8.00000  23000.000000
```

Só colunas numéricas, por padrão. Leia o `count` primeiro: 7 contra 8 é a lacuna de novo. Depois o
`min` e o `max`, que é onde um preço negativo ou uma data em 1970 aparece.

O `df.describe(include="all")` acrescenta as colunas de texto, com `unique` e `top` em vez de
`mean`.

## `value_counts()`

```sh
pais
BR    4
PT    2
US    2
```

Para qualquer coluna com um número pequeno de valores distintos. É onde `"BR"`, `"br"` e `" BR"`
aparecem como três países, e onde a categoria que ninguém sabia que existia aparece.

```python
df["pais"].value_counts(dropna=False)     # conta as faltantes também
```

O `dropna=False` vale virar hábito: o padrão esconde exatamente as linhas que estão prestes a
surpreender você.

## E mais um

```python
df["id"].is_unique          # True
df.duplicated().sum()       # quantas linhas são cópias exatas
```

Duas perguntas baratas de fazer e caras de descobrir a resposta depois.
