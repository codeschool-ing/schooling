---
title: absolute: out of the flow, placed against an ancestor
version: 1
---

**`position: absolute`** takes a box out of the normal flow altogether: it takes up no space, the boxes around it close up as if it were not there, and its insets place it against its **containing block**. Here are two event cards, each with a small badge meant for its top right corner:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Absolute · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .card { width: 300px; padding: 16px; margin: 40px; background: #f4f1ea; }
      .anchored { position: relative; }
      .badge {
        position: absolute;
        top: -10px;
        right: -10px;
        padding: 2px 8px;
        background: #8a1c1c;
        color: white;
      }
    </style>
  </head>
  <body>
    <article class="card anchored">
      <h2>Book swap</h2>
      <p>Saturday 10 October, from 10 am.</p>
      <span class="badge">New</span>
    </article>
    <article class="card">
      <h2>Poetry reading</h2>
      <p>Thursday 8 October, 7 pm.</p>
      <span class="badge">Free</span>
    </article>
  </body>
</html>
```

```
ana@laptop:~/site$ probe absolute.html box .card box .badge
article.card.anchored  x 40     y 40     width 332    height 147.81
article.card           x 40     y 227.81 width 332    height 147.81
span.badge  x 333.98 y 30     width 48.02  height 28
span.badge  x 985.09 y -10    width 48.91  height 28
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two cards on the page, drawn from measured boxes at 60 per cent. The first card has position: relative, and its badge New sits at its top right corner, 10 pixels outside it. The second card has no position, so its badge Free was positioned against the page instead: at x 985.09, y -10, in the page&#x27;s top right corner and half above the top.\"><path d=\"M20 30 h614.4 v240 h-614.4 z\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></path><text x=\"626.4\" y=\"258\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the page</text><path d=\"M44 54 h199.2 v88.69 h-199.2 z\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"54\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.card.anchored</text><text x=\"54\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">position: relative</text><rect x=\"220.39\" y=\"48\" width=\"28.81\" height=\"16.8\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"234.79\" y=\"56.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">New</text><rect x=\"44\" y=\"166.69\" width=\"199.2\" height=\"88.69\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"188.69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.card</text><text x=\"54\" y=\"206.69\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no position</text><rect x=\"611.05\" y=\"24\" width=\"29.35\" height=\"16.8\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"625.73\" y=\"32.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Free</text><text x=\"356\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">top: -10px; right: -10px</text><text x=\"356\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">New is measured from its card,</text><text x=\"356\" y=\"135.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">which is positioned.</text><text x=\"356\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Free found no positioned</text><text x=\"356\" y=\"177.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ancestor and went to the page:</text><text x=\"356\" y=\"193.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">x 985.09, y -10, half off it.</text></svg>", "caption": "An absolute box is placed against its nearest positioned ancestor, and against the page when there is none."}
```

**The first badge is where it was meant to be.** Its card ends at x 372 and y 40, and the badge's right edge is at 382 and its top at 30: `top: -10px` and `right: -10px` put it 10 pixels outside the card's top right corner. The card has `position: relative`, and that is what made it the badge's containing block.

**The second badge flew to the corner of the page.** Its card has no `position`, so the badge looked further up the tree for an ancestor with one, found none, and was placed against the page itself: its right edge 10 pixels past the right of the page, at x 985.09 + 48.91 = 1034, and its top at **y -10**, ten pixels above the top of the page, where part of it cannot be seen at all. Nothing broke and no error was reported; the badge simply went to the only reference it could find.

## What absolute does to the flow

The badge takes no space, which is what a badge needs: the card's height, 147.81, is the heading and the paragraph, and adding or removing the badge changes nothing about it. The other side of that is that **an absolute box cannot push anything out of its way**, and nothing makes room for it. A badge with a longer word grows over the heading below it. Absolute positioning is right for small things laid on top of something whose size does not depend on them.

An absolute box with no width shrinks to fit its content, as the badges did, instead of stretching across its container the way a block in the flow would. And its margins never collapse with anything's, lesson 6 section 05.
