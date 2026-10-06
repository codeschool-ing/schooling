---
title: Visual order and reading order
version: 1
---

Flexbox can change the order in which items are drawn without changing the HTML. **`order`** on an item moves it: items are drawn in increasing `order`, which defaults to 0, so `order: -1` puts an item first and `order: 1` last. `row-reverse` and `column-reverse` draw the whole set backwards. That is useful and it has a cost. Here is a set of links for a book, with the most important one moved to the front by CSS:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Order · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .actions { display: flex; gap: 8px; }
      .actions a { padding: 8px 16px; background: #f4f1ea; }
      .actions .primary { order: -1; background: #2f6f4e; color: white; }
    </style>
  </head>
  <body>
    <nav class="actions" aria-label="Book">
      <a href="details.html">Details</a>
      <a href="reviews.html">Reviews</a>
      <a href="order.html" class="primary">Order this book</a>
    </nav>
  </body>
</html>
```

```
ana@laptop:~/site$ probe order.html box a tab tab tab
a          x 149.39 y 0      width 80.91  height 40
a          x 238.3  y 0      width 92.47  height 40
a.primary  x 0      y 0      width 141.39 height 40
focus: a "Details"
focus: a "Reviews"
focus: a "Order this book"
```

On the screen, *Order this book* is first, at **x 0**, with *Details* and *Reviews* after it. But **Tab went to *Details* first**, then *Reviews*, then *Order this book*: keyboard focus follows the HTML, not the drawing. A sighted keyboard user sees the focus ring jump from the middle of the row to the right and then back to the left. A screen reader reads them in HTML order too, so its user hears a different sequence from the one everybody else sees.

## The rule

WCAG asks that when the order of content matters to its meaning, the reading order matches it (1.3.2, *Meaningful Sequence*), and that focus moves in an order that preserves meaning and operability (2.4.3, *Focus Order*). The practical rule is short: **if something should come first, put it first in the HTML**. Use `order` and the reverse directions only to rearrange things whose order does not matter to anyone, such as decoration, or to make a visual adjustment that keeps the sequence the same. Lesson 9 meets the same rule with Grid, which can move items much further.
