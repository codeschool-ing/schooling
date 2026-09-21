---
title: `NaN`, e a média que pulou os dados caladinha
version: 1
---

```sh
>>> c = df["centavos"]
>>> len(c), c.count(), c.isna().sum()
8, 7, 1
```

```sh
>>> c.mean()
10141.43      ← a soma dividida por 7
>>> c.sum() / len(c)
8873.75       ← a soma dividida por 8
```

**Catorze por cento de diferença, e nada disse nada.** O `mean()` pula valores faltantes e divide
pelo que sobra, que é o padrão certo e não é o que quem lê "valor médio do pedido" supõe.

O `sum()` os trata como zero. O `count()` conta o que está presente. Toda agregação tomou uma
decisão por você, e as decisões não são a mesma.

## `NaN` compara falso com tudo

```sh
>>> np.nan == np.nan
False
>>> (df["centavos"] > 0).sum()
7        ← de 8 linhas
```

Então uma máscara exclui caladamente as linhas faltantes, para qualquer lado que a comparação
aponte. `x != x` é o truque antigo de detectar uma, e `isna()` é o que escrever:

```python
df["centavos"].isna()          # True onde está faltando
df["centavos"].notna()
df["centavos"].isna().sum()    # quantas
```

## `fillna`

```python
df["centavos"].fillna(0)                           # um zero é um zero de verdade
df["pais"].fillna("desconhecido")
df["centavos"].fillna(df["centavos"].mean())       # a média do que está lá
df["leitura"].ffill()                              # carrega o último valor adiante
```

**Cada uma dessas é uma afirmação diferente sobre o mundo.** Um preço faltando preenchido com zero
diz que o pedido foi de graça. Uma leitura de sensor faltando carregada adiante diz que nada
mudou. Nenhuma das duas está errada, e nenhuma é segura de fazer sem dizer por quê.

## `dropna`

```python
df.dropna()                            # qualquer linha com QUALQUER lacuna: 6 de 8 sobrevivem
df.dropna(subset=["centavos"])         # só onde centavos falta: 7 de 8
df.dropna(axis=1)                      # descarta as colunas em vez das linhas
```

A forma pelada é a armadilha. No arquivo daqui ela descartou duas linhas: uma sem `centavos` e uma
sem `pago_em` — e a segunda não tinha nada a ver com a análise.

**Passe sempre o `subset`.**

## A regra

Decida por coluna, antes de agregar, e escreva a decisão:

```python
df["centavos"] = df["centavos"].fillna(0)   # pedidos não pagos contam como zero
df = df.dropna(subset=["pais"])             # uma linha sem país não pode ser agrupada
```

Duas linhas e um comentário cada. A alternativa é um número catorze por cento errado que parece
exatamente com um número certo.
