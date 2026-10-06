---
title: repeat(), minmax() and as many columns as fit
version: 1
---

Writing `1fr 1fr 1fr 1fr` gets tedious, and **`repeat(4, 1fr)`** says the same thing. That much is shorthand. Combined with two more ideas it becomes the most useful line in Grid.

**`minmax(min, max)`** sizes a track between two limits: `minmax(200px, 1fr)` is never narrower than 200 pixels and otherwise takes a share of the space. And instead of a count, `repeat()` accepts **`auto-fill`** or **`auto-fit`**, which mean "as many tracks as fit". Together:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>auto-fill and auto-fit · Andorinha Books</title>
    <style>
      body { margin: 0; padding: 8px; font: 16px/1.5 sans-serif; }
      .cards { display: grid; gap: 16px; margin-bottom: 16px; }
      .fill { grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); }
      .fit { grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); }
      .cards > article { background: #f4f1ea; }
    </style>
  </head>
  <body>
    <div class="cards fill">
      <article>Poetry reading</article>
      <article>Book swap</article>
      <article>Bookbinding</article>
    </div>
    <div class="cards fit">
      <article>Poetry reading</article>
      <article>Book swap</article>
      <article>Bookbinding</article>
    </div>
  </body>
</html>
```

`probe` asked the browser what tracks it made, and where the three cards went:

```
ana@laptop:~/site$ probe autofit.html style .fill grid-template-columns style .fit grid-template-columns
div.cards.fill  grid-template-columns: 240px 240px 240px 240px
div.cards.fit  grid-template-columns: 325.328px 325.328px 325.344px 0px
ana@laptop:~/site$ probe autofit.html box '.fill article' box '.fit article'
article  x 8      y 8      width 240    height 24
article  x 264    y 8      width 240    height 24
article  x 520    y 8      width 240    height 24
article  x 8      y 48     width 325.33 height 24
article  x 349.33 y 48     width 325.33 height 24
article  x 690.66 y 48     width 325.34 height 24
```

The page has 1008 pixels of width to work with. A track of at least 200 and gaps of 16 fit **four times**: 4 × 200 + 3 × 16 = 848, and a fifth would need 1064. So both grids made four tracks. The difference is what happened to the fourth, which has no card in it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"Three cards in two grids 1008 pixels wide. With repeat auto-fill and minmax 200px 1fr, the browser made four tracks of 240 and the fourth stays empty. With auto-fit, it made the same four tracks, collapsed the empty one to 0 pixels, and the three cards are 325.33 wide each.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">repeat(auto-fill, minmax(200px, 1fr))</text><rect x=\"20\" y=\"30\" width=\"148.8\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"94.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">240</text><rect x=\"178.72\" y=\"30\" width=\"148.8\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"253.12\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">240</text><rect x=\"337.44\" y=\"30\" width=\"148.8\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"411.84\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">240</text><rect x=\"496.16\" y=\"30\" width=\"148.8\" height=\"40\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></rect><text x=\"570.56\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">240</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">repeat(auto-fit, minmax(200px, 1fr))</text><rect x=\"20\" y=\"110\" width=\"201.7\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"120.85\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">325.33</text><rect x=\"231.62\" y=\"110\" width=\"201.7\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"332.48\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">325.33</text><rect x=\"443.25\" y=\"110\" width=\"201.71\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"544.1\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">325.34</text><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">auto-fill made four tracks and left the fourth empty; auto-fit made the same four, collapsed the empty</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one to 0px, and shared its space among the three cards.</text></svg>", "caption": "The two differ only when there are fewer items than tracks."}
```

**`auto-fill` kept the empty track**: four columns of **240**, the cards in the first three, and space for a fourth card on the right. **`auto-fit` collapsed the empty track to 0px**, as the computed value says, and gave its space to the others: three cards of **325.33**. With twelve cards the two would be identical; they differ only when there are fewer items than tracks. Choose `auto-fit` when the items should stretch to fill the row, `auto-fill` when every item should keep the same size wherever the row ends.

## The layout that responds by itself

On a phone 390 wide, the same `auto-fit` grid makes one column:

```
ana@laptop:~/site$ probe --width 390 autofit.html box '.fit article'
article  x 8      y 128    width 374    height 24
article  x 8      y 168    width 374    height 24
article  x 8      y 208    width 374    height 24
```

There was room for one 200-pixel track and not for two, so there is one column, **374** wide, and the cards stack. **One line of CSS gives four columns on a desktop, two on a tablet and one on a phone**, with no breakpoint chosen by anybody, because the number of columns follows from the space and the minimum width. Lesson 11 builds on exactly this: a layout that adapts on its own needs fewer media queries.
