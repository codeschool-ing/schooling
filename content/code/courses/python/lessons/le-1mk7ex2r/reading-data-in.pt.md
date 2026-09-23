---
title: `read_csv`, `dtype`, e a coluna que entrou errada
version: 2
---

```python
import pandas as pd
df = pd.read_csv("orders.csv")
```

```sh
id,customer,country,cents,paid_at
1,ana,BR,12990,2026-01-04
2,bruno,BR,,2026-01-05          ← one empty cell
```

```sh
>>> df.dtypes
id            int64
customer        str
country         str
cents       float64      ← not int64
paid_at         str
```

**Um valor faltando transformou a coluna inteira num float.** O `cents` guarda números inteiros
de centavos e o pandas o leu como `float64`, porque o tipo inteiro clássico não tem como
representar uma lacuna.

Nada avisa sobre isso. Aparece depois, como `12990.0` num relatório ou como um total que não vai
comparar igual a um inteiro.

## `dtype`, na leitura

```python
df = pd.read_csv("orders.csv", dtype={"cents": "Int64"})
```

```sh
>>> df["cents"].tolist()
[12990, <NA>, 4500, 23000, 4500, 7800, 15000, 3200]
```

`Int64` com **I maiúsculo** é o tipo inteiro anulável: números inteiros, com um `<NA>` de verdade
para a lacuna. `int64` em minúsculas é o que não guarda um valor faltando.

Declarar o `dtype` também impede o pandas de adivinhar, o que vale para qualquer coluna cujo tipo
importe — um id só de dígitos vira inteiro e perde os zeros à esquerda de outro jeito.

## Datas

```python
df = pd.read_csv("orders.csv", parse_dates=["paid_at"])
```

```sh
>>> df["paid_at"].dtype
datetime64[us]
```

Sem isso, uma data é uma string e ordená-la funciona por sorte — datas ISO por acaso ordenam certo
como texto e nenhum outro formato ordena.

## Os argumentos que valem conhecer

```python
pd.read_csv(path,
            sep=";",                # a European CSV
            decimal=",",            # and its decimal comma
            usecols=["id","cents"], # read two columns of forty
            nrows=1000,             # look before loading all of it
            na_values=["", "N/A", "-"])
```

O `usecols` e o `nrows` são os dois que transformam um arquivo que não abre num arquivo legível.
Leia mil linhas primeiro, olhe, e aí decida o que carregar.

## E o resto

```python
pd.read_json(path)          # records, or a nested structure
pd.read_excel(path)         # needs openpyxl
pd.read_parquet(path)       # typed, compressed, and much faster
pd.read_sql(query, conn)
```

Todos produzem o mesmo DataFrame, e tudo depois desta seção é igual seja qual for o que você usou.
