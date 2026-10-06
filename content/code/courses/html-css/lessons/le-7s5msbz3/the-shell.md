---
title: Redrawing the page shell at two widths
version: 1
---

Lesson 9 section 11 left a page with a problem: on a window 700 wide, the 240-pixel aside stayed beside the content and took a third of the screen. Lesson 9 section 06 promised the fix, rewriting `grid-template-areas` inside a media query. Here is the shell rewritten mobile first, with a navigation added:

```css
*, *::before, *::after { box-sizing: border-box; }

/* Phones: one column, in the order of the HTML. */
body {
  margin: 0 auto;
  max-width: 1100px;
  padding: 0 16px;
  display: grid;
  grid-template-areas:
    "header"
    "nav"
    "main"
    "aside"
    "footer";
  gap: 24px;
}
.site-header { grid-area: header; }
nav          { grid-area: nav; }
main         { grid-area: main; }
aside        { grid-area: aside; }
footer       { grid-area: footer; }

/* Room for the opening hours beside the content. */
@media (width >= 48rem) {
  body {
    grid-template-columns: 1fr 240px;
    grid-template-areas:
      "header header"
      "nav    nav"
      "main   aside"
      "footer footer";
  }
}

/* Room for the navigation as a column of its own. */
@media (width >= 64rem) {
  body {
    grid-template-columns: 180px 1fr 240px;
    grid-template-areas:
      "header header header"
      "nav    main   aside"
      "footer footer footer";
  }
}

.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}
.cards article { padding: 16px; background: #f4f1ea; }
```

The base is one column, five areas stacked in the order of the HTML. At **48rem**, 768 pixels, the aside moves beside `main`. At **64rem**, 1024, the navigation becomes a column of its own on the left. Each step only rewrites the template strings and the columns; the five `grid-area` lines are written once:

```
ana@laptop:~/site$ probe --width 700 shell.html box "body > *"
header.site-header  x 16     y 0      width 668    height 50
nav                 x 16     y 74     width 668    height 50
main                x 16     y 148    width 668    height 361.5
aside               x 16     y 533.5  width 668    height 100.81
footer              x 16     y 658.31 width 668    height 50
ana@laptop:~/site$ probe --width 800 shell.html box "body > *"
header.site-header  x 16     y 0      width 768    height 50
nav                 x 16     y 74     width 768    height 50
main                x 16     y 148    width 504    height 361.5
aside               x 544    y 148    width 240    height 361.5
footer              x 16     y 533.5  width 768    height 50
ana@laptop:~/site$ probe --width 1200 shell.html box "body > *"
header.site-header  x 66     y 0      width 1068   height 50
nav                 x 66     y 74     width 180    height 361.5
main                x 270    y 74     width 600    height 361.5
aside               x 894    y 74     width 240    height 361.5
footer              x 66     y 459.5  width 1068   height 50
```

At **700**, everything is one column **668** wide, and the aside is below `main` at y 533.5: the problem from lesson 9 is gone. At **800** the aside is beside `main`, 240 wide, and the navigation runs across above both. At **1200** there are three columns, 180, 600 and 240, and the body stopped at its `max-width` of 1100 and centred itself at x 66.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 204\" role=\"img\" aria-label=\"The page shell of shell.html at three window widths, drawn from measured boxes. At 700, one column: header, nav, main, aside and footer stacked, each 668 wide. At 800, the aside is 240 wide beside main, with the nav across the top. At 1200, three columns: nav 180, main 600 and aside 240, between a header and a footer 1068 wide.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">700 wide</text><rect x=\"20\" y=\"30\" width=\"140\" height=\"145.6\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"23.2\" y=\"30\" width=\"133.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">header</text><rect x=\"23.2\" y=\"44.8\" width=\"133.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">nav</text><rect x=\"23.2\" y=\"59.6\" width=\"133.6\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"95.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main</text><rect x=\"23.2\" y=\"136.7\" width=\"133.6\" height=\"20.16\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"146.78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aside</text><rect x=\"23.2\" y=\"161.66\" width=\"133.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"166.66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">footer</text><text x=\"180\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">800 wide</text><rect x=\"180\" y=\"30\" width=\"160\" height=\"120.7\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"183.2\" y=\"30\" width=\"153.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"260\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">header</text><rect x=\"183.2\" y=\"44.8\" width=\"153.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"260\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">nav</text><rect x=\"183.2\" y=\"59.6\" width=\"100.8\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"233.6\" y=\"95.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main</text><rect x=\"288.8\" y=\"59.6\" width=\"48\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"312.8\" y=\"95.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aside</text><rect x=\"183.2\" y=\"136.7\" width=\"153.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"260\" y=\"141.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">footer</text><text x=\"360\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">1200 wide</text><rect x=\"360\" y=\"30\" width=\"240\" height=\"105.9\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"373.2\" y=\"30\" width=\"213.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">header</text><rect x=\"373.2\" y=\"44.8\" width=\"36\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"391.2\" y=\"80.95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nav</text><rect x=\"414\" y=\"44.8\" width=\"120\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"474\" y=\"80.95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main</text><rect x=\"538.8\" y=\"44.8\" width=\"48\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"562.8\" y=\"80.95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aside</text><rect x=\"373.2\" y=\"121.9\" width=\"213.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"126.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">footer</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">The aside goes below main at 700 and beside it at 800; the nav becomes a column only at 1200.</text></svg>", "caption": "One HTML document and three layouts: each media query only rewrites the template and the columns."}
```

## The order did not move

At every width, the order of the HTML is header, nav, main, aside, footer, and so is the order a keyboard or a screen reader goes through. The layouts only moved things **across**, never moved something visually before what comes ahead of it in the source. That is the rule from lesson 9 section 10, and it is why the narrow layout is the HTML order: if the phone layout needs the order changed, the HTML is in the wrong order.

The cards inside `main` were not mentioned in any query. They are lesson 9's `auto-fit` grid, and they made as many columns as fitted in whatever width `main` had at each step.
