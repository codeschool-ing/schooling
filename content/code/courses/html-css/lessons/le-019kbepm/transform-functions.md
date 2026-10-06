---
title: translate, rotate, scale, and their order
version: 1
---

A transform is a list of **functions**. The common ones:

- **`translate(x, y)`** moves. Percentages are of the element's **own** size: `translate(-50%, -50%)` moves an element up and left by half its width and height, which is the old centring trick.
- **`rotate(angle)`** turns, clockwise for positive angles: `45deg`, `0.25turn`.
- **`scale(x, y)`** or `scale(n)` resizes what is drawn. `scale(-1, 1)` mirrors it.
- **`skew(angle)`** slants it; it is rarely what you want.

A list is applied **from right to left**, and each function works in the coordinate system the next one left it in. So the order changes the result:

```css
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 16px; }
      .tile { width: 60px; height: 60px; margin-bottom: 100px; background: #2f6f4e; }
      .move-then-turn { transform: translateX(200px) rotate(90deg); }
      .turn-then-move { transform: rotate(90deg) translateX(200px); }
      .separate       { rotate: 90deg; translate: 200px; }
    </style>
  </head>
  <body>
    <div class="tile move-then-turn"></div>
    <div class="tile turn-then-move"></div>
    <div class="tile separate"></div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe order.html box .tile style .tile transform
div.tile.move-then-turn  x 216    y 16     width 60     height 60
div.tile.turn-then-move  x 16     y 376    width 60     height 60
div.tile.separate        x 216    y 336    width 60     height 60
div.tile.move-then-turn  transform: matrix(0, 1, -1, 0, 200, 0)
div.tile.turn-then-move  transform: matrix(0, 1, -1, 0, 0, 200)
div.tile.separate  transform: none
```

`translateX(200px) rotate(90deg)` turned the tile and then moved it 200 to the **right**: x 216. `rotate(90deg) translateX(200px)` first moved it along its own x axis, and that axis had been turned to point **down**: the tile is 200 lower, at y 376, and did not move sideways at all. The computed matrices say the same thing: the last two numbers are the movement, 200 across in one and 200 down in the other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two tiles with the same two transform functions in opposite orders, drawn at 0.6 scale. With translateX then rotate, the tile moved 200 pixels to the right, to x 216. With rotate then translateX, the rotation turned the tile&#x27;s x axis to point down, so the translation moved it 200 pixels down, to y 376.\"><defs><marker id=\"ah12\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">translateX(200px) rotate(90deg)</text><rect x=\"20\" y=\"30\" width=\"320\" height=\"190\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"36\" y=\"46\" width=\"36\" height=\"36\" rx=\"1\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"156\" y=\"46\" width=\"36\" height=\"36\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">start</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">moved 200 across: x 216</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">rotate(90deg) translateX(200px)</text><rect x=\"380\" y=\"30\" width=\"320\" height=\"190\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"396\" y=\"46\" width=\"36\" height=\"36\" rx=\"1\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"396\" y=\"166\" width=\"36\" height=\"36\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"396\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">start</text><text x=\"380\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">moved 200 down: y 376</text><line x1=\"76\" y1=\"64\" x2=\"150\" y2=\"64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah12)\"></line><line x1=\"414\" y1=\"86\" x2=\"414\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah12)\"></line></svg>", "caption": "The functions are applied right to left, each in the axes the one before it left behind."}
```

## The separate properties

`translate`, `rotate` and `scale` also exist as **properties of their own**, and the third tile uses them. They are always applied in one fixed order, translate first, then rotate, then scale, whatever order you write them in. So `rotate: 90deg; translate: 200px` gave the same result as the first tile, x 216, and its `transform` is **none**, because nothing was set there. The separate properties are easier to read and easier to change one at a time, which matters most in the next sections: a hover can change `scale` without repeating the `translate` the element already had.
