---
title: inset, and a box centred over the page
version: 1
---

**`inset`** is shorthand for the four inset properties, in the same clockwise order as `margin`: `inset: 0` is `top: 0; right: 0; bottom: 0; left: 0`, and `inset: 10px 20px` is 10 at the top and bottom and 20 at the sides.

Setting **opposite insets** on the same box does something useful: an absolute or fixed box with `left: 0; right: 0` and no width stretches between them, and one with `inset: 0` fills its containing block completely. That is how an overlay covering the whole window is made:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Overlay · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .overlay {
        position: fixed;
        inset: 0;
        background: rgb(0 0 0 / 0.5);
      }
      .notice {
        position: absolute;
        inset: 0;
        margin: auto;
        width: 300px;
        height: 200px;
        padding: 16px;
        box-sizing: border-box;
        background: white;
      }
    </style>
  </head>
  <body>
    <main><h1>Events</h1></main>
    <div class="overlay">
      <div class="notice">
        <p>The shop is closed on 12 October for a public holiday.</p>
      </div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe overlay.html box .overlay box .notice
div.overlay  x 0      y 0      width 1024   height 768
div.notice  x 362    y 284    width 300    height 200
ana@laptop:~/site$ probe --width 390 --height 844 overlay.html box .notice
div.notice  x 45     y 322    width 300    height 200
```

The overlay is **1024 by 768**, the whole window, from `position: fixed; inset: 0` and no size at all. Inside it the notice is centred, and the technique is worth reading closely: `position: absolute; inset: 0` says "stretch to all four edges", a fixed `width` and `height` say "but this big", and **`margin: auto`** shares the leftover space equally on all four sides, the vertical as well as the horizontal, which ordinary flow never does. The notice is at **x 362, y 284**, which is (1024 − 300) / 2 and (768 − 200) / 2. On a window 390 by 844 it is at x 45, y 322: centred again, with no change to the CSS.

Lesson 8 centres things in a container more simply, with Flexbox. This technique is for a box laid over everything, where there is no container to centre it in.

## An overlay that is a dialog

A notice that the reader must deal with before going on is a **dialog**, and HTML has an element for it, `<dialog>`, which brings what this CSS does not: the browser moves focus into it, keeps Tab inside it, closes it with Escape, and makes the page behind it inert. Its `::backdrop` pseudo-element is the dimmed layer, so even the overlay is built in. Opening it needs one line of JavaScript, `showModal()`, which is the `javascript` course's to teach. For anything that interrupts the reader, use the element; the CSS above is the shape it draws.
