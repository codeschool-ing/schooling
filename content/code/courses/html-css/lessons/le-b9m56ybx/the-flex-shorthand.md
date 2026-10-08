---
title: The flex shorthand
version: 2
---

The three properties are almost always set together, with **`flex`**, and three values of it cover nearly everything:

| shorthand | means | does |
| --- | --- | --- |
| `flex: 1` | `1 1 0%` | grows from zero: items share all the space equally |
| `flex: auto` | `1 1 auto` | grows from its content: bigger content, bigger item |
| `flex: none` | `0 0 auto` | stays the size of its content, neither grows nor shrinks |

The first line is the one worth reading twice. Here are all three on the same three shelf names, in `shorthand.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>flex · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .row { display: flex; width: 600px; margin-bottom: 8px; background: #f4f1ea; }
      .row p { margin: 0; background: #2f6f4e; color: white; }
      .one p { flex: 1; }
      .auto p { flex: auto; }
      .none p { flex: none; }
    </style>
  </head>
  <body>
    <div class="row one"><p>Poetry</p><p>Fiction in Portuguese</p><p>Children</p></div>
    <div class="row auto"><p>Poetry</p><p>Fiction in Portuguese</p><p>Children</p></div>
    <div class="row none"><p>Poetry</p><p>Fiction in Portuguese</p><p>Children</p></div>
  </body>
</html>
```

The browser confirms what `flex: 1` means:

```
ana@laptop:~/site$ probe shorthand.html style '.one p:first-child' flex-grow,flex-shrink,flex-basis
p  flex-grow: 1
p  flex-shrink: 1
p  flex-basis: 0%
ana@laptop:~/site$ probe shorthand.html box '.one p' box '.auto p' box '.none p'
p  x 0      y 0      width 200    height 24
p  x 200    y 0      width 200    height 24
p  x 400    y 0      width 200    height 24
p  x 0      y 32     width 160.86 height 24
p  x 160.86 y 32     width 264.92 height 24
p  x 425.78 y 32     width 174.2  height 24
p  x 0      y 64     width 46.25  height 24
p  x 46.25  y 64     width 150.31 height 24
p  x 196.56 y 64     width 59.59  height 24
```

`flex: 1` sets the basis to **0%**, not to `auto`. Then the three rows of the same page, three items each with labels of different lengths: *Poetry*, *Fiction in Portuguese* and *Children*:

- With **`flex: 1`**, the three items are **200, 200 and 200**. Every basis is zero, so all 600 pixels are free space, shared in three equal shares, and the length of the text no longer matters.
- With **`flex: auto`**, they are **160.86, 264.92 and 174.2**. Each starts from its content's width, and the leftover is shared equally on top, so the longest label stays the widest.
- With **`flex: none`**, they are **46.25, 150.31 and 59.59**: exactly their content, and the rest of the row is empty.

**`flex: 1` is the one for equal columns**, the reason it is the most common value in real stylesheets. `flex: auto` is for items that should fill a row while keeping their proportions, such as the tabs of a menu. `flex: none` is for something that must not change size, such as an icon or the price in the last section.

Writing `flex` instead of the three longhands is also safer: `flex: 1` sets all three, whereas `flex-grow: 1` alone leaves the basis at `auto`, which is how somebody expecting equal columns gets the second row instead.
