---
title: Percentages: a share of what?
version: 1
---

A percentage is always a share of something, and the something depends on the property. Getting it wrong is how a layout ends up twice the height anybody expected. The rules worth knowing:

- **`width`**: a share of the **containing block's width**. For most elements the containing block is the parent; lesson 7 is about the exceptions.
- **`height`**: a share of the containing block's **height**, but only if that height is set; otherwise it is ignored.
- **`padding` and `margin`, on every side, including top and bottom**: a share of the containing block's **width**.
- **`font-size`**: a share of the parent's font size, like `em`.

The third rule is the one that surprises people. Here is a column 600 by 200 with a child at `width: 50%; padding-top: 10%; height: 50%`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Percentages · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .column { width: 600px; height: 200px; }
      .half { width: 50%; padding-top: 10%; height: 50%; }
    </style>
  </head>
  <body>
    <div class="column">
      <div class="half"></div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe percent.html box .half
div.half  x 0      y 0      width 300    height 160
```

The child is **300 wide**, half of 600. It is **160 tall**: 100 from `height: 50%`, half of the column's 200, plus **60** from `padding-top: 10%`. Ten per cent of the column's **width**, not of its height. The rule exists so that padding on all four sides is the same size when written as the same percentage, and before `aspect-ratio` existed it was the trick used to make a box keep its proportions: `padding-top: 56.25%` on an empty box made it 16:9 at any width. Section 11 shows the modern way.

## Percentages and the page

`width: 100%` on a block is usually unnecessary: a block already takes the full width of its container. And with `content-box`, `width: 100%` plus padding is wider than the container, which is one more reason for section 04's rule. Where percentages earn their place is in layouts where something should be a share of its container, and lessons 8 and 9 give better tools for most of those: the `fr` unit and `flex` share space more precisely than percentages, and without any arithmetic about borders.
