---
title: Columns, rows and the fr unit
version: 1
---

**`grid-template-columns`** lists the columns, one size per column; `grid-template-rows` does the same for rows. Here is a grid of three columns: a fixed one of 200 pixels and two that share what is left, the second getting twice as much as the first:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Tracks · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .grid {
        display: grid;
        grid-template-columns: 200px 1fr 2fr;
        gap: 16px;
        width: 800px;
      }
      .grid > div { background: #f4f1ea; }
    </style>
  </head>
  <body>
    <div class="grid">
      <div>Filters</div>
      <div>Fiction</div>
      <div>Poetry, essays and everything else on the shelves</div>
      <div>Sort</div>
      <div>12 titles</div>
      <div>31 titles</div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe tracks.html box '.grid > div'
div  x 0      y 0      width 200    height 24
div  x 216    y 0      width 189.33 height 24
div  x 421.33 y 0      width 378.67 height 24
div  x 0      y 40     width 200    height 24
div  x 216    y 40     width 189.33 height 24
div  x 421.33 y 40     width 378.67 height 24
```

The six items fill the cells in order, left to right and then on to the next row. The first column is **200** wide, as written. The other two are **189.33** and **378.67**, and the arithmetic is the whole point of **`fr`**. The container is 800 wide; the fixed column takes 200 and the two gaps take 32; that leaves **568**. The fr values add up to 3, so 1fr is 568 / 3 = 189.33 and 2fr is twice that, 378.67.

**An `fr` is one share of the space left after everything fixed has been taken out**, gaps included. It is lesson 8's `flex: 1` given a unit: equal fr values are equal columns whatever their content, which is what `1fr 1fr 1fr` is for. And because the gaps come off first, three columns of `1fr` plus two gaps of 16 always fit the container exactly, which percentages never managed: `33.33%` three times plus two gaps is wider than 100%.

## Mixing units

A track size can be any length, `200px` or `15rem`; a percentage of the container; `fr`; or one of the content keywords from lesson 6: `min-content`, `max-content`, `auto`. `auto` columns are sized by their content and then stretched to fill any free space if there are no `fr` columns, which makes `auto 1fr` the usual way to say "a label column as wide as it needs, and the rest for the content".

A grid with no `grid-template-rows` still has rows: as many as the items need, each as tall as its content. Those are **implicit** rows, section 07.
