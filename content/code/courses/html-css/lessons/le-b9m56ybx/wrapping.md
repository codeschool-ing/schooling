---
title: When the items do not fit: wrapping
version: 2
---

By default a flex container keeps all its items on **one line**, however many there are, and shrinks them to fit if it can. That is right for a menu of four links and wrong for a grid of thirty book covers, which should flow onto as many lines as they need. **`flex-wrap: wrap`** lets them:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Covers · Andorinha Books</title>
    <style>
      .covers { display: flex; flex-wrap: wrap; gap: 16px; }
    </style>
  </head>
  <body>
    <div class="covers">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
      <img src="cover.png" alt="" width="120" height="180">
    </div>
  </body>
</html>
```

Any small picture saved as `cover.png` serves for the covers, since the attributes fix their size. Eight covers 120 pixels wide, with 16 pixels between them, on a window 1024 wide and then on one 390 wide:

```
ana@laptop:~/site$ probe covers.html box img
img  x 8      y 8      width 120    height 180
img  x 144    y 8      width 120    height 180
img  x 280    y 8      width 120    height 180
img  x 416    y 8      width 120    height 180
img  x 552    y 8      width 120    height 180
img  x 688    y 8      width 120    height 180
img  x 824    y 8      width 120    height 180
img  x 8      y 204    width 120    height 180
ana@laptop:~/site$ probe --width 390 covers.html box img
img  x 8      y 8      width 120    height 180
img  x 144    y 8      width 120    height 180
img  x 8      y 204    width 120    height 180
img  x 144    y 204    width 120    height 180
img  x 8      y 400    width 120    height 180
img  x 144    y 400    width 120    height 180
img  x 8      y 596    width 120    height 180
img  x 144    y 596    width 120    height 180
```

With `wrap`, items that do not fit on the line move to a new one below, as words do in a paragraph. On the wide window, **seven covers fit on the first line**, at y 8, and the eighth starts a second line at y 204: seven covers and six gaps are 936 pixels, and an eighth would need 1072 of the 1008 available. On the phone there are **two to a line**, four lines down to y 596. No media query was involved, which lesson 11 will lean on: a layout that adapts by itself is one you never have to write breakpoints for.

## Each line is laid out on its own

When a flex container wraps, **each line is a separate row** as far as the main axis is concerned: `justify-content` spreads the items of each line independently, so a last line with two covers is laid out as two covers, not aligned with the columns above. If you need the items in all the lines to line up in columns, that is a grid, lesson 9, and that difference is the most reliable way to choose between the two: **Flexbox lays things out in one dimension, a line, and Grid in two, rows and columns at once.**

With several lines there is one more property, **`align-content`**, which places the lines themselves on the cross axis when the container is taller than they need: packed at the top, spread out, centred. On a single-line container it does nothing, which is the usual reason it seems not to work.

## The shorthand

`flex-flow` combines the two: `flex-flow: row wrap` is `flex-direction: row; flex-wrap: wrap`. It is common in older code and saves a line.
