---
title: A flex container and its two axes
version: 1
---

**Flexbox is a way of laying out the children of one element in a line.** Write `display: flex` on a container, and its direct children become **flex items**, placed one after another along a line instead of stacked as blocks. Here is a shelf of three books, once as a row and once as a column:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Axes · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf { display: flex; width: 600px; background: #f4f1ea; }
      .column { flex-direction: column; }
      .book { padding: 8px; background: #2f6f4e; color: white; }
    </style>
  </head>
  <body>
    <div class="shelf row">
      <div class="book">Vidas Secas</div>
      <div class="book">Macunaíma</div>
      <div class="book">Grande Sertão: Veredas</div>
    </div>
    <div class="shelf column">
      <div class="book">Vidas Secas</div>
      <div class="book">Macunaíma</div>
      <div class="book">Grande Sertão: Veredas</div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe axes.html box '.row .book' box '.column .book'
div.book  x 0      y 0      width 104.66 height 40
div.book  x 104.66 y 0      width 99.59  height 40
div.book  x 204.25 y 0      width 188.56 height 40
div.book  x 0      y 40     width 600    height 40
div.book  x 0      y 80     width 600    height 40
div.book  x 0      y 120    width 600    height 40
```

In the row, the three books sit side by side starting at x 0, and **each is as wide as its own content**: 104.66, 99.59 and 188.56, the titles plus their padding. The shelf is 600 wide and the books use 393 of it; the rest is left over, which is what most of this lesson is about. In the column, the same books stack, and **each is 600 wide**, the whole width of the shelf.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"Two flex containers. With flex-direction row, three items A, B and C sit side by side, each as wide as its content; the main axis runs left to right and the cross axis top to bottom. With flex-direction column, the same items stack; the main axis runs top to bottom, the cross axis left to right, and the items stretch across it to the full width.\"><defs><marker id=\"ah8\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ah8b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">flex-direction: row</text><rect x=\"20\" y=\"30\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"30\" y=\"40\" width=\"70\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A</text><rect x=\"106\" y=\"40\" width=\"66\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"139\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">B</text><rect x=\"178\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"238\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">C</text><line x1=\"20\" y1=\"116\" x2=\"316\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#ah8)\"></line><text x=\"20\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">main axis: the items line up along it</text><line x1=\"336\" y1=\"30\" x2=\"336\" y2=\"98\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#ah8b)\"></line><text x=\"348\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cross</text><text x=\"420\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">flex-direction: column</text><rect x=\"420\" y=\"30\" width=\"200\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"430\" y=\"40\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A</text><rect x=\"430\" y=\"86\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">B</text><rect x=\"430\" y=\"132\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">C</text><line x1=\"640\" y1=\"30\" x2=\"640\" y2=\"178\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#ah8)\"></line><text x=\"652\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">main</text><line x1=\"420\" y1=\"196\" x2=\"618\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#ah8b)\"></line><text x=\"420\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cross axis: items stretch across it</text></svg>", "caption": "justify-content works along the main axis and align-items across it, whichever way the main axis points."}
```

That difference is the whole model. A flex container has two axes. **The main axis is the direction the items are laid out in**, set by `flex-direction`: `row`, the default, runs left to right, and `column` runs top to bottom. **The cross axis runs across it.** Two properties then do almost all the work, and they are easy to tell apart once the axes are fixed in your head:

- **`justify-content`** places the items **along the main axis**: packed at the start, in the middle, spread out. Section 04.
- **`align-items`** places them **across**, on the cross axis: at the top, in the middle, or stretched to fill. Section 05.

The column's books were 600 wide because the default value of `align-items` is `stretch`: on the cross axis, items stretch to fill the container. In a row, the cross axis is vertical, so the same default makes every item as tall as the row, which is why flex columns come out equal in height without anybody asking.

## Only the children

`display: flex` affects **only the direct children** of the container. A paragraph inside a book is laid out in the ordinary way inside its book; to lay out the book's contents in a line as well, the book becomes a flex container too. Nesting flex containers is normal, and a page is usually several of them.

The container itself still behaves like a block to its own neighbours: it takes the full width and starts on a new line. `display: inline-flex` makes it sit inside a line of text instead, as `inline-block` did in lesson 6.

`row-reverse` and `column-reverse` exist too, and lay the items out from the other end. Section 10 is about why reversing the visual order is more dangerous than it looks.
