---
title: Four questions that settle it
version: 1
---

| | list | tuple | dict | set |
|---|---|---|---|---|
| ordered | yes | yes | by insertion | **no** |
| can change | yes | **no** | yes | yes |
| duplicates | yes | yes | keys: no | **no** |
| indexed by | position | position | key | — |
| `in` costs | **a walk** | **a walk** | one step | one step |
| can be a dict key | no | **yes** | no | no |

## The questions, in order

**Is there a name for each piece?** Then a dictionary. `person["city"]` says what it is;
`person[1]` needs you to remember. This is the answer most of the time, and a list of dictionaries
is what almost every file you read turns into.

**Do you only need to know whether something is there?** A set. No duplicates and no walk.

**Is it a fixed group of things that belong together?** A tuple — a coordinate, a return value, a
key.

**Otherwise a list**, which is the honest default: an ordered collection of things of the same
kind.

## The one that costs real time

```python
for name in names:            # 100_000 names
    if name in banned:        # banned is a list of 5_000
        ...
```

That is five hundred million comparisons. Change `banned` to a set and it is a hundred thousand
steps, and the line of code does not otherwise change. Lesson 20 measures exactly this and the
answer is eleven seconds against forty milliseconds.

**The rule of thumb:** if `in` is inside a loop, the thing on the right should be a set or a
dictionary.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Asking whether a name is in a list walks the list one item at a time until it finds one or runs out. Asking the same of a set turns the name into a position and looks once, whatever the size.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">name in banned — a list</text> <rect x=\"20\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"56\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;abe&quot;</text> <rect x=\"100\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"136\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;bo&quot;</text> <path d=\"M91 52 L99 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"180\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"216\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;cy&quot;</text> <path d=\"M171 52 L179 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"260\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"296\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;dee&quot;</text> <path d=\"M251 52 L259 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"340\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"376\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;eve&quot;</text> <path d=\"M331 52 L339 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"420\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"456\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;gil&quot;</text> <path d=\"M411 52 L419 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"500\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"536\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;hal&quot;</text> <path d=\"M491 52 L499 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <rect x=\"580\" y=\"34\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"616\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;ada&quot;</text> <path d=\"M571 52 L579 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">one comparison, then the next, then the next</text> <text x=\"20\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">name in banned — a set</text> <rect x=\"20\" y=\"142\" width=\"232\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"136\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">hash(&quot;ada&quot;) -&gt; 4</text> <path d=\"M258 160 L300 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"306\" y=\"142\" width=\"72\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"342\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;ada&quot;</text> <text x=\"520\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">turn the name into a position, look there, done</text> <text x=\"360\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Lesson 20 measures this exact pair: eleven seconds against forty milliseconds.</text> <text x=\"360\" y=\"225\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">When that question sits inside a loop, the thing on the right belongs in a set.</text> </svg>", "caption": "The line of code is the same either way. The work behind it is not."}
```

## What they have in common

All four are iterable, all four have `len`, all four work with `in`, and all four can be built
from another with `list()`, `tuple()`, `set()` or `dict()`. Converting between them is cheap and
is often the neatest way to say something:

```python
>>> sorted(set(words))       # unique, in order
>>> dict(pairs)              # a list of two-item tuples into a dictionary
```
