---
title: Width and height: keeping the space
version: 1
---

You have met this as a reader: you start reading a paragraph, a picture above it finishes loading, and the paragraph jumps down the screen. It is called **layout shift**, and it happens because the browser did not know how tall the picture would be until the file arrived. The cure is two attributes that tell it in advance.

Here are two pictures of the same file, one with `width` and `height` and one without, each followed by a paragraph:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>The shop · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>The shop</h1>
      <img class="sized" src="shelves-480.png" width="480" height="320" alt="The fiction shelves">
      <p class="after-sized">Fiction is at the front.</p>
      <img class="unsized" src="shelves-480.png" alt="The poetry corner">
      <p class="after-unsized">Poetry is at the back.</p>
    </main>
  </body>
</html>
```

`probe --hold-images` keeps every image request waiting until the `release` step, so the page can be measured at the moment a slow connection would show it, and again once the pictures are in:

```
ana@laptop:~/site$ probe --hold-images shift.html box img box p release box img box p
img.sized    x 8      y 79.88  width 480    height 320
img.unsized  x 8      y 467.88 width 0      height 0
p.after-sized    x 8      y 419.88 width 1008   height 18
p.after-unsized  x 8      y 487.88 width 1008   height 18
img.sized    x 8      y 79.88  width 480    height 320
img.unsized  x 8      y 453.88 width 480    height 320
p.after-sized    x 8      y 419.88 width 1008   height 18
p.after-unsized  x 8      y 793.88 width 1008   height 18
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 334\" role=\"img\" aria-label=\"Two snapshots of shift.html, drawn from the boxes probe measured, not to scale. Before the pictures arrive, the image with width and height already takes 320 pixels, and the unsized image is 0 pixels tall with its paragraph at y 487.88. After they arrive, the unsized image is 320 tall and its paragraph has moved to y 793.88, 306 pixels further down. The paragraph under the sized image did not move.\"><text x=\"150\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">before the pictures arrive</text><rect x=\"20\" y=\"30\" width=\"260\" height=\"290\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"30\" y=\"44\" width=\"144\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"102\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">img.sized</text><text x=\"182\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">320</text><rect x=\"30\" y=\"148\" width=\"240\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">p.after-sized  y 419.88</text><line x1=\"30\" y1=\"179\" x2=\"174\" y2=\"179\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"182\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">img.unsized: 0</text><rect x=\"30\" y=\"188\" width=\"240\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">p.after-unsized  y 487.88</text><text x=\"420\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">after</text><rect x=\"290\" y=\"30\" width=\"260\" height=\"290\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"300\" y=\"44\" width=\"144\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"372\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">img.sized</text><text x=\"452\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">320</text><rect x=\"300\" y=\"148\" width=\"240\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">p.after-sized  y 419.88</text><rect x=\"300\" y=\"178\" width=\"144\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"372\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">img.unsized</text><text x=\"452\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">320</text><rect x=\"300\" y=\"282\" width=\"240\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">p.after-unsized  y 793.88</text><text x=\"566\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">The sized one kept</text><text x=\"566\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">its 320 pixels from</text><text x=\"566\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the start, so nothing</text><text x=\"566\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">after it moved.</text><text x=\"566\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The unsized one was</text><text x=\"566\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0 tall, then 320: the</text><text x=\"566\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">paragraph under it</text><text x=\"566\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">jumped 306 pixels.</text></svg>", "caption": "Width and height let the browser keep the space before it has the file."}
```

Before the files arrive, the sized picture already occupies **320 pixels**, the height its attributes promised, and its paragraph sits below that space. The unsized picture is **0 by 0**: the browser had no idea. After the release, the sized picture is unchanged and so is everything after it. The unsized one became 320 tall and pushed its paragraph from y 487.88 to **793.88, 306 pixels further down**. Somebody reading or about to tap that paragraph had it moved out from under them.

## What the two numbers are for

`width` and `height` are the image's size in pixels, written as plain numbers without units. The browser uses them for two things: the size to draw if CSS says nothing else, and **the proportion of the image**, 480 to 320 here, so that it can reserve the right height even when CSS makes the picture narrower. That second use is what makes them still worth writing in responsive layouts, where CSS sets `width: 100%; height: auto;`, as the next section's page does: the browser computes the height from the width it gets and the ratio the attributes gave it, before a byte of the file has arrived.

Lesson 6 introduces `aspect-ratio`, the CSS property that does the same job for any box. For images, the attributes in the HTML are enough and are the habit to keep. Google's **Cumulative Layout Shift** score, one of the measurements `front-performance` works with, adds up exactly these jumps.
