---
title: `[f(x) for x in xs if p(x)]`
version: 2
---

```python
discounted = [price * 0.9 for price in prices if price > 100]
```

Six lines of loop in one, and the first thing it says is **what is being built**.

## Reading it

The order it is written in is not the order it runs in:

```localised
[  price * 0.9        for price in prices       if price > 100  ]
   what to keep       where it comes from       which ones
```

Execution goes right to left: take each price, test it, and if it passes, evaluate the expression.
Reading goes left to right, which is what makes it readable.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 282\" role=\"img\" aria-label=\"The loop and the comprehension are the same three parts in a different order. The expression that is kept is the last line of the loop and the first thing in the comprehension; the source and the test follow it.\"> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">the loop</text> <text x=\"52\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" xml:space=\"preserve\">discounted = []</text> <text x=\"52\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" xml:space=\"preserve\">for price in prices:</text> <text x=\"52\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" xml:space=\"preserve\">    if price &gt; 100:</text> <text x=\"52\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" xml:space=\"preserve\">        discounted.append(price * 0.9)</text> <circle cx=\"32\" cy=\"68\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></circle> <text x=\"32\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text> <circle cx=\"32\" cy=\"92\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></circle> <text x=\"32\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text> <circle cx=\"32\" cy=\"116\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"32\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text> <text x=\"20\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">the comprehension</text> <text x=\"52\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">[</text> <text x=\"61\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" xml:space=\"preserve\">price * 0.9</text> <text x=\"160\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\" xml:space=\"preserve\"> for price in prices</text> <text x=\"340\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\" xml:space=\"preserve\"> if price &gt; 100</text> <text x=\"475\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">]</text> <circle cx=\"110.5\" cy=\"174\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"110.5\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text> <text x=\"110.5\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">what to keep</text> <circle cx=\"250\" cy=\"174\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></circle> <text x=\"250\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text> <text x=\"250\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">where it comes from</text> <circle cx=\"407.5\" cy=\"174\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></circle> <text x=\"407.5\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text> <text x=\"407.5\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">which ones</text> <text x=\"360\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Reading goes left to right. Execution goes the other way:</text> <text x=\"360\" y=\"265\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">take each price, test it, and only then work the expression out.</text> </svg>", "caption": "The comprehension says what is being built before it says where it comes from. That reordering is the whole of what it buys."}
```

## The shapes

```python
[x * 2 for x in xs]                  # map
[x for x in xs if x > 0]             # filter
[x * 2 for x in xs if x > 0]         # both
[y for row in grid for y in row]     # flatten — the loops in the order you would write them
```

**The nested one is the only one that surprises.** The `for` clauses read left to right exactly
as nested `for` statements, which is the opposite of what most people guess.

## When it stops being clearer

```python
# three conditions and a conditional expression — this is a loop
[transform(x) if ok(x) else fallback(x) for x in xs if a(x) and b(x)]
```

Two rules that hold up:

**If it does not fit on one line, it is a loop.** Not "wrap it" — the wrapping is the signal.

**If you want to do anything but build a value, it is a loop.** A comprehension cannot log,
cannot `break`, cannot assign to anything outside itself. That is a feature — it is why you can
trust what one does at a glance — and it is also the boundary.

## What it is not for

```python
[print(x) for x in xs]      # no
```

This builds a list of `None`s and throws it away, for the side effect. Write the loop; it is the
same length and it says what it means.
