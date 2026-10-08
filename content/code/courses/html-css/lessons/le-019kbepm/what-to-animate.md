---
title: What is cheap to animate
version: 2
---

Lesson 10 of `web-fundamentals` described the browser's work for each frame: **style**, then **layout**, then **paint**, then **compositing** the painted layers together. An animation runs that work up to sixty times a second, and how much of it each frame needs depends on the property being animated. Two dots slide 200 pixels back and forth, one by animating `margin-left`, one by animating `transform: translateX()`. The first is `cost-margin.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      .dot { width: 24px; height: 24px; background: #8a1c1c;
             animation: by-margin 1s linear infinite alternate; }
      @keyframes by-margin { to { margin-left: 200px; } }
    </style>
  </head>
  <body>
    <div class="dot"></div>
  </body>
</html>
```

`cost-transform.html` is a copy with the animation renamed and its one keyframe moving by `transform` instead: `animation: by-transform 1s linear infinite alternate;` and `@keyframes by-transform { to { transform: translateX(200px); } }`. The new step **`frames`** lets each page run for a second and reads Chromium's own counters:

```
ana@laptop:~/site$ probe cost-margin.html frames 1000
in 1000 ms: 62 layouts, 62 style recalculations
ana@laptop:~/site$ probe cost-transform.html frames 1000
in 1000 ms: 0 layouts, 1 style recalculations
```

`margin-left`: **62 layouts and 62 style recalculations** in one second, about one of each per frame. Every frame, the browser recalculated the dot's style, laid out the page again to find where the dot and everything after it go, and painted. `transform`: **0 layouts and 1 style recalculation**, the one at the start. The browser handed the animation to its **compositor**, which moves an already painted layer every frame without asking the main thread anything.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 196\" role=\"img\" aria-label=\"The four stages of the browser&#x27;s work for a frame: style, layout, paint and composite. Animating margin-left runs all four every frame, and the capture counted 62 layouts and 62 style recalculations in a second. Animating transform runs only compositing each frame, with 0 layouts and 1 style recalculation at the start.\"><rect x=\"150\" y=\"14\" width=\"116\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">style</text><rect x=\"290\" y=\"14\" width=\"116\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"348\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">layout</text><rect x=\"430\" y=\"14\" width=\"116\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"488\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">paint</text><rect x=\"570\" y=\"14\" width=\"116\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"628\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">composite</text><text x=\"20\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">margin-left</text><rect x=\"150\" y=\"64\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"290\" y=\"64\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"430\" y=\"64\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"570\" y=\"64\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"150\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">every frame: 62 layouts and 62 style recalculations in one second</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">transform</text><rect x=\"150\" y=\"134\" width=\"116\" height=\"24\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"290\" y=\"134\" width=\"116\" height=\"24\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"430\" y=\"134\" width=\"116\" height=\"24\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"570\" y=\"134\" width=\"116\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"150\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">every frame: compositing only; 0 layouts, 1 style recalculation at the start</text></svg>", "caption": "Which stages each frame needs depends on the property being animated."}
```

On this page one dot is cheap either way. On a real page, a layout per frame means every box on the page is reconsidered sixty times a second, on the same thread that runs the page's JavaScript, and on a phone that is where an animation starts to stutter.

## The short list

**`transform` and `opacity` are the two properties a browser can animate on the compositor**, along with `filter` in most cases. Movement, scaling and rotation should be transforms; appearing and disappearing should be opacity. `width`, `height`, `margin`, `top` and `left` cause layout; `color`, `background-color` and `box-shadow` cause paint, which is cheaper than layout and still work every frame. For a short hover on one button none of this matters. For something that runs all the time, or moves something large, it does.

**`will-change: transform`** tells the browser in advance that an element will be transformed, so it can promote it to its own layer before the animation starts. Use it on the few elements that need it, and only when there is a measured problem: every layer costs memory, and as section 04 showed, it also makes the element a containing block and a stacking context.
