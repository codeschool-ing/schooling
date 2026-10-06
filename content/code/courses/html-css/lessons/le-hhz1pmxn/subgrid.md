---
title: subgrid: lining up the inside of separate items
version: 1
---

A grid lines up its items. It does not line up **the contents** of its items: a card is a grid item, and the title, text and link inside it are laid out by the card, which knows nothing about the cards beside it. When the titles are of different lengths, the links at the bottom of the cards end up at different heights. **`subgrid`** lets an item take part in its parent's tracks, so that the parts of different cards share the same rows. Here are three event cards twice, the second time with subgrid:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Subgrid · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .events {
        display: grid;
        grid-template-columns: repeat(3, 220px);
        gap: 16px;
        margin-bottom: 24px;
      }
      .events article { background: #f4f1ea; padding: 8px; }
      .events h2 { margin: 0; font-size: 1.1rem; }
      .events p { margin: 0; }
      .aligned article {
        display: grid;
        grid-row: span 3;
        grid-template-rows: subgrid;
        gap: 8px;
      }
    </style>
  </head>
  <body>
    <div class="events plain">
      <article><h2>Book swap</h2><p>Saturday, from 10 am.</p><a href="swap.html">Details</a></article>
      <article><h2>Poetry reading: Hilda Hilst and her contemporaries</h2><p>Thursday, 7 pm.</p><a href="poetry.html">Details</a></article>
      <article><h2>Bookbinding</h2><p>A two-hour class for beginners, with all materials included.</p><a href="binding.html">Details</a></article>
    </div>
    <div class="events aligned">
      <article><h2>Book swap</h2><p>Saturday, from 10 am.</p><a href="swap.html">Details</a></article>
      <article><h2>Poetry reading: Hilda Hilst and her contemporaries</h2><p>Thursday, 7 pm.</p><a href="poetry.html">Details</a></article>
      <article><h2>Bookbinding</h2><p>A two-hour class for beginners, with all materials included.</p><a href="binding.html">Details</a></article>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe subgrid.html box '.plain p' box '.plain a'
p  x 8      y 34.39  width 204    height 24
p  x 244    y 87.17  width 204    height 24
p  x 480    y 34.39  width 204    height 72
a  x 8      y 61.39  width 48.91  height 17
a  x 244    y 114.17 width 48.91  height 17
a  x 480    y 109.39 width 48.91  height 17
ana@laptop:~/site$ probe subgrid.html box '.aligned p' box '.aligned a'
p  x 8      y 262.34 width 204    height 72
p  x 244    y 262.34 width 204    height 72
p  x 480    y 262.34 width 204    height 72
a  x 8      y 342.34 width 204    height 24
a  x 244    y 342.34 width 204    height 24
a  x 480    y 342.34 width 204    height 24
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Three event cards, twice. In the plain grid, each card lays out its title, paragraph and link on its own, so the links land at three different heights, 61.39, 114.17 and 109.39. With subgrid, the cards use their parent&#x27;s rows, so every paragraph starts at the same height and every link does too.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">grid</text><rect x=\"20\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"26\" y=\"46.63\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"26\" y=\"62.83\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"124\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"78.3\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130\" y=\"94.5\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"228\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"46.63\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"91.63\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><text x=\"380\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">grid + subgrid</text><rect x=\"380\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"386\" y=\"46.6\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"386\" y=\"94.6\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"484\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"490\" y=\"46.6\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"490\" y=\"94.6\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"588\" y=\"26\" width=\"96\" height=\"150\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"594\" y=\"46.6\" width=\"84\" height=\"10\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"594\" y=\"94.6\" width=\"40\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\"></rect><text x=\"20\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">The wide bar is each card’s paragraph, the short one its link. On the left, each card lays out its own rows: the links</text><text x=\"20\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">land at 61.39, 114.17 and 109.39. With subgrid they share the parent’s rows: all three at the same height.</text></svg>", "caption": "subgrid lets the parts of separate cards line up with each other."}
```

In the plain grid, each card's paragraph starts below its own title, at **34.39, 87.17 and 34.39**, because the second title takes three lines. The links land at **61.39, 114.17 and 109.39**, three different heights, which looks careless in a row of cards. With subgrid, every paragraph starts at **262.34** and every link at **342.34**.

What did it: each card spans three rows of the parent grid, `grid-row: span 3`, and declares `grid-template-rows: subgrid`, which means "my rows are those three rows of my parent". The parent's implicit rows are sized by the tallest content across all the cards, the long title, the long paragraph, so every card's title row is as tall as the tallest title. The links also stretch to the card's width, **204**, because a grid item stretches by default; a `justify-self: start` would keep them to their text.

`subgrid` works for columns too, and is supported in every current browser. Before it existed, this was done with fixed heights for the titles, which broke whenever a title was longer than expected.
