---
title: Aligning across: align-items and align-self
version: 1
---

**`align-items`** places the items on the cross axis, which in a row means vertically. Here are four shelves 100 pixels tall, each holding three items whose text is 12, 28 and 16 pixels, so their natural heights differ:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>align-items · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .shelf { display: flex; gap: 8px; height: 100px; margin-bottom: 8px; background: #f4f1ea; }
      .book { padding: 4px 8px; background: #2f6f4e; color: white; }
      .small { font-size: 12px; }
      .big { font-size: 28px; }
      #stretch { align-items: stretch; }
      #flex-start { align-items: flex-start; }
      #center { align-items: center; }
      #baseline { align-items: baseline; }
    </style>
  </head>
  <body>
    <div class="shelf" id="stretch">
      <div class="book small">Poetry</div>
      <div class="book big">Fiction</div>
      <div class="book">Children</div>
    </div>
    <div class="shelf" id="flex-start">
      <div class="book small">Poetry</div>
      <div class="book big">Fiction</div>
      <div class="book">Children</div>
    </div>
    <div class="shelf" id="center">
      <div class="book small">Poetry</div>
      <div class="book big">Fiction</div>
      <div class="book">Children</div>
    </div>
    <div class="shelf" id="baseline">
      <div class="book small">Poetry</div>
      <div class="book big">Fiction</div>
      <div class="book">Children</div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe align.html box '#stretch .book'
div.book.small  x 0      y 0      width 50.69  height 100
div.book.big    x 58.69  y 0      width 98.47  height 100
div.book        x 165.16 y 0      width 75.59  height 100
ana@laptop:~/site$ probe align.html box '#flex-start .book'
div.book.small  x 0      y 108    width 50.69  height 26
div.book.big    x 58.69  y 108    width 98.47  height 50
div.book        x 165.16 y 108    width 75.59  height 32
ana@laptop:~/site$ probe align.html box '#center .book'
div.book.small  x 0      y 253    width 50.69  height 26
div.book.big    x 58.69  y 241    width 98.47  height 50
div.book        x 165.16 y 250    width 75.59  height 32
ana@laptop:~/site$ probe align.html box '#baseline .book'
div.book.small  x 0      y 341    width 50.69  height 26
div.book.big    x 58.69  y 324    width 98.47  height 50
div.book        x 165.16 y 337    width 75.59  height 32
```

The shelves are stacked 108 pixels apart, so `probe`'s y for each item includes its shelf's position: the stretch shelf starts at 0, the flex-start shelf at 108, the center shelf at 216 and the baseline shelf at 324. Subtracting that:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 214\" role=\"img\" aria-label=\"Four flex containers 100 pixels tall, each with three items whose text is 12, 28 and 16 pixels. stretch: all three items are 100 tall. flex-start: they keep their own heights, 26, 50 and 32, at the top. center: each is centred, at 37, 25 and 34 from the top. baseline: they are placed so that the baselines of their text line up, at 17, 0 and 13 from the top.\"><text x=\"20\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">stretch</text><rect x=\"20\" y=\"26\" width=\"149.42\" height=\"140\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"20\" y=\"26\" width=\"31.43\" height=\"140\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"56.39\" y=\"26\" width=\"61.05\" height=\"140\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"122.4\" y=\"26\" width=\"46.87\" height=\"140\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"196\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">flex-start</text><rect x=\"196\" y=\"26\" width=\"149.42\" height=\"140\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"196\" y=\"26\" width=\"31.43\" height=\"36.4\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"232.39\" y=\"26\" width=\"61.05\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"298.4\" y=\"26\" width=\"46.87\" height=\"44.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"372\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">center</text><rect x=\"372\" y=\"26\" width=\"149.42\" height=\"140\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"372\" y=\"77.8\" width=\"31.43\" height=\"36.4\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408.39\" y=\"61\" width=\"61.05\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"474.4\" y=\"73.6\" width=\"46.87\" height=\"44.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"548\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">baseline</text><rect x=\"548\" y=\"26\" width=\"149.42\" height=\"140\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"548\" y=\"49.8\" width=\"31.43\" height=\"36.4\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"584.39\" y=\"26\" width=\"61.05\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"650.4\" y=\"44.2\" width=\"46.87\" height=\"44.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Three items of 12, 28 and 16-pixel text in containers 100 tall, drawn from measured boxes.</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">baseline lines up the text inside the items, so the boxes themselves end up uneven.</text></svg>", "caption": "align-items places the items on the cross axis; stretch, the default, is why flex columns come out equal in height."}
```

- **`stretch`**, the default: every item is **100 tall**, the full height of the shelf, whatever its text.
- **`flex-start`**: each keeps its own height, **26, 50 and 32**, at the top of its shelf, which starts at 108.
- **`center`**: each is centred, at **37, 25 and 34** from the top, which is (100 − 26) / 2, (100 − 50) / 2 and (100 − 32) / 2.
- **`baseline`**: the items move so that **the first lines of their text sit on the same line**: 17, 0 and 13 from the top. The boxes end up uneven and the words read as one line, which is what a row of a price, a title and a label wants.

## One item on its own: `align-self`

`align-self` on one item overrides the container's `align-items` for that item alone: a row of stretched cards with one `align-self: flex-start` card that keeps its own height. There is no `justify-self` in Flexbox, because along the main axis the items are placed as a group; to push one item away from the others, Flexbox uses an `auto` margin, section 11.

## Centring something

`justify-content: center` and `align-items: center` together centre the items in both directions, and for a long time that pair was the reason people learnt Flexbox at all. Section 11 does it on the bookshop's empty-basket message.
