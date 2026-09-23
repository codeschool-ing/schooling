---
title: Atribuição é um segundo nome, e `copy` é rasa
version: 2
---

Esta é a seção para a qual a aula existe.

```python
>>> a = [1, 2, 3]
>>> b = a
>>> b.append(4)
>>> a
[1, 2, 3, 4]
```

**`b = a` não copiou nada.** Uma lista, dois nomes. Isso vale para todo valor mutável — listas,
dicionários, conjuntos, e os objetos que você escrever na aula 6.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Uma cópia rasa cria uma lista externa nova cujos itens continuam apontando para as mesmas listas internas, então mudar uma interna aparece pelos dois nomes. Uma cópia profunda cria também listas internas novas, e as duas deixam de estar ligadas.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"173\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">b = a[:] — uma cópia rasa</text> <text x=\"547\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">b = deepcopy(a) — uma cópia profunda</text> <rect x=\"20\" y=\"54\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"43\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">a</text> <rect x=\"20\" y=\"138\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"43\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">b</text> <rect x=\"86\" y=\"54\" width=\"112\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"142\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[ . , . ]</text> <rect x=\"86\" y=\"138\" width=\"112\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"142\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[ . , . ]</text> <path d=\"M70 71 L82 71\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M70 155 L82 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"218\" y=\"96\" width=\"108\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"272\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[1, 2]</text> <path d=\"M202 78 L214 106\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M202 148 L214 120\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"394\" y=\"54\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"417\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">a</text> <rect x=\"394\" y=\"138\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"417\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">b</text> <rect x=\"460\" y=\"54\" width=\"112\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"516\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[ . , . ]</text> <rect x=\"460\" y=\"138\" width=\"112\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"516\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[ . , . ]</text> <path d=\"M444 71 L456 71\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M444 155 L456 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"592\" y=\"54\" width=\"108\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"646\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[1, 2]</text> <rect x=\"592\" y=\"138\" width=\"108\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"646\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">[1, 2]</text> <path d=\"M576 71 L588 71\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M576 155 L588 155\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"173\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a MESMA lista interna</text> <text x=\"547\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">uma lista interna própria</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Mude a[0][0] depois da cópia da esquerda e b[0][0] muda junto.</text> <text x=\"360\" y=\"229\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Depois da cópia da direita não muda, e essa é a única diferença.</text> </svg>", "caption": "Toda cópia comum é rasa: a lista externa é nova e tudo dentro dela é o mesmo objeto."}
```

Não é falha. É como se entrega uma tabela de um milhão de linhas para uma função sem duplicá-la. É
surpresa exatamente uma vez, e depois é ferramenta.

## Três jeitos de copiar uma lista

```python
b = a[:]
b = list(a)
b = a.copy()
```

Os três fazem o mesmo. Para um dicionário, `dict(a)` ou `a.copy()`; para um conjunto, `set(a)`.

## Os três são rasos

```python
>>> a = [[1, 2], [3, 4]]
>>> b = a.copy()
>>> b[0].append(99)
>>> a
[[1, 2, 99], [3, 4]]
```

A lista de fora foi copiada. **As de dentro não** — as duas listas de fora apontam para as mesmas
duas de dentro. Uma cópia rasa tem um nível de profundidade, sempre.

```python
import copy
b = copy.deepcopy(a)
```

O `deepcopy` segue a estrutura inteira. É mais lento, lida com ciclos, e é a resposta certa quando
você precisa mesmo de uma árvore independente.

## Quando não importa

**Números, strings e tuplas não podem ser alterados**, então compartilhar um é invisível. É por isso
que dá para passar uma string de um lado para o outro por um ano sem nunca encontrar isto.

## Como isso morde de fato

```python
def clean(rows):
    for row in rows:
        row["name"] = row["name"].strip()
    return rows
```

Isto parece devolver linhas limpas e deixar as de quem chamou em paz. Não deixa: os dicionários são
de quem chamou, e foram editados. Ou diga isso no nome — `limpar_no_lugar` — ou copie antes:

```python
def clean(rows):
    return [{**row, "name": row["name"].strip()} for row in rows]
```

**Uma função que altera o argumento e também o devolve** é a forma que esconde isso. Faça uma coisa
ou a outra.
