---
title: `[start:stop:step]`, e a cópia que ele faz
version: 2
---

```python
>>> letters = ["a", "b", "c", "d", "e"]
>>> letters[1:3]
['b', 'c']
```

**O fim é exclusivo.** `[1:3]` são as posições 1 e 2. Isso parece arbitrário até você reparar no que
compra: `len(xs[a:b])` é `b - a`, e `xs[:n] + xs[n:]` é a coisa inteira sem sobreposição e sem buraco.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Cinco itens com as fronteiras de fatia numeradas de zero a cinco nos vãos entre eles, e as posições dos itens numeradas de zero a quatro embaixo. A fatia de um a três vai do vão antes do b até o vão depois do c, que são b e c.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">os números que a fatia usa</text> <rect x=\"134\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"176\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;a&quot;</text> <text x=\"176\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text> <rect x=\"226\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"268\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;b&quot;</text> <text x=\"268\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text> <rect x=\"318\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;c&quot;</text> <text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text> <rect x=\"410\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"452\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;d&quot;</text> <text x=\"452\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text> <rect x=\"502\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"544\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;e&quot;</text> <text x=\"544\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text> <text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text> <text x=\"222\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1</text> <text x=\"314\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text> <text x=\"406\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">3</text> <text x=\"498\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">4</text> <text x=\"590\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5</text> <text x=\"360\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">as posições que o índice usa</text> <path d=\"M222.0 166 L222.0 176 L406.0 176 L406.0 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"246\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">[1:3]</text> <path d=\"M296 198 L328 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"338\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">['b', 'c']</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Por serem vãos, len(xs[a:b]) é b menos a,</text> <text x=\"360\" y=\"233\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e xs[:n] + xs[n:] é a coisa inteira sem sobreposição e sem buraco.</text> </svg>", "caption": "Uma fatia numera os vãos, não os itens — e é essa a razão inteira de o fim ser exclusivo."}
```

## Deixando partes de fora

```python
>>> letters[:2]     # from the beginning
['a', 'b']
>>> letters[2:]     # to the end
['c', 'd', 'e']
>>> letters[:]      # all of it — and a NEW list
['a', 'b', 'c', 'd', 'e']
```

## O passo

```python
>>> letters[::2]
['a', 'c', 'e']
>>> letters[::-1]
['e', 'd', 'c', 'b', 'a']
```

`[::-1]` inverte. Funciona em strings também — `"ada"[::-1]` é `'ada'`, que é como se testa um
palíndromo numa expressão.

## Uma fatia nunca levanta erro

```python
>>> letters[10:20]
[]
```

Onde `letters[10]` levanta `IndexError`, a fatia simplesmente te dá o que existe. É conveniente e é
também um lugar onde um defeito se esconde: um resultado vazio pode significar *nada casou* ou *meus
índices eram absurdos*, e a fatia não vai dizer qual.

## Ela é uma cópia

```python
>>> a = [1, 2, 3]
>>> b = a[:]
>>> b.append(4)
>>> a
[1, 2, 3]
```

`a[:]` é um dos três jeitos de copiar uma lista — os outros são `list(a)` e `a.copy()`, e os três são
**rasos**, que é do que a seção `copying` trata.

## Atribuindo a uma fatia

```python
>>> a = [1, 2, 3, 4]
>>> a[1:3] = ["x"]
>>> a
[1, 'x', 4]
```

A substituição não precisa ter o mesmo comprimento. Raramente é o que se quer, e vale reconhecer ao
ler.

## Em strings

A sintaxe é idêntica, porque fatiar pertence a sequências e uma string é uma. A diferença é que uma
fatia de string é uma string nova e não se atribui a ela — strings são imutáveis.
