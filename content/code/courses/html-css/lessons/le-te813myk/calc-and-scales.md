---
title: calc() and a scale of sizes
version: 1
---

**`calc()`** does arithmetic with CSS values, and it can mix units that the browser only resolves while laying out: `calc(100% - 15rem)` is "the container's width minus fifteen root ems", which no single unit can say. With variables, `calc()` turns one value into a **scale**:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>A scale · Andorinha Books</title>
    <style>
      :root {
        --space: 0.5rem;
        --space-2: calc(var(--space) * 2);
        --space-4: calc(var(--space) * 4);
        --sidebar: 15rem;
      }
      .card { padding: var(--space-2); margin-bottom: var(--space-4); }
      .main { width: calc(100% - var(--sidebar) - var(--space-4)); }
    </style>
  </head>
  <body>
    <article class="card">One card</article>
    <div class="main">The main column</div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe scale.html style :root --space-2,--space-4 style .card padding-top,margin-bottom box .main
html  --space-2: calc(0.5rem * 2)
html  --space-4: calc(0.5rem * 4)
article.card  padding-top: 16px
article.card  margin-bottom: 32px
div.main  x 8      y 90     width 736    height 18
```

Two things in that output are worth reading. The card's padding is **16px** and its margin **32px**: `--space` is half a rem, and the scale doubles and quadruples it. Change `--space` and every size in the scale moves together, in proportion.

**The custom properties themselves were stored unevaluated**: `--space-2` is `calc(0.5rem * 2)`, not `1rem` and not `16px`. That is the behaviour section 05 was about, from the other side. A custom property holds the text it was given, with any `var()` inside it substituted, and the arithmetic only happens where it is finally used, in `padding`, where the browser knows it is a length. It also means a variable defined with `em` is resolved against the font size of the element that **uses** it, not the one that declared it.

The main column's width is `calc(100% - var(--sidebar) - var(--space-4))`, and it came out **736**: 1008 minus 240 minus 32. A `calc()` like that is how layouts were made before Grid; with Grid, lesson 9, `1fr` does it without arithmetic, and `calc()` stays useful for everything that is not a layout track.

## The operators

`+` and `-` need spaces on both sides: `calc(100% -1rem)` is invalid, because `-1rem` reads as a negative number. `*` and `/` do not, and one side of each must be a plain number. `min()`, `max()` and `clamp()` are calc's relatives: they pick the smaller, the larger, or a value between two limits, and lesson 11 builds fluid type with `clamp()`.
