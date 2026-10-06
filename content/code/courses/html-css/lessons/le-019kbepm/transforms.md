---
title: Transforms move what is drawn, not the layout
version: 1
---

The **`transform`** property moves, rotates, scales or skews an element **after layout has placed it**. That one fact explains everything else about transforms. Here are three books on a shelf, and the middle one lifted:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 40px 16px; font-family: system-ui, sans-serif; }
      .shelf { display: flex; gap: 16px; }
      .book { width: 120px; height: 160px; background: #f4f1ea; border: 1px solid #8a8577; }
      .lifted { transform: translate(0, -24px) scale(1.1); }
    </style>
  </head>
  <body>
    <div class="shelf">
      <div class="book">One</div>
      <div class="book lifted">Two</div>
      <div class="book">Three</div>
    </div>
  </body>
</html>
```

`translate(0, -24px)` moves it 24 pixels up, and `scale(1.1)` makes it 10% bigger. The `probe` measured two different things: **`box`** asks where the element is drawn, transform included, and the new step **`layout`** asks where layout put it, before any transform:

```
ana@laptop:~/site$ probe move.html box .book layout .book
div.book         x 16     y 40     width 122    height 162
div.book.lifted  x 147.9  y 7.9    width 134.2  height 178.2
div.book         x 292    y 40     width 122    height 162
div.book  laid out at x 16, y 40, width 122, height 162
div.book.lifted  laid out at x 154, y 40, width 122, height 162
div.book  laid out at x 292, y 40, width 122, height 162
```

The lifted book is **drawn** at y 7.9, 134.2 wide and 178.2 tall: 10% bigger and moved up. But **layout** still has it at x 154, y 40, 122 by 162, exactly the size and place of its neighbours. And the third book is at x 292, as if nothing had happened, because for layout nothing did. The scaled book now overlaps the gap on each side, and the shelf did not make room for it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 204\" role=\"img\" aria-label=\"Three books from move.html, drawn from measured boxes. The middle one, Two, has a dashed outline where layout put it, at x 154, y 40, 122 by 162, the same size as its neighbours, and a solid one where it is drawn, moved up and 10% bigger, at x 147.9, y 7.9, 134.2 by 178.2. The third book stays at x 292.\"><rect x=\"54.4\" y=\"46\" width=\"109.8\" height=\"145.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"62.4\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">One</text><rect x=\"302.8\" y=\"46\" width=\"109.8\" height=\"145.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"310.8\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Three</text><rect x=\"173.11\" y=\"17.11\" width=\"120.78\" height=\"160.38\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"181.11\" y=\"33.11\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Two</text><path d=\"M 178.6 46 H 288.4 V 191.8 H 178.6 Z\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></path><text x=\"440\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dashed: where layout put Two,</text><text x=\"440\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">x 154, y 40, 122 by 162</text><text x=\"440\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">solid: where it is drawn,</text><text x=\"440\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">x 147.9, y 7.9, 134.2 by 178.2</text><text x=\"440\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Three stays at x 292: for</text><text x=\"440\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">layout, nothing moved.</text></svg>", "caption": "A transform changes the drawing and leaves the layout alone, so nothing around it moves."}
```

## What that buys, and what it costs

**It buys smoothness.** Moving something by changing `margin` or `top` changes layout, and every box after it may move too. A transform changes nothing the browser has to lay out again, which is why section 07 will find that it is the cheap way to animate movement.

**It costs space.** A transformed element can cover its neighbours, as the lifted book does, and it can go past the edge of its container or the window, where `overflow` clips it or makes a scrollbar. If something should take up more room, change its size, not its scale.

Transforms are drawn from the **`transform-origin`**, which is the centre of the element by default. That is why the scaled book grew in all four directions, starting 6.1 pixels left of where it was laid out. `transform-origin: bottom` would make it grow upwards from the shelf.
