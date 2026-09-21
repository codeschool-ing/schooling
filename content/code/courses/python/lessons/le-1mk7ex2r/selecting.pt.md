---
title: Colunas, `loc`, `iloc`, e a máscara booleana
version: 1
---

```python
df["centavos"]                # uma coluna → um Series
df[["cliente", "centavos"]]   # duas colunas → um DataFrame
```

Os colchetes duplos são uma lista de nomes de coluna, não uma sintaxe especial. Passar um nome dá
um Series; passar uma lista dá uma tabela.

## A máscara, que é a ideia

```python
df["centavos"] > 10000
```

```sh
0     True
1    False
2    False
3     True
...
Name: centavos, dtype: bool
```

Comparar uma coluna dá **outra coluna, de booleanos**. Indexar um DataFrame com uma delas fica com
as linhas em que ela é `True`:

```python
df[df["centavos"] > 10000]
```

É esse o mecanismo inteiro, e todo o resto são combinações dele:

```python
df[(df["pais"] == "BR") & (df["centavos"] > 5000)]
df[df["pais"].isin(["BR", "PT"])]
df[~df["centavos"].isna()]
```

**`&`, `|` e `~`, não `and`, `or` e `not`** — as palavras-chave do Python trabalham sobre um valor
de verdade e estas trabalham elemento a elemento. E os parênteses são obrigatórios, porque o `&`
liga mais forte que o `>`.

## `loc` e `iloc`

```python
df.loc[0, "cliente"]                       # por rótulo
df.iloc[0, 1]                              # por posição
df.loc[df["pais"] == "BR", "centavos"]     # uma máscara e uma coluna
df.iloc[0:2, 1:3]                          # duas linhas, duas colunas, por posição
```

O `loc` recebe **rótulos**: valores de índice e nomes de coluna. O `iloc` recebe **posições**:
inteiros, como numa lista.

## Por que os dois não são a mesma coisa

```python
us = df[df["pais"] == "US"]
```

```sh
   id cliente pais    centavos
3   4   diego   US     23000.0
6   7  gisele   US     15000.0
```

```sh
>>> us.iloc[0]["cliente"]
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
df.loc[df["pais"] == "BR", "centavos"] = 0      # certo
df[df["pais"] == "BR"]["centavos"] = 0          # errado: uma cópia
```

O segundo seleciona, recebe uma cópia, e atribui na cópia — então o `df` não muda. Medido no
pandas 3: ele emite um aviso `ChainedAssignmentError` e as quatro linhas BR mantêm os valores que
tinham. **Escreva a atribuição pelo `loc`**, sempre; um aviso é fácil de perder num notebook.
