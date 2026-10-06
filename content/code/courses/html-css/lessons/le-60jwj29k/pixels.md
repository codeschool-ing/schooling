---
title: Pixels: the CSS pixel and the device pixel
version: 1
---

`px` is the unit everyone starts with, and it hides a surprise: **a CSS pixel is not a pixel of your screen**. It is a unit of length that the browser maps onto the screen's real pixels, the **device pixels**, using the **device pixel ratio** that lesson 4 used to choose an image.

The same card, measured on a screen with a ratio of 1 and one with a ratio of 3:

```
ana@laptop:~/site$ probe --dpr 1 sizes.html window box .card
window: 1024×768, device pixel ratio 1
article.card  x 0      y 0      width 400    height 50
ana@laptop:~/site$ probe --dpr 3 sizes.html window box .card
window: 1024×768, device pixel ratio 3
article.card  x 0      y 0      width 400    height 50
```

The window is 1024 CSS pixels wide in both, and the card is **400 CSS pixels wide in both**. On the second screen, each CSS pixel is drawn with 3 device pixels across, so the card occupies 1200 of them and looks exactly as large to the reader, only sharper. That is the whole point of the unit: a 16-pixel font is roughly the same physical size on a laptop and on a phone held at reading distance, whatever the hardware.

The standard defines the reference pixel as the size of one pixel on a 96 dots-per-inch screen seen at arm's length, which is why the absolute units relate to it by fixed ratios: `1in` is `96px`, `1cm` is about `37.8px`, `1pt` is `1.333px`. Those units are for print stylesheets; on a screen, `px` is the absolute unit to use.

## When pixels are wrong

**Pixels are right for things that should not scale with the text**: a 1-pixel border, a 4-pixel shadow, the thickness of a line. They are **wrong for font sizes and for the spacing around text**, because a reader can ask their browser for bigger text and a size fixed in pixels is a size that refuses. The next section is the unit that does not refuse.
