---
title: Similaridade de cosseno
version: 1
---

Para dar nota só ao alinhamento de duas setas, divida o produto escalar pelos dois comprimentos:
`cos θ = a · b / (|a| × |b|)`.

O **comprimento** de um vetor, escrito `|a|`, é a raiz quadrada do produto escalar dele com ele
mesmo. Para `a = (2, 1, 2)` isso dá √(4 + 1 + 4) = 3, e `b` por acaso também tem comprimento 3.
Então o cosseno dos dois é 8 / (3 × 3) = 8/9.

```schooling-example
{
  "language": "python",
  "file": "cosine.py",
  "parts": [
    {
      "code": "import numpy as np\n\ndef cosine(x, y):\n    return x @ y / (np.linalg.norm(x) * np.linalg.norm(y))",
      "note": "A fórmula como função: o produto escalar dividido pelo produto dos dois comprimentos. `np.linalg.norm` calcula um comprimento."
    },
    {
      "code": "a = np.array([2, 1, 2])\nb = np.array([1, 2, 2])\nprint(np.linalg.norm(a), np.linalg.norm(b))\nprint(round(cosine(a, b), 4))\nprint(round(np.degrees(np.arccos(cosine(a, b))), 1), \"degrees\")",
      "note": "Os dois comprimentos, o cosseno e o ângulo do qual ele é o cosseno, convertido de radianos para graus."
    },
    {
      "code": "print(round(cosine(2 * a, b), 4))",
      "note": "O cosseno com `a` dobrado."
    },
    {
      "code": "c = np.array([1, -2, 0])\nprint(cosine(a, c), cosine(a, -a))",
      "note": "Um vetor perpendicular a `a`, e `a` contra o seu oposto."
    },
    {
      "code": "D = np.array([a, 2 * a, b, c])\nprint((D @ b / (np.linalg.norm(D, axis=1) * np.linalg.norm(b))).round(4))",
      "note": "A mesma fórmula para uma matriz: um produto escalar por linha, dividido pelo comprimento de cada linha e pelo comprimento de `b`."
    }
  ]
}
```

```
ana@lab:~/emb$ python cosine.py
3.0 3.0
0.8889
27.3 degrees
0.8889
0.0 -1.0
[ 0.8889  0.8889  1.     -0.4472]
```

O resultado é o cosseno do **ângulo** θ entre as duas setas: 0,8889, um ângulo de 27,3 graus.
**Dobrar `a` não muda nada**: o cosseno de `2a` e `b` é 0,8889 de novo, porque o comprimento
dobrado é dividido. Essa é a propriedade que faltava ao produto escalar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"À esquerda: duas setas, a e b, saem do mesmo ponto separadas por 27,3 graus; uma terceira seta, 2a, vai na direção de a com o dobro do comprimento. O produto escalar de a e b é 8 e o de 2a e b é 16, enquanto o cosseno é 0,8889 nos dois casos. À direita: três setas saindo de um ponto mostram a faixa do cosseno: a mesma direção dá 1, uma seta perpendicular c dá 0,0 e a seta oposta, menos a, dá -1,0.\"><defs><marker id=\"angpt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"angpt-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"angpt-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><path d=\"M50 270 L284.8 220.1\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#angpt-ah0)\" stroke-dasharray=\"6 4\"></path><path d=\"M50 270 L167.4 245.1\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\" marker-end=\"url(#angpt-ah0)\"></path><path d=\"M50 270 L142.9 194\" stroke=\"var(--amber)\" stroke-width=\"2.6\" fill=\"none\" marker-end=\"url(#angpt-ah1)\"></path><text x=\"171.4\" y=\"261.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">a</text><text x=\"286.8\" y=\"238.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">2a</text><text x=\"140.9\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">b</text><path d=\"M110.6 257.1 A62 62 0 0 0 98.0 230.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"129.3\" y=\"231.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">27.3°</text><circle cx=\"50\" cy=\"270\" r=\"3\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"60\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a · b  = 8</text><text x=\"60\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2a · b = 16</text><text x=\"60\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">cos = 0.8889</text><text x=\"176\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">nos dois</text><text x=\"200\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o comprimento muda o produto escalar</text><path d=\"M400 24 L400 306\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M560 190 L670 190\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\" marker-end=\"url(#angpt-ah0)\"></path><path d=\"M560 190 L560 80\" stroke=\"var(--paper)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#angpt-ah2)\"></path><path d=\"M560 190 L450 190\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#angpt-ah1)\"></path><circle cx=\"560\" cy=\"190\" r=\"3\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"664\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">a</text><text x=\"574\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c</text><text x=\"460\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">-a</text><text x=\"660\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">mesma direção</text><text x=\"660\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cos 1</text><text x=\"574\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">perpendicular</text><text x=\"590\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cos 0.0</text><text x=\"456\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">oposta</text><text x=\"456\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cos -1.0</text><text x=\"560\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o cosseno só enxerga a direção</text></svg>", "caption": "Duas setas sempre ficam num mesmo plano, então este ângulo é o verdadeiro, e não uma projeção. Dobrar a dobra o produto escalar com b e deixa o ângulo, e o cosseno, onde estavam.", "same": ["perpendicular"]}
```

O ângulo da figura não é uma aproximação. Duas setas quaisquer saindo da origem ficam num mesmo
plano, em quantas dimensões elas estiverem, então o ângulo entre dois vetores de 384 números é um
ângulo comum, que daria para medir com um transferidor. A figura de dezenove pontos da aula 1
precisou jogar informação fora; uma figura de duas setas nunca precisa.

## De −1 a 1

Um cosseno só pode valer de −1 a 1, e a linha `0.0 -1.0` da saída mostra os dois marcos além do de
cima:

- **1**: a mesma direção, sejam quais forem os comprimentos.
- **0**: perpendicular. `c = (1, −2, 0)` tem produto escalar com `a` de 2 − 2 + 0 = 0.
- **−1**: oposta. `−a` aponta exatamente para trás.

Leia isso como geometria, e ainda não como significado. Em texto, um cosseno perto de 1 é um quase
duplicado, mas um cosseno 0 não quer dizer "sem relação", e na prática nada fica perto de −1. A
seção *Um espaço apertado* mede onde as notas reais caem, e elas ocupam uma faixa da escala muito
mais estreita do que esses três marcos sugerem.

## No NumPy

A função no começo de `cosine.py` é a fórmula como está escrita, para dois vetores. A última parte
faz isso para uma matriz inteira de uma vez, uma linha por documento: divida o produto escalar de
cada linha com a consulta pelo comprimento da linha vezes o da consulta. As quatro linhas são `a`,
`2a`, `b` e `c` contra `b`, e saem 0,8889, 0,8889, 1 para o próprio `b` e −0,4472 para `c`.

Quando todo vetor já tem comprimento 1, o denominador é 1 × 1 e a linha volta a ser `D @ q`, e é
por isso que a aula 1 pôde chamar as notas dela de cossenos.
