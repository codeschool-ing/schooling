---
title: Uma tabela como um objeto
version: 1
---

```python
total = 0
for linha in linhas:                    # uma lista de dicts
    if linha["pais"] == "BR":
        total += linha["centavos"]
```

```python
total = df.loc[df["pais"] == "BR", "centavos"].sum()
```

**Um DataFrame é uma tabela sobre a qual você fala como um todo.** Uma coluna é um objeto que você
compara, multiplica, filtra e agrupa, e o resultado de comparar uma é outra coluna — de booleanos
— que é o que a segunda linha está fazendo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Comparar uma coluna inteira produz outra coluna inteira, de booleanos, e é essa coluna que seleciona as linhas. O laço que teria feito isso linha por linha nunca aparece.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"155\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o quadro</text> <text x=\"60\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pais</text> <text x=\"150\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">centavos</text> <text x=\"240\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">taxa</text> <rect x=\"20\" y=\"58\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"62\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BR</text> <rect x=\"110\" y=\"58\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"152\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12990</text> <rect x=\"200\" y=\"58\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"242\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.00</text> <rect x=\"20\" y=\"96\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"62\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">US</text> <rect x=\"110\" y=\"96\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"152\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">38000</text> <rect x=\"200\" y=\"96\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"242\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5.40</text> <rect x=\"20\" y=\"134\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"62\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BR</text> <rect x=\"110\" y=\"134\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"152\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11000</text> <rect x=\"200\" y=\"134\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"242\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1.00</text> <rect x=\"20\" y=\"172\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"62\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PT</text> <rect x=\"110\" y=\"172\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"152\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9000</text> <rect x=\"200\" y=\"172\" width=\"84\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"242\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.20</text> <text x=\"400\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">df[&quot;pais&quot;] == &quot;BR&quot;</text> <rect x=\"330\" y=\"58\" width=\"140\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"400\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">True</text> <rect x=\"330\" y=\"96\" width=\"140\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"400\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">False</text> <rect x=\"330\" y=\"134\" width=\"140\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"400\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">True</text> <rect x=\"330\" y=\"172\" width=\"140\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"400\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">False</text> <path d=\"M296 134 L324 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"600\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">.loc[…, &quot;centavos&quot;].sum()</text> <rect x=\"530\" y=\"58\" width=\"170\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"615\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12990</text> <rect x=\"530\" y=\"96\" width=\"170\" height=\"32\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"615\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">11000</text> <path d=\"M476 134 L524 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"530\" y=\"142\" width=\"170\" height=\"2\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <rect x=\"530\" y=\"152\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"615\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">23990</text> <text x=\"360\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">O laço continua ali — ele roda em C, sobre a coluna inteira, uma vez.</text> <text x=\"360\" y=\"239\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">O que sumiu foi a chamada Python por linha, e é essa a diferença toda.</text> </svg>", "caption": "Uma coluna é um objeto que dá para comparar, multiplicar, filtrar e agrupar — e o resultado de comparar uma é outra coluna."}
```

## O que custa fazer um laço no lugar

```python
df["centavos"] * df["taxa"]                             # vetorizado
df.apply(lambda l: l["centavos"] * l["taxa"], axis=1)   # uma chamada Python por linha
[l["centavos"] * l["taxa"] for _, l in df.iterrows()]   # um Series montado por linha
```

```sh
500.000 linhas
  iterrows   11,200 s
  apply       2,771 s
  vetorizado  0,002 s
```

**Cinco mil vezes**, medido. A operação de coluna roda em código compilado sobre um bloco contíguo
de memória; o `iterrows` monta um objeto `Series` para cada linha antes de você tocá-la.

O `apply(axis=1)` parece o jeito pandas de fazer isso e não é — é uma chamada de função Python por
linha com a construção do objeto ainda lá.

## Os dois tipos

```python
df["centavos"]                # um Series  — uma coluna, com um índice
df[["cliente","centavos"]]    # um DataFrame — duas colunas
```

Um **Series** é uma coluna: valores mais um índice. Um **DataFrame** é um dict de Series
compartilhando um índice. Quase tudo o que você faz devolve um dos dois, e saber qual você tem na
mão explica a maior parte das mensagens de erro.

## O índice

```sh
   id cliente pais    centavos
3   4   diego   US     23000.0
6   7  gisele   US     15000.0
```

Depois de filtrar, as linhas mantêm os rótulos **originais** — 3 e 6, não 0 e 1. O índice não é
uma posição, e essa é a surpresa mais comum do pandas. A seção sobre `loc` e `iloc` é exatamente
sobre isso.

## Quando não usar

Cem linhas lidas uma vez. Um fluxo que você processa e descarta. Qualquer coisa em que a resposta
seja uma passagem só e os dados não caibam numa tabela. O `pandas` custa uma dependência, alguma
memória e uma curva de aprendizado, e abaixo de alguns milhares de linhas uma lista de dicts está
honestamente bem.
