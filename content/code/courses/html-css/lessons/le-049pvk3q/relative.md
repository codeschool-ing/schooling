---
title: relative: moved, with its space kept
version: 1
---

**`position: relative`** draws a box shifted from where the normal flow put it, by the amounts in `top`, `left`, `bottom` and `right`, **and leaves its space in the flow exactly where it was**. Here are three cards, the middle one moved:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Relative · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .card { width: 300px; height: 60px; margin: 20px; background: #f4f1ea; }
      .nudged { position: relative; top: 10px; left: 40px; }
    </style>
  </head>
  <body>
    <div class="card one">One</div>
    <div class="card two nudged">Two</div>
    <div class="card three">Three</div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe relative.html box .card
div.card.one         x 20     y 20     width 300    height 60
div.card.two.nudged  x 60     y 110    width 300    height 60
div.card.three       x 20     y 180    width 300    height 60
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three cards from relative.html at their measured positions. One at x 20, y 20. Two is drawn at x 60, y 110, shifted 40 right and 10 down from a dashed outline at x 20, y 100, where it would have been. Three is at x 20, y 180, exactly where it would be if Two had not moved: the space Two left behind is kept.\"><rect x=\"38\" y=\"34\" width=\"270\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">One  x 20, y 20</text><rect x=\"38\" y=\"106\" width=\"270\" height=\"54\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"50\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">where Two would be</text><rect x=\"74\" y=\"115\" width=\"270\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"86\" y=\"149\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Two  x 60, y 110</text><rect x=\"38\" y=\"178\" width=\"270\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Three  x 20, y 180</text><text x=\"400\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">top: 10px; left: 40px moved Two</text><text x=\"400\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">from where it would have been,</text><text x=\"400\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">and nothing else moved.</text><text x=\"400\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Three is where it would be if</text><text x=\"400\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Two had not moved: the space</text><text x=\"400\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Two left behind is kept.</text></svg>", "caption": "position: relative moves the drawing and leaves the space where it was."}
```

Card two would have been at x 20, y 100: 20 pixels of margin below card one, which ends at 80. `top: 10px; left: 40px` drew it at **x 60, y 110**, 40 to the right and 10 down. **Card three is at y 180, where it would have been anyway**: 100 + 60 + 20. The flow still believes card two is at 100, so nothing else moved, and card two now overlaps card three by 10 pixels.

`top: 10px` means "10 pixels down from the top of where you would be", which reads backwards at first: the inset says which edge the offset is measured from, and a positive value moves away from that edge, into the box's space.

## What relative is really used for

Nudging boxes by a few pixels is rarely what `relative` is for: overlapping its neighbour, as card two does, is usually a bug. **Its real use is to be a reference for absolutely positioned children.** A box with `position: relative` and no offsets at all stays exactly where it is, and becomes the box its absolute children are measured from. That is the next two sections, and it is why you will write `position: relative` with no `top` or `left` far more often than with them.
