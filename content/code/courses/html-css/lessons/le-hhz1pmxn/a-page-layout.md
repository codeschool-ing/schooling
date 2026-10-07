---
title: The bookshop's home page in Grid
version: 1
---

Everything in this lesson, in one page: the shell from section 06, with an aside instead of a navigation column, and the events from section 04 as an `auto-fit` grid inside `main`. Grid outside, Grid inside, and nothing positioned.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="home.css">
  </head>
  <body>
    <header class="site-header"><p>Andorinha Books</p></header>
    <main>
      <h1>This week</h1>
      <div class="cards">
        <article><h2>Poetry reading</h2><p>Thursday, 7 pm.</p></article>
        <article><h2>Book swap</h2><p>Saturday, from 10 am.</p></article>
        <article><h2>Bookbinding</h2><p>Saturday, 2 pm.</p></article>
        <article><h2>New arrivals</h2><p>Forty paperbacks.</p></article>
      </div>
    </main>
    <aside><h2>Opening hours</h2><p>10 am to 7 pm.</p></aside>
    <footer><p>Rua dos Pinheiros, 1000 · São Paulo</p></footer>
  </body>
</html>
```

```css
*, *::before, *::after { box-sizing: border-box; }

body {
  margin: 0;
  display: grid;
  grid-template-columns: 1fr 240px;
  grid-template-areas:
    "header header"
    "main   aside"
    "footer footer";
  gap: 24px;
  max-width: 1100px;
  padding: 0 16px;
  margin-inline: auto;
}
.site-header { grid-area: header; }
main         { grid-area: main; }
aside        { grid-area: aside; }
footer       { grid-area: footer; }

.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}
.cards article { padding: 16px; background: #f4f1ea; }
```

```
ana@laptop:~/site$ probe home.html box main box aside style .cards grid-template-columns
main  x 16     y 74     width 728    height 361.5
aside  x 768    y 74     width 240    height 361.5
div.cards  grid-template-columns: 232px 232px 232px
ana@laptop:~/site$ probe --width 700 home.html box main box aside style .cards grid-template-columns
main  x 16     y 74     width 404    height 659.13
aside  x 444    y 74     width 240    height 659.13
div.cards  grid-template-columns: 404px
```

On the 1024 window, `main` is **728** wide and the aside **240**: the `1fr` and the fixed column, inside a body limited to 1100 and padded by 16 on each side. The event cards made three columns of **232**, so the fourth card wraps to a second row. That is `auto-fit` at work: three tracks of at least 220 fit in 728, four would not.

On a window 700 wide, `main` shrinks to **404**, and the cards made **one column**, 404 wide. The aside is still **240** beside it, taking more than a third of a small screen for a box of opening hours. Nothing in this stylesheet knows that a narrow window wants a different shape for the page: the cards adapted by themselves, the shell did not. Changing the shell at a width is what a **media query** does, and that, and the decision about at which width to do it, is lesson 11.

## What the page does not use

No floats, no absolute positioning, no percentages, and no fixed widths except the aside's column and the page's maximum. `margin-inline: auto` centres the body in wide windows, the logical-property spelling of lesson 6's `margin: 0 auto`: `inline` means the direction text runs in. The layout is two grids and a `gap`, and it is readable as a picture in the template.
