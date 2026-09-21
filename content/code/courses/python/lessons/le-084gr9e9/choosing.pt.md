---
title: Quatro perguntas que resolvem
version: 1
---

| | lista | tupla | dict | conjunto |
|---|---|---|---|---|
| ordenado | sim | sim | por inserção | **não** |
| pode mudar | sim | **não** | sim | sim |
| duplicatas | sim | sim | chaves: não | **não** |
| indexado por | posição | posição | chave | — |
| custo do `in` | **um percurso** | **um percurso** | um passo | um passo |
| serve de chave | não | **sim** | não | não |

## As perguntas, em ordem

**Existe um nome para cada pedaço?** Então um dicionário. `pessoa["cidade"]` diz o que é;
`pessoa[1]` exige que você lembre. Esta é a resposta na maior parte das vezes, e uma lista de
dicionários é no que quase todo arquivo que você ler vai virar.

**Você só precisa saber se algo está lá?** Um conjunto. Sem duplicatas e sem percurso.

**É um grupo fixo de coisas que andam juntas?** Uma tupla — uma coordenada, um valor de retorno, uma
chave.

**Caso contrário uma lista**, que é o padrão honesto: uma coleção ordenada de coisas do mesmo tipo.

## A que custa tempo de verdade

```python
for nome in nomes:            # 100_000 nomes
    if nome in banidos:       # banidos é uma lista de 5_000
        ...
```

São quinhentos milhões de comparações. Troque `banidos` por um conjunto e são cem mil passos, e a
linha de código não muda em mais nada. A aula 20 mede exatamente isso e a resposta é onze segundos
contra quarenta milissegundos.

**A regra prática:** se o `in` está dentro de um laço, a coisa à direita deveria ser um conjunto ou
um dicionário.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Perguntar se um nome está numa lista percorre a lista item por item até achar um ou acabar. Perguntar o mesmo a um conjunto transforma o nome numa posição e olha uma vez só, seja qual for o tamanho.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">nome in banidos — uma lista</text> <rect x=\"20\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"56\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;abe&quot;</text> <rect x=\"100\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"136\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;bo&quot;</text> <path d=\"M91 52 L99 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"180\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"216\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;cy&quot;</text> <path d=\"M171 52 L179 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"260\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"296\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;dee&quot;</text> <path d=\"M251 52 L259 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"340\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"376\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;eve&quot;</text> <path d=\"M331 52 L339 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"420\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"456\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;gil&quot;</text> <path d=\"M411 52 L419 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"500\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"536\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;hal&quot;</text> <path d=\"M491 52 L499 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"580\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"616\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;ada&quot;</text> <path d=\"M571 52 L579 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">uma comparação, depois a próxima, depois a próxima</text> <text x=\"20\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">nome in banidos — um conjunto</text> <rect x=\"20\" y=\"142\" width=\"232\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"136\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">hash(&quot;ada&quot;) -&gt; 4</text> <path d=\"M258 160 L300 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"306\" y=\"142\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"342\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;ada&quot;</text> <text x=\"520\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">transforma o nome numa posição, olha lá, pronto</text> <text x=\"360\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">A aula 20 mede exatamente este par: onze segundos contra quarenta milissegundos.</text> <text x=\"360\" y=\"225\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Quando essa pergunta fica dentro de um laço, o que está à direita cabe num conjunto.</text> </svg>", "caption": "A linha de código é a mesma dos dois jeitos. O trabalho por trás dela não é."}
```

## O que os quatro têm em comum

Os quatro são iteráveis, os quatro têm `len`, os quatro funcionam com `in`, e os quatro podem ser
construídos a partir de outro com `list()`, `tuple()`, `set()` ou `dict()`. Converter entre eles é
barato e muitas vezes é o jeito mais limpo de dizer alguma coisa:

```python
>>> sorted(set(palavras))    # únicas, em ordem
>>> dict(pares)              # uma lista de tuplas de dois numa dicionário
```
