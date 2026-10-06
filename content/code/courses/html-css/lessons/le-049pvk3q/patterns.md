---
title: Positioning patterns worth knowing
version: 1
---

Four small patterns use positioning in ways you will meet on almost every site. They are all on one page:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Patterns · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .skip {
        position: absolute;
        left: 8px;
        top: -100px;
        padding: 8px 16px;
        background: #2f6f4e;
        color: white;
      }
      .skip:focus { top: 8px; }
      .visually-hidden {
        position: absolute;
        width: 1px;
        height: 1px;
        overflow: hidden;
        clip-path: inset(50%);
        white-space: nowrap;
      }
      .card { position: relative; width: 300px; padding: 16px; margin: 60px 16px 16px; background: #f4f1ea; }
      .card a::after { content: ""; position: absolute; inset: 0; }
    </style>
  </head>
  <body>
    <a class="skip" href="#main">Skip to main content</a>
    <header><p>Andorinha Books</p></header>
    <main id="main">
      <article class="card">
        <h2><a href="swap.html">Book swap</a></h2>
        <p>Saturday 10 October, from 10 am.</p>
      </article>
      <table>
        <caption class="visually-hidden">Opening hours</caption>
        <tr><th scope="row">Saturday</th><td>10 am to 4 pm</td></tr>
      </table>
    </main>
  </body>
</html>
```

## A skip link

Lesson 2 mentioned the **skip link**, "skip to main content", the first link on a page, which lets a keyboard user jump past the header and the menu instead of tabbing through them on every page. It must be the first thing Tab reaches and should be visible when it is, but it would clutter the page for everybody else. So it waits off the screen:

```
ana@laptop:~/site$ probe patterns.html box .skip tab box .skip
a.skip  x 8      y -100   width 176.97 height 40
focus: a "Skip to main content"
a.skip  x 8      y 8      width 176.97 height 40
```

Before Tab it is at **y −100**, above the top of the page. The first Tab focuses it, `.skip:focus { top: 8px; }` applies, and it is at **y 8**, on the screen where a keyboard user can see what Enter will do.

## A whole card that is a link

A card whose heading is a link is often wanted clickable everywhere, not only on the heading's words. Wrapping the whole card in `<a>` makes the link's name the whole card's text, read out in full by a screen reader. The **stretched link** keeps the link on the heading and stretches its clickable area: `.card a::after { content: ""; position: absolute; inset: 0; }` lays an empty pseudo-element over the card, measured against the card because the card is `position: relative`.

```
ana@laptop:~/site$ probe patterns.html box .card top 330 230 top 30 110
article.card  x 16     y 100    width 332    height 147.81
at 330,230: a  "Book swap"
at 30,110: a  "Book swap"
```

A point in the bottom right corner of the card, over the paragraph, and a point at its top left, in its padding, both hit **the link**. On the copy of the page without the `::after`, the same corner hits the article. The link's name is still just *Book swap*.

## Text for screen readers only

Lesson 4 promised a technique for a caption that should be in the accessibility tree and not on the screen. It is a set of declarations usually given the class name `visually-hidden`:

```
ana@laptop:~/site$ probe patterns.html box caption tree table
caption.visually-hidden  x 2      y 265.81 width 1      height 1
- table "Opening hours":
  - caption: Opening hours
  - rowgroup:
    - row "Saturday 10 am to 4 pm":
      - rowheader "Saturday"
      - cell "10 am to 4 pm"
```

The caption is drawn as a **1 by 1 pixel** box, clipped to nothing, and the tree still names the table *Opening hours*. `display: none` or `visibility: hidden` would have removed it from the tree as well, which is the opposite of what is wanted.

## A sticky header that does not hide its anchors

The fourth pattern is two lines and closes section 06: a header with `position: sticky; top: 0` keeps the menu on screen, and `html { scroll-padding-top: 4rem; }` makes a jump to `#events` stop 4rem short, so that the section's heading is not underneath the header. Sticky is usually the better choice than fixed for a header, because it takes up its own space at the top of the page instead of covering content.
