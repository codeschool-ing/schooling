---
title: Cosine similarity
version: 1
---

To score only how two arrows line up, divide the dot product by both lengths:
`cos θ = a · b / (|a| × |b|)`.

The **length** of a vector, written `|a|`, is the square root of its dot product with itself. For
`a = (2, 1, 2)` that is √(4 + 1 + 4) = 3, and `b` happens to have length 3 as well. So the cosine
of the two is 8 / (3 × 3) = 8/9.

```schooling-example
{
  "language": "python",
  "file": "cosine.py",
  "parts": [
    {
      "code": "import numpy as np\n\ndef cosine(x, y):\n    return x @ y / (np.linalg.norm(x) * np.linalg.norm(y))",
      "note": "The formula as a function: the dot product divided by the product of the two lengths. `np.linalg.norm` computes a length."
    },
    {
      "code": "a = np.array([2, 1, 2])\nb = np.array([1, 2, 2])\nprint(np.linalg.norm(a), np.linalg.norm(b))\nprint(round(cosine(a, b), 4))\nprint(round(np.degrees(np.arccos(cosine(a, b))), 1), \"degrees\")",
      "note": "The two lengths, the cosine, and the angle it is the cosine of, converted from radians to degrees."
    },
    {
      "code": "print(round(cosine(2 * a, b), 4))",
      "note": "The cosine with `a` doubled."
    },
    {
      "code": "c = np.array([1, -2, 0])\nprint(cosine(a, c), cosine(a, -a))",
      "note": "A vector perpendicular to `a`, and `a` against its own opposite."
    },
    {
      "code": "D = np.array([a, 2 * a, b, c])\nprint((D @ b / (np.linalg.norm(D, axis=1) * np.linalg.norm(b))).round(4))",
      "note": "The same formula for a matrix: one dot product per row, divided by each row's length and the length of `b`."
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

The result is the cosine of the **angle** θ between the two arrows: 0.8889, an angle of 27.3
degrees. **Doubling `a` changes nothing**: the cosine of `2a` and `b` is 0.8889 again, because the
doubled length is divided out. That is the property the dot product lacked.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Left: two arrows a and b leave the same point 27.3 degrees apart; a third arrow, 2a, runs along a and is twice as long. The dot product of a and b is 8 and of 2a and b is 16, while the cosine is 0.8889 for both. Right: three arrows from one point show the cosine's range: the same direction scores 1, a perpendicular arrow c scores 0.0, and the opposite arrow, minus a, scores -1.0.\"><defs><marker id=\"angen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"angen-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"angen-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><path d=\"M50 270 L284.8 220.1\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#angen-ah0)\" stroke-dasharray=\"6 4\"></path><path d=\"M50 270 L167.4 245.1\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\" marker-end=\"url(#angen-ah0)\"></path><path d=\"M50 270 L142.9 194\" stroke=\"var(--amber)\" stroke-width=\"2.6\" fill=\"none\" marker-end=\"url(#angen-ah1)\"></path><text x=\"171.4\" y=\"261.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">a</text><text x=\"286.8\" y=\"238.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">2a</text><text x=\"140.9\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">b</text><path d=\"M110.6 257.1 A62 62 0 0 0 98.0 230.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"129.3\" y=\"231.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">27.3°</text><circle cx=\"50\" cy=\"270\" r=\"3\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"60\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a · b  = 8</text><text x=\"60\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2a · b = 16</text><text x=\"60\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">cos = 0.8889</text><text x=\"176\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">for both</text><text x=\"200\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">length changes the dot product</text><path d=\"M400 24 L400 306\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M560 190 L670 190\" stroke=\"var(--phosphor)\" stroke-width=\"2.6\" fill=\"none\" marker-end=\"url(#angen-ah0)\"></path><path d=\"M560 190 L560 80\" stroke=\"var(--paper)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#angen-ah2)\"></path><path d=\"M560 190 L450 190\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#angen-ah1)\"></path><circle cx=\"560\" cy=\"190\" r=\"3\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"664\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">a</text><text x=\"574\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c</text><text x=\"460\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">-a</text><text x=\"660\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">same direction</text><text x=\"660\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cos 1</text><text x=\"574\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">perpendicular</text><text x=\"590\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cos 0.0</text><text x=\"456\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">opposite</text><text x=\"456\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cos -1.0</text><text x=\"560\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">direction is all the cosine sees</text></svg>", "caption": "Two arrows always lie in one flat plane, so this angle is the real one, not a projection. Doubling a doubles its dot product with b and leaves the angle, and the cosine, where they were."}
```

The angle in the figure is not an approximation. Any two arrows from the origin lie in one flat
plane, however many dimensions they live in, so the angle between two 384-number vectors is an
ordinary angle you could measure with a protractor. Lesson 1's picture of nineteen points had to
throw information away; a picture of two arrows never does.

## From −1 to 1

A cosine can only take values from −1 to 1, and the line `0.0 -1.0` in the output shows the two
landmarks besides the top one:

- 1 is the same direction, whatever the lengths.
- 0 is perpendicular: `c = (1, −2, 0)` has a dot product with `a` of 2 − 2 + 0 = 0.
- −1 is opposite: `−a` points straight back.

Read that as geometry and not yet as meaning. For text, a cosine near 1 is a near-duplicate, but a
cosine of 0 is not "unrelated" and nothing in practice sits near −1. The section *A crowded space*
measures where real scores fall, and they use a strip of the range much narrower than these three
landmarks suggest.

## In NumPy

The function at the top of `cosine.py` is the formula as written, for two vectors. The last part
does it for a whole matrix at once, one row per document: divide each row's dot product with the
query by that row's length times the query's. Its four rows are `a`, `2a`, `b` and `c` scored
against `b`, and they come out as 0.8889, 0.8889, 1 for `b` itself and −0.4472 for `c`.

When every vector already has length 1, the denominator is 1 × 1 and the line shrinks back to
`D @ q`, which is why lesson 1 could call its scores cosines.
