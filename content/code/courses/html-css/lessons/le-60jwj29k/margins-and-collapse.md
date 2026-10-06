---
title: Margins, and when two become one
version: 1
---

Margins have one behaviour that padding and border do not, and it surprises everybody once: **vertical margins that touch collapse into one**, as big as the larger of them. Here are four event cards, each with 24 pixels of margin above and below, each holding a heading with 16 pixels of margin above and below:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Margins · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .event { margin: 24px 0; background: #f4f1ea; }
      .event h2 { margin: 16px 0; }
      .boxed { padding: 1px 0; }
      .centred { width: 400px; margin: 0 auto; }
    </style>
  </head>
  <body>
    <article class="event"><h2>Poetry reading</h2></article>
    <article class="event"><h2>Book swap</h2></article>
    <article class="event boxed"><h2>Bookbinding</h2></article>
    <article class="event centred"><h2>Centred</h2></article>
  </body>
</html>
```

```
ana@laptop:~/site$ probe margins.html box .event box h2
article.event          x 0      y 24     width 1024   height 27
article.event          x 0      y 75     width 1024   height 27
article.event.boxed    x 0      y 126    width 1024   height 61
article.event.centred  x 312    y 211    width 400    height 27
h2  x 0      y 24     width 1024   height 27
h2  x 0      y 75     width 1024   height 27
h2  x 0      y 143    width 1024   height 27
h2  x 312    y 211    width 400    height 27
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Three articles from margins.html, drawn at their measured positions. The first starts at y 24, the second at 75 and the third at 126, so the gaps are 24 each: the articles&#x27; 24-pixel margins and their headings&#x27; 16-pixel margins all collapsed into one 24-pixel gap. The third article has 1 pixel of padding, which stops its heading&#x27;s margins collapsing through it, and it is 61 tall: 1 plus 16 plus 27 plus 16 plus 1.\"><rect x=\"40\" y=\"51.2\" width=\"300\" height=\"35.1\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"68.75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">article 1</text><rect x=\"40\" y=\"117.5\" width=\"300\" height=\"35.1\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"135.05\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">article 2</text><rect x=\"40\" y=\"183.8\" width=\"300\" height=\"79.3\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"223.45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">article 3, padding 1px</text><line x1=\"360\" y1=\"20\" x2=\"360\" y2=\"51.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"372\" y=\"35.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">24</text><line x1=\"360\" y1=\"86.3\" x2=\"360\" y2=\"117.5\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"372\" y=\"101.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">24</text><line x1=\"360\" y1=\"152.6\" x2=\"360\" y2=\"183.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"372\" y=\"168.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">24</text><text x=\"420\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Each article has a 24px margin and its</text><text x=\"420\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">h2 a 16px one. Between two articles the</text><text x=\"420\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">gap is 24, not 24 + 16 + 16 + 24:</text><text x=\"420\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">touching margins collapse to the largest.</text><text x=\"420\" y=\"193.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A pixel of padding separates the h2’s</text><text x=\"420\" y=\"211.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">margin from its article’s, and the box</text><text x=\"420\" y=\"229.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">grows to 61: 1 + 16 + 27 + 16 + 1.</text></svg>", "caption": "Vertical margins that touch become one margin, the larger of them."}
```

Read the first two articles. The first starts at y 24 and is 27 tall, so it ends at 51; the second starts at 75. **The gap is 24 pixels**, not the 24 + 24 you might add up, and not 24 + 16 + 16 + 24 counting the headings' margins as well. Every one of those margins was touching another, and they collapsed into a single 24, the largest.

There is a second collapse in the same numbers. The first article and its heading both start at y 24, and the article is exactly as tall as the heading, 27. **The heading's margin went through the article**: with nothing between the parent's top edge and the child's, the child's margin collapses with the parent's and ends up outside the parent.

The third article has `padding: 1px 0`, and that one pixel is enough to stop it. Now the heading's margins stay inside: the heading starts at 143, which is 126 + 1 + 16, and the article is **61** tall, 1 + 16 + 27 + 16 + 1. A border does the same, and so does making the article a flex or grid container, as lessons 8 and 9 will.

## When margins collapse, and when they do not

Only **vertical** margins collapse, and only between **block** boxes in the ordinary flow of the page. Horizontal margins never do. Margins of flex and grid items never do. Floated and absolutely positioned boxes, lesson 7, never do. It is a rule for text, and it was designed for text: a paragraph's margin and a heading's margin should not add up to a hole between them.

## `auto` margins

The fourth article has `width: 400px; margin: 0 auto`. A horizontal margin of `auto` takes whatever space is left, and two of them share it equally: (1024 − 400) / 2 = 312, which is where `probe` found it. That is how a block of fixed width is centred horizontally. A vertical `auto` margin, in ordinary flow, is 0; lesson 8 shows where it does more.
