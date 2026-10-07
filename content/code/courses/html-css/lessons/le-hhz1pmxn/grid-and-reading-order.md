---
title: Placement and the order people read in
version: 1
---

Grid can put any item in any cell, whatever its place in the HTML, and `dense` packing moves items to fill holes. Both change **what is drawn where**. Neither changes **the order of the document**, and keyboard focus and screen readers follow the document. Here is a set of shelf links in a dense grid:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Reading order · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf {
        display: grid;
        grid-template-columns: repeat(3, 200px);
        grid-auto-rows: 80px;
        grid-auto-flow: dense;
        gap: 10px;
      }
      .shelf a { background: #f4f1ea; }
      .wide { grid-column: span 2; }
    </style>
  </head>
  <body>
    <nav class="shelf" aria-label="Shelves">
      <a class="wide" href="fiction.html">Fiction</a>
      <a class="wide" href="poetry.html">Poetry</a>
      <a href="essays.html">Essays</a>
      <a href="children.html">Children</a>
    </nav>
  </body>
</html>
```

```
ana@laptop:~/site$ probe order.html box a tab tab tab tab
a.wide  x 0      y 0      width 410    height 80
a.wide  x 0      y 90     width 410    height 80
a       x 420    y 0      width 200    height 80
a       x 420    y 90     width 200    height 80
focus: a "Fiction"
focus: a "Poetry"
focus: a "Essays"
focus: a "Children"
```

On screen, row 1 reads *Fiction*, *Essays* (x 420, y 0) and row 2 reads *Poetry*, *Children*: dense packing moved *Essays* up into the hole. **Tab goes Fiction, Poetry, Essays, Children**, the HTML order: from the top left down to the second row, back up to the top right, and down again. A sighted keyboard user sees the focus jump around, and a screen reader user hears an order that does not match what anybody sees.

The rule is lesson 8 section 10 again, and with Grid it needs more care, because Grid can move things much further than `order` ever does: **write the HTML in the order it should be read, and use placement to arrange that order on the screen, not to change it.** Placement that keeps the sequence, such as a sidebar beside the content rather than after it, is fine. Placement that reverses it, or `dense` packing on items whose order means something, needs either a different HTML order or a different layout.

There is a CSS property in development, `reading-flow`, that would let a grid's focus order follow its visual order. It is not in every browser yet, and the HTML order remains the thing to get right.
