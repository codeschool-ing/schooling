---
title: Aligning inside the cells
version: 1
---

Grid items are placed in cells, and an item smaller than its cell can sit anywhere inside it. Grid uses the alignment properties of Flexbox and adds the one Flexbox does not have:

| property | on | aligns | axis |
| --- | --- | --- | --- |
| `justify-items` | container | every item in its cell | inline, horizontal |
| `align-items` | container | every item in its cell | block, vertical |
| `justify-self` | item | that item | horizontal |
| `align-self` | item | that item | vertical |
| `justify-content` | container | the whole grid in the container | horizontal |
| `align-content` | container | the whole grid in the container | vertical |

The default for items is `stretch`: an item fills its cell, which is why grid items are as wide and as tall as their tracks without asking. Here are labels in cells 200 wide and 120 tall, with `justify-items: center` and `align-items: end`, and one label that overrides both:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Alignment · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .labels {
        display: grid;
        grid-template-columns: repeat(3, 200px);
        grid-auto-rows: 120px;
        gap: 10px;
        justify-items: center;
        align-items: end;
        background: #f4f1ea;
      }
      .labels span { padding: 4px 8px; background: #2f6f4e; color: white; }
      .labels .full { justify-self: stretch; align-self: start; }
      .centred { display: grid; place-items: center; height: 200px; background: #f4f1ea; }
    </style>
  </head>
  <body>
    <div class="labels">
      <span>Poetry</span>
      <span>Fiction</span>
      <span class="full">Children</span>
    </div>
    <div class="centred"><p>Nothing in your basket yet.</p></div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe align.html box '.labels span' box '.centred p'
span       x 68.88  y 88     width 62.25  height 32
span       x 278.44 y 88     width 63.13  height 32
span.full  x 420    y 0      width 200    height 32
p  x 417.28 y 208    width 189.44 height 24
```

*Poetry* and *Fiction* are each centred in their 200-pixel cell, at x 68.88 and 278.44, and sit at the bottom: y **88**, which is 120 minus their height of 32. *Children* has `justify-self: stretch` and `align-self: start`: it fills its cell's width, **200**, and sits at the top, y 0.

## `place-items: center`

`place-items` is shorthand for `align-items` and `justify-items` together, and **`place-items: center` on a grid container centres its content in both directions**: the empty-basket message from lesson 8, here with one declaration instead of two. The paragraph is at y **208**: its box sits 88 pixels into the 200-pixel container, which starts at 120. It is now the shortest way to centre anything in CSS.

`justify-content` and `align-content` only matter when the tracks add up to less than the container, for instance columns of fixed width in a wider page; then they place the whole grid, `center` or `space-between`, exactly as in Flexbox.
