---
title: sticky: in the flow until it would leave
version: 2
---

**`position: sticky`** is the hybrid. The box is in the normal flow and takes up its space, like a static one, **until scrolling would carry it past the edge set by its inset**; then it sticks at that edge, and stays there until the end of its parent passes. The months on the events page have sticky headings, `top: 0`, and each month's section is 900 pixels tall:

```
ana@laptop:~/site$ probe fixed.html box h2
h2  x 0      y 0      width 1024   height 52
h2  x 0      y 900    width 1024   height 52
ana@laptop:~/site$ probe fixed.html scroll 500 box h2 top 100 20
h2  x 0      y 500    width 1024   height 52
h2  x 0      y 900    width 1024   height 52
at 100,20: h2  "October"
ana@laptop:~/site$ probe fixed.html scroll 880 box h2 top 100 20
h2  x 0      y 848    width 1024   height 52
h2  x 0      y 900    width 1024   height 52
at 100,20: h2  "November"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The window of fixed.html at three scroll positions, with the two month sections and their sticky headings. At scroll 0 the October heading is at the top of the page. At scroll 500 it is held at the top of the window, at page y 500. At scroll 880 it has reached the bottom of its 900-pixel section and is pushed up to 848, while the November heading arrives at the top.\"><text x=\"85\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">scroll 0</text><rect x=\"20\" y=\"30\" width=\"130\" height=\"130.56\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"28\" y=\"30\" width=\"114\" height=\"130.56\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"28\" y=\"30\" width=\"114\" height=\"8.84\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"156\" y=\"34.42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2 October</text><text x=\"321\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">scroll 500</text><rect x=\"256\" y=\"30\" width=\"130\" height=\"130.56\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"264\" y=\"30\" width=\"114\" height=\"68\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"98\" width=\"114\" height=\"62.56\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"264\" y=\"30\" width=\"114\" height=\"8.84\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"392\" y=\"34.42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2 October</text><rect x=\"264\" y=\"98\" width=\"114\" height=\"8.84\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"392\" y=\"102.42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2 November</text><text x=\"557\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">scroll 880</text><rect x=\"492\" y=\"30\" width=\"130\" height=\"130.56\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><rect x=\"500\" y=\"30\" width=\"114\" height=\"3.4\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"500\" y=\"33.4\" width=\"114\" height=\"127.16\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"500\" y=\"30\" width=\"114\" height=\"3.4\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"500\" y=\"33.4\" width=\"114\" height=\"8.84\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"628\" y=\"37.82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">h2 November</text><text x=\"30\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">At 500 the October heading is held at the top of the window. At 880 it has reached the end of its</text><text x=\"30\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">section and is pushed up, at 848, while November reaches the top.</text></svg>", "caption": "A sticky heading sticks within its own section, and leaves with it."}
```

At the top of the page, the headings are where the flow put them: October at 0, November at 900. Scrolled to 500, October's heading is at **page y 500**, the top of the window, and the window's top row is still the October heading: it stuck. Scrolled to 880, it is at **848**, no longer at the top of the window: its section ends at 900 and the 52-pixel heading has been pushed up with it, while November's heading, at 900, has reached the top of the window and is what sits there.

**A sticky box never leaves its parent.** That is what makes it right for section headings: each one stays visible while you read its section and hands over to the next.

## Why sticky sometimes does nothing

The commonest complaint about sticky is that it does not stick, and the commonest cause is this. Here is `fixed.html` saved as `sticky-broken.html`, with its two sections wrapped in a `<div>` and one rule added for it:

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
      .wrapper { overflow: hidden; }
    </style>
  </head>
  <body>
    <div class="wrapper">
    <section class="month" id="october">
      <h2>October</h2>
      <p>Poetry reading, book swap and a bookbinding class.</p>
    </section>
    <section class="month" id="november">
      <h2>November</h2>
      <p>Nothing is planned yet.</p>
    </section>
    </div>
    <a class="chat" href="contact.html">Ask us</a>
  </body>
</html>
```

```
ana@laptop:~/site$ probe sticky-broken.html scroll 500 box h2
h2  x 0      y 0      width 1024   height 52
h2  x 0      y 900    width 1024   height 52
```

Wrapped in a `<div>` that has **`overflow: hidden`**, and scrolled 500, the heading is still at **0**. It did not stick. A sticky box sticks to its nearest **scrolling** ancestor, and `overflow: hidden`, `auto` or `scroll` on any ancestor makes that ancestor the one, even though it never scrolls itself. The heading stuck faithfully to the top of a box that never moved. The fix is to remove the `overflow`, or to use `overflow: clip`, which cuts off overflowing content without making a scroll container.

The other two causes: **no inset**, because `position: sticky` without `top` or another inset never sticks; and **a parent no taller than the sticky box**, which leaves it no room to move.
