---
title: Colunas, `loc`, `iloc`, e a máscara booleana
version: 2
---

```python
df["cents"]                 # one column → a Series
df[["customer", "cents"]]   # two columns → a DataFrame
```

Os colchetes duplos são uma lista de nomes de coluna, não uma sintaxe especial. Passar um nome dá
um Series; passar uma lista dá uma tabela.

## A máscara, que é a ideia

```python
df["cents"] > 10000
```

```sh
0     True
1    False
2    False
3     True
...
Name: cents, dtype: bool
```

Comparar uma coluna dá **outra coluna, de booleanos**. Indexar um DataFrame com uma delas fica com
as linhas em que ela é `True`:

```python
df[df["cents"] > 10000]
```

É esse o mecanismo inteiro, e todo o resto são combinações dele:

```python
df[(df["country"] == "BR") & (df["cents"] > 5000)]
df[df["country"].isin(["BR", "PT"])]
df[~df["cents"].isna()]
```

**`&`, `|` e `~`, não `and`, `or` e `not`** — as palavras-chave do Python trabalham sobre um valor
de verdade e estas trabalham elemento a elemento. E os parênteses são obrigatórios, porque o `&`
liga mais forte que o `>`.

## `loc` e `iloc`

```python
df.loc[0, "customer"]                      # by label
df.iloc[0, 1]                              # by position
df.loc[df["country"] == "BR", "cents"]     # a mask and a column
df.iloc[0:2, 1:3]                          # two rows, two columns, by position
```

O `loc` recebe **rótulos**: valores de índice e nomes de coluna. O `iloc` recebe **posições**:
inteiros, como numa lista.

## Por que os dois não são a mesma coisa

```python
us = df[df["country"] == "US"]
```

```sh
   id customer country    cents
3   4    diego      US  23000.0
6   7   gisele      US  15000.0
```

```sh
>>> us.iloc[0]["customer"]
'diego'
>>> us.loc[0]
KeyError: 0
```

**As linhas filtradas mantiveram os rótulos originais.** Não existe mais linha 0, então o `loc[0]`
levanta e o `iloc[0]` dá a primeira linha. Esse `KeyError` é a confusão mais comum da biblioteca, e
é isto inteiro.

O `df.reset_index(drop=True)` os renumera quando você quer que os dois concordem.

## Atribuir

```python
df.loc[df["country"] == "BR", "cents"] = 0      # right
df[df["country"] == "BR"]["cents"] = 0          # wrong: a copy
```

O segundo seleciona, recebe uma cópia, e atribui na cópia — então o `df` não muda. Medido no
pandas 3: ele emite um aviso `ChainedAssignmentError` e as quatro linhas BR mantêm os valores que
tinham. **Escreva a atribuição pelo `loc`**, sempre; um aviso é fácil de perder num notebook.
