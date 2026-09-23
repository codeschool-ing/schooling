---
title: `[start:stop:step]`, and the copy it makes
version: 2
---

```python
>>> letters = ["a", "b", "c", "d", "e"]
>>> letters[1:3]
['b', 'c']
```

**The stop is exclusive.** `[1:3]` is positions 1 and 2. That looks arbitrary until you notice
what it buys: `len(xs[a:b])` is `b - a`, and `xs[:n] + xs[n:]` is the whole thing with no overlap
and no gap.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Five items with the slice boundaries numbered zero to five in the gaps between them, and the item positions numbered zero to four under the items. The slice one to three reaches from the gap before b to the gap after c, which is b and c.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">the numbers a slice uses</text> <rect x=\"134\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"176\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;a&quot;</text> <text x=\"176\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text> <rect x=\"226\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"268\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;b&quot;</text> <text x=\"268\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text> <rect x=\"318\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;c&quot;</text> <text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text> <rect x=\"410\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"452\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;d&quot;</text> <text x=\"452\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text> <rect x=\"502\" y=\"74\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"544\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;e&quot;</text> <text x=\"544\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text> <text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text> <text x=\"222\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1</text> <text x=\"314\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text> <text x=\"406\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">3</text> <text x=\"498\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">4</text> <text x=\"590\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5</text> <text x=\"360\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the positions an index uses</text> <path d=\"M222.0 166 L222.0 176 L406.0 176 L406.0 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"246\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">[1:3]</text> <path d=\"M296 198 L328 198\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"338\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">['b', 'c']</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Because they are gaps, len(xs[a:b]) is b minus a,</text> <text x=\"360\" y=\"233\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and xs[:n] + xs[n:] is the whole thing with no overlap and no hole.</text> </svg>", "caption": "A slice numbers the gaps, not the items — which is the whole of why the stop is exclusive."}
```

## Leaving parts out

```python
>>> letters[:2]     # from the beginning
['a', 'b']
>>> letters[2:]     # to the end
['c', 'd', 'e']
>>> letters[:]      # all of it — and a NEW list
['a', 'b', 'c', 'd', 'e']
```

## The step

```python
>>> letters[::2]
['a', 'c', 'e']
>>> letters[::-1]
['e', 'd', 'c', 'b', 'a']
```

`[::-1]` reverses. It works on strings too — `"ada"[::-1]` is `'ada'`, which is how you check for
a palindrome in one expression.

## A slice never raises

```python
>>> letters[10:20]
[]
```

Where `letters[10]` raises `IndexError`, the slice just gives you what is there. That is
convenient and it is also a place a bug hides: an empty result may mean *nothing matched* or *my
indices were nonsense*, and the slice will not tell you which.

## It is a copy

```python
>>> a = [1, 2, 3]
>>> b = a[:]
>>> b.append(4)
>>> a
[1, 2, 3]
```

`a[:]` is one of the three ways to copy a list — the others are `list(a)` and `a.copy()`, and all
three are **shallow**, which the `copying` section is about.

## Assigning to a slice

```python
>>> a = [1, 2, 3, 4]
>>> a[1:3] = ["x"]
>>> a
[1, 'x', 4]
```

The replacement does not have to be the same length. Rarely what you want, and worth recognising
when you read it.

## On strings

The syntax is identical, because slicing belongs to sequences and a string is one. The difference
is that a string slice is a new string and there is no assigning to it — strings are immutable.
