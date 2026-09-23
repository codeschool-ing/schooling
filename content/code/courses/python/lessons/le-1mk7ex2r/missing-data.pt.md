---
title: `NaN`, e a média que pulou os dados caladinha
version: 2
---

```sh
>>> c = df["cents"]
>>> len(c), c.count(), c.isna().sum()
8, 7, 1
```

```sh
>>> c.mean()
10141.43      ← the sum divided by 7
>>> c.sum() / len(c)
8873.75       ← the sum divided by 8
```

**Catorze por cento de diferença, e nada disse nada.** O `mean()` pula valores faltantes e divide
pelo que sobra, que é o padrão certo e não é o que quem lê "valor médio do pedido" supõe.

O `sum()` os trata como zero. O `count()` conta o que está presente. Toda agregação tomou uma
decisão por você, e as decisões não são a mesma.

## `NaN` compara falso com tudo

```sh
>>> np.nan == np.nan
False
>>> (df["cents"] > 0).sum()
7        ← of 8 rows
```

Então uma máscara exclui caladamente as linhas faltantes, para qualquer lado que a comparação
aponte. `x != x` é o truque antigo de detectar uma, e `isna()` é o que escrever:

```python
df["cents"].isna()          # True where it is missing
df["cents"].notna()
df["cents"].isna().sum()    # how many
```

## `fillna`

```python
df["cents"].fillna(0)                        # a zero is a real zero
df["country"].fillna("unknown")
df["cents"].fillna(df["cents"].mean())       # the mean of what is there
df["reading"].ffill()                        # carry the last value forward
```

**Cada uma dessas é uma afirmação diferente sobre o mundo.** Um preço faltando preenchido com zero
diz que o pedido foi de graça. Uma leitura de sensor faltando carregada adiante diz que nada
mudou. Nenhuma das duas está errada, e nenhuma é segura de fazer sem dizer por quê.

## `dropna`

```python
df.dropna()                          # any row with ANY gap: 6 of 8 survive
df.dropna(subset=["cents"])          # only where cents is missing: 7 of 8
df.dropna(axis=1)                    # drop the columns instead
```

A forma pelada é a armadilha. No arquivo daqui ela descartou duas linhas: uma sem `cents` e uma
sem `paid_at` — e a segunda não tinha nada a ver com a análise.

**Passe sempre o `subset`.**

## A regra

Decida por coluna, antes de agregar, e escreva a decisão:

```python
df["cents"] = df["cents"].fillna(0)      # unpaid orders count as zero
df = df.dropna(subset=["country"])       # a row with no country cannot be grouped
```

Duas linhas e um comentário cada. A alternativa é um número catorze por cento errado que parece
exatamente com um número certo.
