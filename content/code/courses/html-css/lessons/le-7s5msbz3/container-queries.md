---
title: Container queries: a component that measures its own room
version: 2
---

A media query asks about the **window**. A component often needs to ask something else: how much room has **it** been given? The same event card can be in the wide main column or in a narrow sidebar on one page, at one window width. A media query cannot tell the two apart. A **container query** can. Here is one, in `container.css`:

```css
*, *::before, *::after { box-sizing: border-box; }
body {
  margin: 0;
  padding: 16px;
  display: grid;
  grid-template-columns: 1fr 240px;
  gap: 24px;
  font-family: system-ui, sans-serif;
}

/* The card's parent is the container it measures. */
.slot { container-type: inline-size; }

.event-card { display: grid; gap: 8px; padding: 16px; background: #f4f1ea; }
.event-card__date { margin: 0; font-weight: 700; }
.event-card__title { margin: 0; font-size: clamp(1rem, 4cqi, 2rem); }

/* Wide enough for the date to sit beside the text. */
@container (width >= 28rem) {
  .event-card { grid-template-columns: 6rem 1fr; }
}
```

Two steps. **`container-type: inline-size`** on an element makes it a **query container**: its descendants can ask about its width. Then **`@container (width >= 28rem)`** works like a media query, except that `width` is the width of the nearest ancestor container, here the `.slot` around each card. The card is a single column by default, and puts the date beside the text when its container is at least 28rem wide.

The page, `container.html`, puts one card in `main` and one in the `aside`, each in its own `.slot`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="container.css">
  </head>
  <body>
    <main>
      <h1>This week</h1>
      <div class="slot">
        <article class="event-card">
          <p class="event-card__date">Thu 9</p>
          <div class="event-card__body">
            <h2 class="event-card__title">Poetry reading</h2>
            <p>Five poets read from their first books. Free, and there is tea.</p>
          </div>
        </article>
      </div>
    </main>
    <aside>
      <div class="slot">
        <article class="event-card">
          <p class="event-card__date">Sat 11</p>
          <div class="event-card__body">
            <h2 class="event-card__title">Bookbinding</h2>
            <p>Bind a notebook by hand. Places for twelve.</p>
          </div>
        </article>
      </div>
    </aside>
  </body>
</html>
```

```
ana@laptop:~/site$ probe container.html box .slot box .event-card__date box .event-card__body style .event-card__title font-size
div.slot  x 16     y 97.88  width 728    height 119
div.slot  x 768    y 16     width 240    height 152
p.event-card__date  x 32     y 113.88 width 96     height 87
p.event-card__date  x 784    y 32     width 208    height 20
div.event-card__body  x 136    y 113.88 width 592    height 87
div.event-card__body  x 784    y 60     width 208    height 92
h2.event-card__title  font-size: 29.12px
h2.event-card__title  font-size: 16px
```

One page, one window 1024 wide, two different layouts of the same component. The slot in `main` is **728** wide, so its card has the date in a column **96** wide, 6rem, and the text beside it at x 136. The slot in the aside is **240**, so its date runs across the top, **208** wide, with the text below it at y 60. No class says which is which; each card measured its own room.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 214\" role=\"img\" aria-label=\"container.html at 1024 by 768, drawn from measured boxes. The main column holds a slot 728 wide, and its card puts the date in a column 96 wide beside the text. The aside holds a slot 240 wide, and its card puts the date across the top, 208 wide, with the text below.\"><rect x=\"20\" y=\"20\" width=\"634.88\" height=\"143.84\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"29.92\" y=\"80.69\" width=\"451.36\" height=\"73.78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"39.84\" y=\"90.61\" width=\"59.52\" height=\"53.94\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"104.32\" y=\"90.61\" width=\"367.04\" height=\"53.94\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"496.16\" y=\"29.92\" width=\"148.8\" height=\"94.24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"506.08\" y=\"39.84\" width=\"128.96\" height=\"12.4\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"506.08\" y=\"57.2\" width=\"128.96\" height=\"57.04\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"29.92\" y=\"69.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">main: slot 728 wide</text><text x=\"496.16\" y=\"135.32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aside: slot 240 wide</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">The small solid box is the date, the dashed one the text. Same card, same window, 1024 wide: in the 728 slot</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">@container (width &gt;= 28rem) matched and the date sits beside the text; in the 240 slot it did not.</text></svg>", "caption": "A container query asks how wide the component's own slot is, not the window."}
```

## Container units

The title's size is `clamp(1rem, 4cqi, 2rem)`. **`cqi`** is 1% of the container's inline size, its width in a horizontal language: `vw` for a container. The wide card's title came out at **29.12px**, 4% of 728; the narrow one's at **16px**, the minimum, because 4% of 240 is 9.6. Fluid type, per component.

## Why the wrapper

A container cannot query **itself**: the card's grid columns depend on the container's width, and if the card were its own container, its layout could change its width and loop. So the container is an element around the component. `container-type: inline-size` also tells the browser that the container's width does not depend on its contents, which is what makes the query safe to answer. That is why `inline-size` is the usual value and `size`, which contains the height too, needs the container to have a height of its own.

**Use media queries for the page, container queries for components.** The shell of section 05 depends on the window; a card that can be dropped anywhere should depend on its slot. Container queries are supported in every current browser.
