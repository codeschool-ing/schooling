---
title: Cinco minutos antes de qualquer análise
version: 2
---

```python
df.head(3)        # what does a row look like
df.shape          # (8, 5)
df.info()         # types, and how many values are not missing
df.describe()     # ranges, for the numeric columns
df["country"].value_counts()
```

**Rode os cinco antes de escrever qualquer outra coisa.** Levam um minuto e pegam as coisas que de
outro jeito aparecem como um número errado três horas depois.

## O `info()` é o que merece o lugar

```sh
 #   Column    Non-Null Count  Dtype
---  ------    --------------  -----
 0   id        8 non-null      int64
 1   customer  8 non-null      str
 2   country   8 non-null      str
 3   cents     7 non-null      float64
 4   paid_at   7 non-null      str
```

Dois fatos por coluna: **o tipo**, e **quantos valores estão de fato lá**. O `cents` é um float
e tem sete de oito — os dois problemas da seção anterior, visíveis numa linha.

## `describe()`

```sh
            id         cents
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
country
BR    4
PT    2
US    2
```

Para qualquer coluna com um número pequeno de valores distintos. É onde `"BR"`, `"br"` e `" BR"`
aparecem como três países, e onde a categoria que ninguém sabia que existia aparece.

```python
df["country"].value_counts(dropna=False)     # counts the missing ones too
```

O `dropna=False` vale virar hábito: o padrão esconde exatamente as linhas que estão prestes a
surpreender você.

## E mais um

```python
df["id"].is_unique          # True
df.duplicated().sum()       # how many rows are exact copies
```

Duas perguntas baratas de fazer e caras de descobrir a resposta depois.
