---
title: Naming the parts: grid-template-areas
version: 1
---

Line numbers are precise and hard to read. For the large shape of a page, Grid offers something closer to a picture: **name each area, and draw the layout with the names**. Here is the bookshop's page shell:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
    <style>
      body {
        margin: 0;
        min-height: 100vh;
        display: grid;
        grid-template-columns: 220px 1fr;
        grid-template-rows: auto 1fr auto;
        grid-template-areas:
          "header header"
          "nav    main"
          "footer footer";
        gap: 16px;
      }
      header { grid-area: header; }
      nav    { grid-area: nav; }
      main   { grid-area: main; }
      footer { grid-area: footer; }
      body > * { background: #f4f1ea; }
    </style>
  </head>
  <body>
    <header><p>Andorinha Books</p></header>
    <nav aria-label="Main"><p>Events · Order a book · Opening hours</p></nav>
    <main><h1>This week</h1></main>
    <footer><p>Rua dos Pinheiros, 1000 · São Paulo</p></footer>
  </body>
</html>
```

`grid-template-areas` takes one string per row, with one name per column. `"header header"` says the header spans both columns of the first row; `"nav main"` puts the navigation in the first column and the main content in the second. Each element then joins its area with `grid-area: name`. The browser keeps the template exactly as written:

```
ana@laptop:~/site$ probe areas.html style body grid-template-areas box header box nav box main box footer
body  grid-template-areas: "header header" "nav main" "footer footer"
header  x 0      y 0      width 1024   height 50
nav  x 0      y 66     width 220    height 636
main  x 236    y 66     width 788    height 636
footer  x 0      y 718    width 1024   height 50
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 276\" role=\"img\" aria-label=\"On the left, grid-template-areas as written in the stylesheet: header header, nav main, footer footer, three rows of names. On the right, the page the browser made from it at 1024 by 768: a header across the top, nav and main side by side, a footer across the bottom, the same shape as the text.\"><rect x=\"20\" y=\"20\" width=\"300\" height=\"96\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;header header&quot;</text><text x=\"36\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;nav    main&quot;</text><text x=\"36\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;footer footer&quot;</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">grid-template-areas, as written</text><rect x=\"380\" y=\"20\" width=\"307.2\" height=\"15\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"533.6\" y=\"27.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">header</text><rect x=\"380\" y=\"39.8\" width=\"66\" height=\"190.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"413\" y=\"135.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">nav</text><rect x=\"450.8\" y=\"39.8\" width=\"236.4\" height=\"190.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"569\" y=\"135.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main</text><rect x=\"380\" y=\"235.4\" width=\"307.2\" height=\"15\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"533.6\" y=\"242.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">footer</text><text x=\"380\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what the browser made, 1024 × 768</text></svg>", "caption": "The template is a picture of the layout, written in text."}
```

The header and the footer are **1024 wide**, both columns. `nav` is **220**, the first column; `main` starts at **236**, after the 16-pixel gap, and is **788** wide, the `1fr`. The rows are `auto 1fr auto`, and the body is at least as tall as the window, so the header and the footer are as tall as their content and `main` takes the rest of the height, **636**: the footer at the bottom of the window, which lesson 8 did with a flex column, here falls out of the row sizes.

## The rules of the picture

- **Every row has the same number of names**, one per column.
- **An area must be a rectangle.** An L shape is refused, and the whole template is then ignored.
- **A dot, `.`, is an empty cell.** `"header header" ". main"` leaves the bottom left empty.
- The names line up with spaces only to make the picture readable; the browser ignores the alignment.

The great advantage is that **the layout can be redrawn without touching the HTML**: lesson 11 changes this template inside a media query so that on a phone the navigation goes above the content, one column, by rewriting three strings.
