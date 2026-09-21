---
title: `groupby`, que é `uniq -c` com aritmética
version: 1
---

```python
df.groupby("pais")["centavos"].sum()
```

```text
pais
BR    23990.0
PT     9000.0
US    38000.0
```

**Divide por uma coluna, aplica uma função a cada grupo, junta os resultados.** É esse o modelo
inteiro, e é o mesmo do `sort | uniq -c` do curso de terminal com a contagem trocada por qualquer
aritmética que você queira.

## Várias agregações de uma vez

```python
df.groupby("pais").agg(
    pedidos=("id", "count"),
    total=("centavos", "sum"),
    media=("centavos", "mean"),
)
```

```text
      pedidos    total         media
pais
BR          4  23990.0   7996.666667
PT          2   9000.0   4500.000000
US          2  38000.0  19000.000000
```

A forma com palavra-chave — `nome=("coluna", "função")` — é a de aprender. Ela nomeia as colunas
de saída, coisa que a forma antiga com lista não faz, e se lê como a tabela que produz.

## O `count` conta o que está presente

O `pedidos` acima é o `count` de `id`, que não tem lacunas. Se fosse o `count` de `centavos`, o BR
diria 3 em vez de 4 — porque um dos pedidos dele não tem valor.

**Isso é um recurso.** Um `count` da coluna que você está somando diz de quanto de cada grupo a
soma é de fato feita, e sai de graça.

## Agrupar por mais de uma

```python
df.groupby(["pais", "cliente"])["centavos"].sum()
```

O resultado tem um índice de dois níveis. O `.reset_index()` o achata de volta em colunas comuns,
que é quase sempre o que você quer antes de escrever ou de plotar.

## `transform`, quando a resposta pertence ao lado de cada linha

```python
df["total_do_pais"] = df.groupby("pais")["centavos"].transform("sum")
```

O `agg` dá uma linha por grupo; o `transform` dá uma linha por **linha original**, com a resposta
do grupo repetida. É assim que se calcula "este pedido como fração do país dele" sem um join.

## E o laço que você não está escrevendo

```python
totais = {}
for linha in linhas:
    totais.setdefault(linha["pais"], 0)
    totais[linha["pais"]] += linha["centavos"]
```

Isso é o `defaultdict(int)` da aula 20, e está exatamente certo em Python puro. O `groupby` é a
mesma ideia quando os dados já são uma tabela — e dá `count`, `mean`, `min`, `max` e o resto sem
você escrever nenhum deles.
