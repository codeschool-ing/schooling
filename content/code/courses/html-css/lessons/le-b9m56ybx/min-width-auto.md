---
title: The long word that will not shrink
version: 1
---

A flex item will not shrink below its **minimum content size**: for text, the width of its longest word or unbreakable string. That is the effect of the default `min-width: auto` on flex items, and it exists so that text is not squashed into overlapping letters. It is also the cause of rows that overflow for no visible reason. Here is a row with a title that grows to fill the space and a price of fixed width, twice:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>min-width · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .row { display: flex; gap: 8px; width: 400px; margin-bottom: 8px; background: #f4f1ea; }
      .title { flex: 1; }
      .price { flex: none; width: 80px; }
      .fixed .title { min-width: 0; overflow-wrap: anywhere; }
    </style>
  </head>
  <body>
    <div class="row">
      <p class="title">grande_sertao_veredas_first_edition_1956.pdf</p>
      <p class="price">R$ 240</p>
    </div>
    <div class="row fixed">
      <p class="title">grande_sertao_veredas_first_edition_1956.pdf</p>
      <p class="price">R$ 240</p>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe minwidth.html box .title box .price spill .row
p.title  x 0      y 16     width 330.91 height 24
p.title  x 0      y 80     width 312    height 48
p.price  x 338.91 y 16     width 80     height 24
p.price  x 320    y 80     width 80     height 48
div.row  content 419 wide in a box 400 wide: it spills
div.row.fixed  content 400 wide in a box 400 wide
```

The title is a file name with no spaces and no hyphens, which the browser cannot break. In the first row, the title should have been 312 wide, 400 minus the 8-pixel gap and the 80-pixel price. **It refused to go below 330.91**, the width of that unbreakable string, and pushed the price to x 338.91, so that it ends at 418.91: **the row's content is 419 wide in a box 400 wide**. On a real page that is the price hanging off the edge of the card, or a page that scrolls sideways on a phone.

The second row gives the title two declarations: **`min-width: 0`**, which removes the floor and lets the item shrink to its share, and `overflow-wrap: anywhere` from lesson 6, which lets the string break so that it fits. The title is 312 wide and two lines tall, and the row is exactly 400.

## How to recognise it

A flex row that is wider than its container, where one item holds a long URL, a file name, a code sample, a table or another flex container with long content. The fix is `min-width: 0` on the item that should shrink, plus whatever lets its content cope: wrapping, `overflow: hidden` with `text-overflow: ellipsis`, or `overflow: auto` for a table. In a column, the same floor applies to height, and the fix is `min-height: 0`.
