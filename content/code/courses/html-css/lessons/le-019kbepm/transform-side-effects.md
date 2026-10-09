---
title: Two things a transform also does
version: 2
---

A transform does two other things that surprise people, and lesson 7 pointed at both.

## It becomes the containing block for fixed descendants

Lesson 7 section 06 said a `position: fixed` element is placed relative to the window. **Unless an ancestor has a transform**: then that ancestor becomes the containing block, and the "fixed" element moves with it. Here are two identical toasts, `position: fixed; bottom: 16px; right: 16px`, one in the page and one inside a panel with `transform: translateX(0)`, a transform that moves nothing. The page is `fixed.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0; }
      .page { height: 2000px; }
      .panel { transform: translateX(0); height: 300px; }
      .toast { position: fixed; bottom: 16px; right: 16px; width: 200px; height: 40px; }
    </style>
  </head>
  <body>
    <div class="page">
      <p class="toast outside">Saved</p>
      <div class="panel">
        <p class="toast inside">Saved</p>
      </div>
    </div>
  </body>
</html>
```

Measured before and after scrolling 600:

```
ana@laptop:~/site$ probe fixed.html box .toast scroll 600 box .toast
p.toast.outside  x 808    y 696    width 200    height 40
p.toast.inside   x 808    y 228    width 200    height 40
p.toast.outside  x 808    y 1296   width 200    height 40
p.toast.inside   x 808    y 228    width 200    height 40
```

Before scrolling, the toast outside is at y **696**, at the bottom of the window, and the one inside is at y **228**, at the bottom of the 300-pixel panel. After scrolling 600, the outside toast is at **1296**: still at the bottom of the window, as fixed promises. The inside toast is still at **228**, scrolled away with the page. A transform on any ancestor, even one that changes nothing visible, does this. When a fixed header or a modal stops being fixed, look for a transform, a `filter` or a `will-change: transform` above it.

## It creates a stacking context

Lesson 7 section 08 showed that a stacking context traps the `z-index` of everything inside it. A transform creates one. A card has a menu with `z-index: 100`, and the next card has `z-index: 1`. Here they are in `stack.html`, with the first card lifted by a 4-pixel `translateY`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0; }
      .card { position: relative; width: 300px; height: 120px; background: #f4f1ea; }
      .lifted { transform: translateY(-4px); }
      .menu { position: absolute; top: 80px; left: 20px; z-index: 100; width: 200px; height: 100px; background: #ffffff; }
      .next { position: relative; z-index: 1; width: 300px; height: 120px; background: #e6dfd0; }
    </style>
  </head>
  <body>
    <div class="card lifted">
      <p>Poetry reading</p>
      <div class="menu">Share · Save · Report</div>
    </div>
    <div class="next">Book swap</div>
  </body>
</html>
```

`flat.html` is a copy with `lifted` taken out of the first card's `class`. With the lift, and without:

```
ana@laptop:~/site$ probe stack.html top 100 140
at 100,140: div.next  "Book swap"
ana@laptop:~/site$ probe flat.html top 100 140
at 100,140: div.menu  "Share · Save · Report"
```

With the transform, the point where the menu hangs over the next card shows **the next card**: the menu's 100 only counts inside the lifted card's stacking context, and that whole context is drawn below a sibling with `z-index: 1`. Without the transform, the menu is on top. A hover effect that lifts a card can therefore hide its own dropdown under the card below, which is why the fix in lesson 7 applies here too: give the card that is open a higher `z-index` than its siblings, or move the menu out of it.
