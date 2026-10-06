---
title: fixed: pinned to the window
version: 1
---

**`position: fixed`** takes the box out of the flow like `absolute`, and measures it from **the window** instead of from any element. As the page scrolls, the box stays where it is on the screen. The bookshop has an *Ask us* link in the bottom right corner:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Fixed and sticky · Andorinha Books</title>
    <style>
      body { margin: 0; font: 16px/1.5 sans-serif; }
      .chat {
        position: fixed;
        right: 16px;
        bottom: 16px;
        padding: 8px 16px;
        background: #2f6f4e;
        color: white;
      }
      .month h2 {
        position: sticky;
        top: 0;
        margin: 0;
        padding: 8px;
        background: #f4f1ea;
      }
      .month { height: 900px; }
    </style>
  </head>
  <body>
    <section class="month" id="october">
      <h2>October</h2>
      <p>Poetry reading, book swap and a bookbinding class.</p>
    </section>
    <section class="month" id="november">
      <h2>November</h2>
      <p>Nothing is planned yet.</p>
    </section>
    <a class="chat" href="contact.html">Ask us</a>
  </body>
</html>
```

```
ana@laptop:~/site$ probe fixed.html box .chat
a.chat  x 927.98 y 712    width 80.02  height 40
ana@laptop:~/site$ probe fixed.html scroll 500 box .chat
a.chat  x 927.98 y 1212   width 80.02  height 40
```

`probe box` prints positions in page coordinates. Before scrolling the link is at y 712; after scrolling 500 pixels it is at **y 1212**, exactly 500 further down the page, which means it has not moved at all on the screen: 16 pixels from the bottom of a 768-pixel window, as `bottom: 16px` says.

## What fixed costs

A fixed box covers whatever scrolls under it, **all the time**. On a phone, where a small screen is all there is, a fixed header and a fixed chat button can take a fifth of the screen away from the content for the whole visit. Keep fixed elements small, and ask whether they need to be on screen permanently.

Two more consequences. **Content can scroll underneath and be hidden**: the last line of the page sits behind the *Ask us* link unless the page leaves room for it, which `padding-bottom` on the body does. **And a link to an anchor scrolls the target under a fixed header**, so the heading you jumped to is hidden. `scroll-padding-top` on the `<html>` element, set to the header's height, tells the browser to stop that much short; section 10 uses it.

Under WCAG, content that stays on the screen must not cover the element that has keyboard focus: a fixed bar that hides the link somebody has just tabbed to fails criterion 2.4.11, *Focus Not Obscured*.
