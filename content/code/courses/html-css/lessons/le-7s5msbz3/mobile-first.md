---
title: Mobile first: the narrow layout is the default
version: 1
---

**Mobile first** is an order for writing CSS: the rules outside any media query are the layout for the **narrowest** screen, and each media query adds to it for screens that have more room. Here is the bookshop's menu written that way:

```css
*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; font-family: system-ui, sans-serif; }

/* The phone's layout is the default: one link per line, each easy to tap. */
.menu { list-style: none; margin: 0; padding: 0; }
.menu a { display: block; padding: 0.75rem 1rem; }

/* Only a window wide enough for a row gets one. */
@media (width >= 40rem) {
  .menu { display: flex; gap: 0.5rem; }
}
```

Outside the query, each link is a block with padding: one per line, the whole width of the screen, easy to hit with a thumb. The media query, which section 03 takes apart, says "from 40rem wide upwards", and only there does the list become a flex row:

```
ana@laptop:~/site$ probe --width 390 first.html box ".menu a"
a  x 0      y 0      width 390    height 44
a  x 0      y 44     width 390    height 44
a  x 0      y 88     width 390    height 44
ana@laptop:~/site$ probe --width 800 first.html box ".menu a"
a  x 0      y 0      width 82.61  height 44
a  x 90.61  y 0      width 130.89 height 44
a  x 229.5  y 0      width 143.44 height 44
```

On a phone 390 wide, the three links are stacked, each **390 wide and 44 tall**. On a window 800 wide, they sit in a row at y 0, each as wide as its text. The page's `<meta name="viewport">` from lesson 1 section 08 is what lets a phone report 390 here at all; without it the phone lays the page out 980 wide and no query for a narrow screen would ever match.

## Why start from the narrow end

**The narrow layout is the simpler one.** On a phone, most things are a single column in the order of the HTML, which is what block layout does with no CSS at all. The wide layouts are where the rows, columns and sidebars come in. Writing the simple case first and adding complexity in queries means each query only says what is **new** at that width.

The other order, **desktop first**, writes the wide layout first and then undoes it in queries that apply below a width:

```css
.menu { display: flex; gap: 0.5rem; }
.menu a { padding: 0.5rem; }

@media (width < 40rem) {
  .menu { display: block; }
  .menu a { display: block; padding: 0.75rem 1rem; }
}
```

It works, and every rule in the query is there to cancel one outside it. As the stylesheet grows, the narrow screen ends up as the sum of everything the desktop did and everything that was undone afterwards, and the thing that most people use is the one built last.

It is easier to add than to subtract, and mobile first is that, written down.
