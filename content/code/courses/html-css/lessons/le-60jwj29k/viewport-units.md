---
title: Viewport units
version: 1
---

Four units measure the browser window, the **viewport**, rather than any element: **`vw`** is one per cent of its width, **`vh`** one per cent of its height, and `vmin` and `vmax` are one per cent of the smaller or the larger of the two. A section that should fill the first screen is `min-height: 100vh`.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Viewport units · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .hero { height: 100vh; width: 100vw; }
      .tall { height: 2000px; }
    </style>
  </head>
  <body>
    <div class="hero"></div>
    <div class="tall"></div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe viewport.html window box .hero
window: 1024×768, device pixel ratio 1
div.hero  x 0      y 0      width 1024   height 768
ana@laptop:~/site$ probe --mobile --width 390 --height 844 viewport.html window box .hero
window: 390×844, device pixel ratio 1
div.hero  x 0      y 0      width 390    height 844
```

On a 1024 by 768 window, `100vw` by `100vh` is 1024 by 768. On a phone 390 wide by 844 tall, with the viewport tag from lesson 1, it is 390 by 844. Without that tag, lesson 1 showed, the phone pretends to be 980 wide, and `100vw` would be 980.

## The phone's toolbar

On a phone, the browser's address bar slides away as the reader scrolls and comes back when they scroll up, so the visible height changes while they read. `100vh` was defined as the **largest** of those heights, so a section of `100vh` is taller than the screen while the bar is showing, and its bottom is hidden under the bar. Three newer units say which height they mean: **`svh`**, the small viewport, with the bars showing; **`lvh`**, the large one, with them hidden; and **`dvh`**, the dynamic one, which follows the bar as it moves. `min-height: 100svh` is the safe choice for a first screen that must fit. The headless Chromium in this lab has no address bar to slide away, so it cannot show the difference; on a real phone the units differ by the height of the bar.

## The scrollbar

On a desktop with classic scrollbars, `100vw` includes the width of the vertical scrollbar, so an element of `width: 100vw` is a few pixels wider than the page and makes it scroll sideways. The headless Chromium in this lab draws no scrollbar, so the measurement above cannot show it, and you will see it on Windows and on most Linux desktops. **`width: 100%` is what to use for "the full width of the page"**; keep `vw` for things that really are a share of the window, such as a heading whose size grows with it, which lesson 11 builds with `clamp()`.
