---
title: Lines, and placing items on them
version: 1
---

Items fill the grid in order by default. To put an item somewhere specific, you say **which lines it starts and ends at**. The lines are numbered from 1 at the start of the grid, and from **-1 backwards** from the end. Here is a board of four columns and three rows with items placed in four different ways:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Lines · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .board {
        display: grid;
        grid-template-columns: repeat(4, 200px);
        grid-template-rows: repeat(3, 100px);
        gap: 10px;
      }
      .board > * { background: #f4f1ea; }
      .feature { grid-column: 1 / 3; grid-row: 1 / 3; }
      .banner { grid-column: 1 / -1; }
      .tall { grid-row: span 2; }
    </style>
  </head>
  <body>
    <section class="board">
      <article class="feature">Feature: Hilda Hilst</article>
      <article class="tall">Book swap</article>
      <article>Bookbinding</article>
      <article>New arrivals</article>
      <article class="banner">Closed on 12 October</article>
    </section>
  </body>
</html>
```

```
ana@laptop:~/site$ probe lines.html box '.board > *'
article.feature  x 0      y 0      width 410    height 210
article.tall     x 420    y 0      width 200    height 210
article          x 630    y 0      width 200    height 100
article          x 630    y 110    width 200    height 100
article.banner   x 0      y 220    width 830    height 100
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"The board from lines.html drawn from measured boxes, with its grid lines numbered: 1 to 5 across the four columns and 1 to 4 down the three rows. The feature spans column lines 1 to 3 and row lines 1 to 3. The tall item spans two rows in the third column. Two unplaced items fill the fourth column. The banner runs from line 1 to line -1, the whole width of the bottom row.\"><line x1=\"50\" y1=\"20\" x2=\"50\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"50\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><line x1=\"177.1\" y1=\"20\" x2=\"177.1\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"177.1\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2</text><line x1=\"307.3\" y1=\"20\" x2=\"307.3\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"307.3\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3</text><line x1=\"437.5\" y1=\"20\" x2=\"437.5\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"437.5\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4</text><line x1=\"564.6\" y1=\"20\" x2=\"564.6\" y2=\"236.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"564.6\" y=\"12\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">5</text><line x1=\"36\" y1=\"34\" x2=\"568.6\" y2=\"34\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"26\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><line x1=\"36\" y1=\"99.1\" x2=\"568.6\" y2=\"99.1\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"26\" y=\"99.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2</text><line x1=\"36\" y1=\"167.3\" x2=\"568.6\" y2=\"167.3\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"26\" y=\"167.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3</text><line x1=\"36\" y1=\"232.4\" x2=\"568.6\" y2=\"232.4\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"26\" y=\"232.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4</text><rect x=\"50\" y=\"34\" width=\"254.2\" height=\"130.2\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"58\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.feature  1 / 3, 1 / 3</text><rect x=\"310.4\" y=\"34\" width=\"124\" height=\"130.2\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"318.4\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.tall  span 2</text><rect x=\"440.6\" y=\"34\" width=\"124\" height=\"62\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"440.6\" y=\"102.2\" width=\"124\" height=\"62\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"50\" y=\"170.4\" width=\"514.6\" height=\"62\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"58\" y=\"186.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.banner  1 / -1</text><text x=\"580\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Lines are numbered</text><text x=\"580\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">from 1, and from -1</text><text x=\"580\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">backwards: 1 / -1</text><text x=\"580\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">is the whole width.</text><text x=\"580\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">An item with no</text><text x=\"580\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">position takes the</text><text x=\"580\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">next free cell.</text></svg>", "caption": "Items are placed between numbered lines, not into numbered cells."}
```

- **`.feature { grid-column: 1 / 3; grid-row: 1 / 3; }`** starts at column line 1 and ends at line 3, so it covers two columns, and the same for rows: **410 by 210**, two tracks of 200 plus the 10-pixel gap between them, in each direction.
- **`.tall { grid-row: span 2; }`** says only "two rows tall" and lets the browser pick where: the first free place, the third column, **200 by 210**.
- The two articles with no placement fill the next free cells, the fourth column of rows 1 and 2.
- **`.banner { grid-column: 1 / -1; }`** runs from the first line to the last, **830** wide, the full width, however many columns there turn out to be. That is the reason to count backwards: `1 / -1` is "edge to edge" in any grid.

## The forms of grid-column

`grid-column` is shorthand for `grid-column-start` and `grid-column-end`, written with a slash. Each end can be a line number, a negative line number, `span n`, or a line name (the next section). `grid-column: 2` alone puts the item in column 2, one track wide. `grid-area: 1 / 1 / 3 / 3` sets all four at once, in the order row-start, column-start, row-end, column-end, which is easy to get wrong, and the next section gives `grid-area` a better use.

**Placing items does not change the HTML.** An item placed in the first cell can be the last in the file, and that has a consequence for keyboard and screen reader users that section 10 measures.
