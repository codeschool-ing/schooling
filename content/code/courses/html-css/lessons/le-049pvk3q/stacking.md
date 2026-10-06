---
title: Which box is on top: z-index and stacking contexts
version: 1
---

When positioned boxes overlap, something has to decide which one is drawn in front. Without any instruction, **later in the HTML is on top**, and positioned boxes are drawn above boxes in the normal flow. **`z-index`** changes that order: higher is in front. It works on positioned boxes, and on flex and grid items, which lessons 8 and 9 introduce.

That is the part everybody knows, and it leads straight to a puzzle. Here is a header with a drop-down menu at `z-index: 9999`, followed by a hero section at `z-index: 2`, arranged so that they overlap:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Stacking · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      header { position: relative; z-index: 1; height: 60px; background: #2f6f4e; }
      .menu {
        position: absolute;
        top: 40px;
        left: 20px;
        z-index: 9999;
        width: 200px;
        height: 120px;
        background: white;
        border: 1px solid #333;
      }
      .hero { position: relative; z-index: 2; height: 200px; background: #f4f1ea; }
    </style>
  </head>
  <body>
    <header>
      <ul class="menu">
        <li>Events</li>
        <li>Order a book</li>
      </ul>
    </header>
    <section class="hero"><h1>This week</h1></section>
  </body>
</html>
```

The first command measures the menu and the hero and asks what is drawn on top at the point 100,120, where they overlap; the second asks the same of `stacking-fixed.html`, the same page with one declaration removed, which the end of this section explains:

```
ana@laptop:~/site$ probe stacking.html box .menu box .hero top 100 120
ul.menu  x 20     y 56     width 242    height 122
section.hero  x 0      y 81.44  width 1024   height 200
at 100,120: h1  "This week"
ana@laptop:~/site$ probe stacking-fixed.html top 100 120
at 100,120: ul.menu  "Events Order a book"
```

**On the first page, the hero's heading is on top.** A menu at 9999 sits underneath a box at 2.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 254\" role=\"img\" aria-label=\"Stacking contexts in stacking.html. Inside the page&#x27;s context sit the header, with z-index 1, and the hero, with z-index 2. The menu, with z-index 9999, is inside the header, so it is painted as part of the header&#x27;s layer at level 1, and the hero at level 2 covers it. Without the header&#x27;s z-index, the menu competes at the page level and wins.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"220\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the page’s stacking context</text><rect x=\"36\" y=\"52\" width=\"300\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">header  z-index: 1</text><rect x=\"60\" y=\"84\" width=\"260\" height=\"46\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.menu  z-index: 9999</text><rect x=\"36\" y=\"156\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.hero  z-index: 2</text><text x=\"372\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">header has z-index: 1, so it makes a stacking</text><text x=\"372\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">context: everything inside it is painted as one</text><text x=\"372\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">layer at level 1. The menu’s 9999 only orders</text><text x=\"372\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">it among the header’s own children.</text><text x=\"372\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">At the page level the contest is header 1</text><text x=\"372\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">against hero 2, and the hero wins: probe</text><text x=\"372\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">found its h1 on top at 100,120.</text><text x=\"372\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Remove the header’s z-index and the menu</text><text x=\"372\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">competes at the page level with its 9999.</text></svg>", "caption": "z-index is compared only between siblings in the same stacking context."}
```

## Stacking contexts

`z-index` is not a single global ranking. A positioned element **with a `z-index` other than `auto`** creates a **stacking context**: everything inside it is painted together, as one layer, at that element's level, and the `z-index` values of its descendants only order them among each other, inside that layer. The header has `z-index: 1`, so the menu's 9999 means "first among the header's children". At the level of the page, the contest is the header's 1 against the hero's 2, and the hero wins, with the whole header, menu included, beneath it.

Remove `z-index` from the header, which is what `stacking-fixed.html` does, and the header no longer makes a stacking context. That was the second command above: there the menu, `ul.menu`, is on top at the same point, competing at the page level with its 9999 against the hero's 2.

**Several other properties create stacking contexts too**: an `opacity` below 1, any `transform`, a `filter`, `position: fixed` or `sticky`, and `isolation: isolate`, which exists only to create one. So a fade on a parent can push its dropdown under the next section.

## Keeping z-index sane

When a box is underneath something, the fix is almost never a bigger number: 9999 lost to 2. Find the ancestors that create stacking contexts, which DevTools' **Layers** panel and the 3D view in Edge show, and decide at that level. Keep a short scale of values with names, so that a modal is always above a menu and a menu above content, which lesson 10 writes as variables.
