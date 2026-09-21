---
title: `groupby`, que é `uniq -c` com aritmética
version: 1
---

```python
df.groupby("pais")["centavos"].sum()
```

```sh
pais
BR    23990.0
PT     9000.0
US    38000.0
```

**Divide por uma coluna, aplica uma função a cada grupo, junta os resultados.** É esse o modelo
inteiro, e é o mesmo do `sort | uniq -c` do curso de terminal com a contagem trocada por qualquer
aritmética que você queira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Agrupar separa as linhas pelo valor de uma coluna, aplica uma função a cada grupo, e combina as respostas numa tabela pequena com uma linha por grupo.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">df.groupby(&quot;pais&quot;)[&quot;centavos&quot;].sum()</text> <text x=\"130\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">divide</text> <text x=\"400\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">aplica</text> <text x=\"620\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">junta</text> <rect x=\"20\" y=\"66\" width=\"74\" height=\"68\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"57\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">BR</text> <rect x=\"110\" y=\"66\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12990</text> <rect x=\"110\" y=\"102\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11000</text> <path d=\"M266 82 L320 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"326\" y=\"66\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"401\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sum()</text> <path d=\"M482 82 L536 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"542\" y=\"66\" width=\"158\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"621\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BR  23990.0</text> <rect x=\"20\" y=\"154\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"57\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">PT</text> <rect x=\"110\" y=\"154\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9000</text> <path d=\"M266 170 L320 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"326\" y=\"154\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"401\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sum()</text> <path d=\"M482 170 L536 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"542\" y=\"154\" width=\"158\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"621\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PT  9000.0</text> <rect x=\"20\" y=\"206\" width=\"74\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"57\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">US</text> <rect x=\"110\" y=\"206\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">38000</text> <path d=\"M266 222 L320 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"326\" y=\"206\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"401\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sum()</text> <path d=\"M482 222 L536 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"542\" y=\"206\" width=\"158\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"621\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">US  38000.0</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">é o sort | uniq -c do curso de terminal, com a contagem trocada por aritmética</text> </svg>", "caption": "Divide por uma coluna, aplica uma função a cada grupo, junta os resultados. É esse o modelo inteiro."}
```

## Várias agregações de uma vez

```python
df.groupby("pais").agg(
    pedidos=("id", "count"),
    total=("centavos", "sum"),
    media=("centavos", "mean"),
)
```

```sh
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
