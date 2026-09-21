---
title: `read_csv`, `dtype`, e a coluna que entrou errada
version: 1
---

```python
import pandas as pd
df = pd.read_csv("pedidos.csv")
```

```text
id,cliente,pais,centavos,pago_em
1,ana,BR,12990,2026-01-04
2,bruno,BR,,2026-01-05          ← uma célula vazia
```

```text
>>> df.dtypes
id            int64
cliente         str
pais            str
centavos    float64      ← não int64
pago_em         str
```

**Um valor faltando transformou a coluna inteira num float.** O `centavos` guarda números inteiros
de centavos e o pandas o leu como `float64`, porque o tipo inteiro clássico não tem como
representar uma lacuna.

Nada avisa sobre isso. Aparece depois, como `12990.0` num relatório ou como um total que não vai
comparar igual a um inteiro.

## `dtype`, na leitura

```python
df = pd.read_csv("pedidos.csv", dtype={"centavos": "Int64"})
```

```text
>>> df["centavos"].tolist()
[12990, <NA>, 4500, 23000, 4500, 7800, 15000, 3200]
```

`Int64` com **I maiúsculo** é o tipo inteiro anulável: números inteiros, com um `<NA>` de verdade
para a lacuna. `int64` em minúsculas é o que não guarda um valor faltando.

Declarar o `dtype` também impede o pandas de adivinhar, o que vale para qualquer coluna cujo tipo
importe — um id só de dígitos vira inteiro e perde os zeros à esquerda de outro jeito.

## Datas

```python
df = pd.read_csv("pedidos.csv", parse_dates=["pago_em"])
```

```text
>>> df["pago_em"].dtype
datetime64[us]
```

Sem isso, uma data é uma string e ordená-la funciona por sorte — datas ISO por acaso ordenam certo
como texto e nenhum outro formato ordena.

## Os argumentos que valem conhecer

```python
pd.read_csv(caminho,
            sep=";",                   # um CSV europeu
            decimal=",",               # e a vírgula decimal dele
            usecols=["id","centavos"], # ler duas colunas de quarenta
            nrows=1000,                # olhar antes de carregar tudo
            na_values=["", "N/A", "-"])
```

O `usecols` e o `nrows` são os dois que transformam um arquivo que não abre num arquivo legível.
Leia mil linhas primeiro, olhe, e aí decida o que carregar.

## E o resto

```python
pd.read_json(caminho)       # registros, ou uma estrutura aninhada
pd.read_excel(caminho)      # precisa do openpyxl
pd.read_parquet(caminho)    # tipado, comprimido, e muito mais rápido
pd.read_sql(consulta, conn)
```

Todos produzem o mesmo DataFrame, e tudo depois desta seção é igual seja qual for o que você usou.
