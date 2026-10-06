---
title: Choosing breakpoints from the content
version: 1
---

A **breakpoint** is a width at which a media query changes the layout. The tempting way to choose them is from a list of devices: 375 for this phone, 768 for that tablet. That list is out of date the year it is written, and there are hundreds of widths between the entries. **The content says where to break**: make the window slowly wider, and add a breakpoint where the layout starts to look wrong.

The most common thing that goes wrong as a window widens is not a layout at all. It is lines of text that get too long to read:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 0 auto; padding: 0 1rem; font-family: system-ui, sans-serif; }
      .capped { max-width: 65ch; }
    </style>
  </head>
  <body>
    <p class="free">Andorinha Books opened in 2009 in a former bakery on Rua dos Pinheiros. It sells new and second-hand books, runs a reading group on Thursday evenings, and on Saturdays turns its back room into a workshop for anybody who wants to learn to bind a book by hand.</p>
    <p class="capped">Andorinha Books opened in 2009 in a former bakery on Rua dos Pinheiros. It sells new and second-hand books, runs a reading group on Thursday evenings, and on Saturdays turns its back room into a workshop for anybody who wants to learn to bind a book by hand.</p>
  </body>
</html>
```

```
ana@laptop:~/site$ probe --width 1200 measure.html box p
p.free    x 16     y 16     width 1168   height 40
p.capped  x 16     y 72     width 656.09 height 80
```

The free paragraph is **1168** wide on a 1200 window, and the whole paragraph fits on two lines. A line that long is hard to read: at the end of one, the eye has trouble finding the start of the next. The capped paragraph has **`max-width: 65ch`**, and it is **656.09** wide on four lines. `ch` is the width of the zero in the element's font, so `65ch` holds roughly 65 to 75 characters of ordinary text, the length that books and the long-standing typographic advice settle on.

That needed no media query at all, which is the point to take away: **`max-width`, `flex-wrap`, `auto-fit` and `clamp()` adapt by themselves**, lessons 6, 8 and 9 and section 06 here, and every one of them is a breakpoint you did not have to choose. Media queries are for the changes those cannot make, such as moving a sidebar from beside the content to below it.

## How many

A typical site needs **two or three** breakpoints for its page shell, and its components may have one or two of their own. If you find yourself writing a query every hundred pixels, the layout is probably fighting its content, and a flexible track or a `minmax()` would do the job better.
