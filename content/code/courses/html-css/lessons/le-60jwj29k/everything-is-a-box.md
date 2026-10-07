---
title: Content, padding, border and margin
version: 1
---

To a browser laying out a page, **every element is a rectangle**, and every rectangle has four layers, from the inside out: the **content**, the **padding** around it, the **border** around that, and the **margin** outside the border. A paragraph, a link, a heading, an image: all of them, even the round ones, which are rectangles drawn with rounded corners.

Here is an event card with a value for each layer:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>A card · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .card {
        width: 300px;
        padding: 20px;
        border: 4px solid #2f6f4e;
        margin: 30px;
      }
      .card p { margin: 0; }
    </style>
  </head>
  <body>
    <article class="card">
      <p>Poetry reading: Hilda Hilst. Thursday 8 October, 7 pm.</p>
    </article>
  </body>
</html>
```

And its box, measured:

```
ana@laptop:~/site$ probe box.html box .card box '.card p'
article.card  x 30     y 30     width 348    height 84
p  x 54     y 54     width 300    height 36
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 282\" role=\"img\" aria-label=\"The box model of the card in box.html, from the inside out. The content area is 300 by 36. Around it, 20 pixels of padding; around that, a 4-pixel border; around that, 30 pixels of margin, drawn dashed because it is outside the box. probe reported the box as 348 by 84, which is content, padding and border: 300 plus 20 plus 20 plus 4 plus 4 is 348.\"><rect x=\"20\" y=\"20\" width=\"440\" height=\"250\" rx=\"0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"60\" y=\"56\" width=\"360\" height=\"178\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"6\"></rect><rect x=\"90\" y=\"86\" width=\"300\" height=\"118\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"240\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">content</text><text x=\"240\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">300 × 36</text><text x=\"240\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">padding 20</text><text x=\"240\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">padding 20</text><text x=\"240\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">margin 30</text><text x=\"240\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">margin 30</text><text x=\"330\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">border 4</text><text x=\"498\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">The four areas of .card,</text><text x=\"498\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">from the inside out:</text><text x=\"498\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">content, padding, border,</text><text x=\"498\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">margin.</text><text x=\"498\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">probe printed the box as</text><text x=\"498\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">348 × 84: the border box,</text><text x=\"498\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">which is content, padding</text><text x=\"498\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and border, but not margin.</text><text x=\"498\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">300 + 20 + 20 + 4 + 4 = 348</text></svg>", "caption": "width: 300px set the content area only, which is the default, content-box."}
```

The paragraph inside, which is the card's content, is **300 by 36**: the `width` set, and the height of two lines of text. The card itself is **348 by 84**. That is the content plus 20 pixels of padding on each side and 4 pixels of border on each side: 300 + 40 + 8 = 348 across, and 36 + 40 + 8 = 84 down. What `probe box` prints, and what DevTools highlights when you hover, is the **border box**: content, padding and border. The margin is outside it, which is why the card starts at x 30 and y 30.

## What each layer is for

**Padding** is space inside the box: the background colour fills it, and clicking it clicks the element. **Border** is the line around the padding, with a width, a style and a colour: `4px solid #2f6f4e`. **Margin** is space outside the box: always transparent, never clickable, and the gap between this element and its neighbours.

Each of the three takes one to four values, going clockwise from the top: `padding: 20px` is all four sides, `padding: 10px 20px` is top and bottom 10, left and right 20, and `padding: 5px 10px 15px 20px` is top, right, bottom, left. Every side can also be set on its own, `padding-left: 20px`. DevTools draws the four layers as nested rectangles in the **Computed** pane with the number for each side, which is the quickest way to read where a gap comes from.

## The space under images, removed on purpose

Lesson 1 measured a `<div>` 4 pixels taller than the image inside it, and promised this lesson would remove the space on purpose. The reason is in the next section: an image is inline by default and sits on the line of text like a letter does.
