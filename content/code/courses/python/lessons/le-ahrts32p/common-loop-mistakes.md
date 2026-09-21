---
title: The three that do not raise
version: 1
---

Every one of these produces a wrong answer rather than an error, which is what makes them worth a
section.

## Changing a list while iterating it

```python
>>> xs = [1, 2, 4, 3]
>>> for x in xs:
...     if x % 2 == 0:
...         xs.remove(x)
>>> xs
[1, 4, 3]
```

The `4` survived — an even number, in a list that was supposed to have none left. The loop keeps
its own position, not a copy of the list: removing `2` slid `4` back into position 1, which the
loop had already passed, so position 2 held the `3`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"A loop over a list it is also removing from. The loop keeps its own position: removing the two slides the four back into position one, which the loop has already passed, so the four is never tested and an even number survives.\"> <text x=\"102\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the cursor</text> <rect x=\"110\" y=\"34\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"133\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text> <rect x=\"162\" y=\"34\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">2</text> <rect x=\"214\" y=\"34\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"237\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text> <rect x=\"266\" y=\"34\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"289\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text> <rect x=\"110\" y=\"70\" width=\"46\" height=\"3\" rx=\"1\" fill=\"var(--amber)\"></rect> <text x=\"340\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">1 is odd, so it stays</text> <rect x=\"110\" y=\"84\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"133\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text> <rect x=\"162\" y=\"84\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"185\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">2</text> <rect x=\"214\" y=\"84\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"237\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text> <rect x=\"266\" y=\"84\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"289\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text> <rect x=\"162\" y=\"120\" width=\"46\" height=\"3\" rx=\"1\" fill=\"var(--amber)\"></rect> <text x=\"340\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">2 is even, so it goes</text> <rect x=\"110\" y=\"134\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"133\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text> <rect x=\"162\" y=\"134\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text> <rect x=\"214\" y=\"134\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"237\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text> <rect x=\"214\" y=\"170\" width=\"46\" height=\"3\" rx=\"1\" fill=\"var(--amber)\"></rect> <text x=\"340\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the 4 slid back behind the cursor, so position 2 is the 3</text> <rect x=\"110\" y=\"184\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"133\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text> <rect x=\"162\" y=\"184\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4</text> <rect x=\"214\" y=\"184\" width=\"46\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"237\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3</text> <text x=\"289\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">x</text> <text x=\"340\" y=\"200\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">position 3 is past the end, so the loop stops</text> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">xs is [1, 4, 3], and the 4 was never looked at</text> </svg>", "caption": "The loop counts positions and the list moves under it. Nothing raises, and an even number comes out of a loop written to remove them."}
```

**Iterate a copy, or build a new list:**

```python
xs = [x for x in xs if x % 2 != 0]      # the usual answer
for x in xs[:]:                          # or iterate a copy
```

The same applies to a dictionary — changing its size during iteration raises `RuntimeError`,
which is at least loud.

## The off-by-one

```python
for i in range(1, len(items)):    # skips items[0]
for i in range(len(items) + 1):   # IndexError on the last pass
```

Both come from computing an index. **`for item in items` cannot be off by one**, and `enumerate`
cannot either.

## The variable that outlives the loop

```python
for item in items:
    ...
print(item)        # the last one — or NameError if items was empty
```

Python has no block scope: the loop variable stays after the loop, holding whatever it had last.
Reading it deliberately is legitimate and rare; reading it by accident is a bug that works on
every non-empty input and raises on the empty one.

## And one that does raise, eventually

```python
total = 0
for row in rows:
    total += row["amount"]
```

Correct — until a row has no `amount`. `row.get("amount", 0)` is the decision to treat it as zero,
said out loud. Lesson 8 is the other answer: catch it and say which row.
