---
title: The implicit grid, and filling the holes
version: 1
---

A grid template declares some tracks. When there are more items than declared cells, or an item is placed outside them, the browser **adds tracks on its own**. Those are the **implicit grid**, and two properties control them: **`grid-auto-rows`** sizes the rows it adds (and `grid-auto-columns` the columns), and **`grid-auto-flow`** decides how items without a placement are put in.

Here is a shelf of three columns that declares no rows at all, with `grid-auto-rows: minmax(80px, auto)`: every row at least 80 tall, and taller if its content needs it:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Implicit grid · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf {
        display: grid;
        grid-template-columns: repeat(3, 200px);
        grid-auto-rows: minmax(80px, auto);
        gap: 10px;
        margin-bottom: 20px;
      }
      .shelf > * { background: #f4f1ea; }
      .wide { grid-column: span 2; }
      .dense { grid-auto-flow: dense; }
    </style>
  </head>
  <body>
    <div class="shelf sparse">
      <article class="a wide">A, wide</article>
      <article class="b wide">B, wide</article>
      <article class="c">C</article>
      <article class="d">D, with a description long enough to need several lines in a column two hundred pixels wide, which makes its row grow.</article>
    </div>
    <div class="shelf dense">
      <article class="a wide">A, wide</article>
      <article class="b wide">B, wide</article>
      <article class="c">C</article>
      <article class="d">D</article>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe implicit.html style .sparse grid-template-rows box '.sparse > *'
div.shelf.sparse  grid-template-rows: 80px 80px 120px
article.a.wide  x 0      y 0      width 410    height 80
article.b.wide  x 0      y 90     width 410    height 80
article.c       x 420    y 90     width 200    height 80
article.d       x 0      y 180    width 200    height 120
```

There are three rows, **80, 80 and 120**, all implicit: the third grew to 120 because D's description needed it, while the first two stayed at their minimum. `minmax(80px, auto)` is the usual value for card rows: a floor that keeps the grid even, and room for the card that has more to say.

## The hole, and `dense`

Read the positions. A is two columns wide and sits in row 1. B is two columns wide as well, and there is only one column left in row 1, so B goes to row 2. **The cell at the end of row 1 stays empty**: C, which would have fitted there, comes after B in the HTML, and the browser places items in order, never going back. That hole is the default, `grid-auto-flow: row`.

The second shelf on the page is the same, with **`grid-auto-flow: dense`**:

```
ana@laptop:~/site$ probe implicit.html box '.dense > *'
article.a.wide  x 0      y 320    width 410    height 80
article.b.wide  x 0      y 410    width 410    height 80
article.c       x 420    y 320    width 200    height 80
article.d       x 420    y 410    width 200    height 80
```

Now **C is at the end of row 1**, y 320, in the hole, and D at the end of row 2. The browser went back and filled each hole with the first later item that fits. It is the right tool for a gallery of pictures of mixed sizes where the order does not matter. Where the order does matter, it rearranges what the reader sees without changing what they hear or tab through, which is section 10.

`grid-auto-flow: column` fills columns first instead of rows, adding implicit columns as it goes, which suits a short list that should run down and then across.
