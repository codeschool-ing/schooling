---
title: R8 at 360 pixels
version: 1
---

Checking R8 on a phone does not need a phone to start with. **Every current desktop browser has a
responsive mode**, which shrinks the area the page is drawn in to any width you type and redraws
the page as a browser that size would. It is the quickest compatibility check there is, and on
boxoffice's home page it finds a defect in under a minute.

## Opening responsive mode

With boxoffice running, open `http://127.0.0.1:8000` and then:

- in Chrome or Edge, open the developer tools with F12 (Cmd+Option+I on a Mac) and press
  Ctrl+Shift+M (Cmd+Shift+M on a Mac), or click the icon of a phone and a tablet at the top left of
  the tools. A bar appears above the page; choose Responsive in its first menu if it names a device,
  and type 360 in the width box;
- in Firefox, Ctrl+Shift+M (Cmd+Option+M on a Mac) opens Responsive Design Mode directly, with
  a width box at the top;
- in Safari, the Develop menu has Enter Responsive Design Mode, once the Develop menu has been
  switched on in Safari's settings.

This course ran the check in Chromium 141, the open-source browser Chrome is built from; the
Firefox and Safari steps are described and were not run.

## What 360 pixels shows

At 360 pixels the page keeps its heading, Shows, and the table starts as usual, but only two of its
five columns fit: the name of the show, and the date and time, which end right at the edge.
**The price, the seats left and the Book links are off the screen to the right.** Drag the page
sideways, or swipe it on a phone, and they come into view; the links under the table, Shows, Sign
up and Outbox, stay where they were.

How far off the screen is something the browser will tell you. Open the Console tab of the same
developer tools, type `document.documentElement.scrollWidth` and press Enter. It answers with the
width of the whole page in CSS pixels, and in Chromium at 360 pixels it answered **776**: the page is
more than twice as wide as the window it is in.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l07-narrow-screen\" aria-label=\"The home page of boxoffice drawn to scale at a window 360 pixels wide. The page is 776 pixels wide. Inside the window are the heading Shows and the first two columns of the table, Show and When. The columns Price, Seats left and the Book links lie outside the window, to the right, a sideways scroll away.\"><rect x=\"30.0\" y=\"34.0\" width=\"620.8\" height=\"134.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"318.0\" y=\"35.0\" width=\"331.8\" height=\"132.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--ink)\" stroke-width=\"0\"></rect><rect x=\"24.0\" y=\"20.0\" width=\"300.0\" height=\"162.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\"></rect><text x=\"42.8\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"700\" fill=\"var(--paper)\">Shows</text><text x=\"48.4\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">Show</text><text x=\"48.4\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">The Seagull</text><text x=\"48.4\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Hamlet</text><text x=\"212.4\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper-dim)\">When</text><text x=\"212.4\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2026-10-10 20:00</text><text x=\"212.4\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2026-10-17 20:00</text><text x=\"389.2\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper-dim)\">Price</text><text x=\"389.2\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 60,00</text><text x=\"389.2\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 80,00</text><text x=\"487.6\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper-dim)\">Seats left</text><text x=\"487.6\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120</text><text x=\"487.6\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><text x=\"593.2\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper-dim)\"></text><text x=\"593.2\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Book</text><text x=\"593.2\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Book</text><text x=\"42.8\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">Shows · Sign up · Outbox</text><text x=\"484.4\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">off the screen</text><text x=\"484.4\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a sideways scroll away</text><path d=\"M30.0 208.0 L318.0 208.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M30.0 203.0 L30.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M318.0 203.0 L318.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"174.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the window: 360</text><path d=\"M30.0 234.0 L650.8 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M30.0 229.0 L30.0 239.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M650.8 229.0 L650.8 239.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"340.4\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the page: 776</text></svg>", "caption": "The home page at 360 pixels, drawn to the widths Chromium measured. The window shows the name and the date; the price, the seats and the Book link are on the part of the page outside it."}
```

## Why it happens

The page's own style says why, and you can read it without a browser. From the second terminal:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o 'table.shows{[^}]*}'
table.shows{width:760px}
```

The table of shows is told to be 760 pixels wide, whatever the window. Add the 16 pixels of margin
the page keeps on its left and the page is 776 pixels wide, the number the console gave. On Windows
without a Unix shell, the browser's View Page Source shows the same rule, in the `<style>` block
near the top.

One other cause of a page that does not fit a phone can be ruled out the same way. A page without a
viewport line in its head is laid out by phone browsers as if the screen were a desktop's and then
shrunk, which makes everything tiny rather than cut off. boxoffice has the line:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<meta name="viewport"[^>]*>'
<meta name="viewport" content="width=device-width, initial-scale=1">
```

So the page does ask to be laid out at the phone's width, and the fixed table is what refuses.

## Where the problem starts

360 is the width R8 names, and it is not where the problem begins. Measured the same way in Chromium,
the page is still 776 pixels wide in a window 768 wide, a common width for a tablet held upright,
and in a window 775 wide. At 776 it fits. **Every window narrower than 776 pixels scrolls
sideways**, which is lesson 4's boundary thinking applied to a width: the edge is at 775 and 776,
and R8's 360 happens to be far inside the failing side.

The other pages pass at 360. Sign up and Book fit, with the page exactly as wide as the window. The
outbox does not, once it holds an e-mail: in Chromium its width came to 423, because the confirmation
link is one long line that does not wrap. That is worth a note and is not a defect against R8,
because the outbox is the test build's page and not one of the theatre's, as lesson 1 section 04
said.

## Is it a defect?

R8 says every page works on a phone screen 360 pixels wide. On the home page at that width, the
price and the Book link, the two things the page exists to show, need a sideways scroll to find,
and nothing on the screen says there is anything to scroll to. That is a departure from R8, it is
the phone-layout risk E of lesson 1's plan, and it is a defect: **the shows table is 760 pixels
wide, so a phone scrolls sideways**.

What Ana writes down while it is in front of her is what a report needs, and lesson 15 turns it into
one: the requirement, R8; the browser and its version, Chromium 141; the width, 360; what she saw; the
measured width, 776; the rule, `table.shows{width:760px}`; and a screenshot, which Chrome's
responsive bar takes from the menu at its right-hand end. The fix is Rui's.

One limit stays. Responsive mode in Chrome draws with Chrome's engine at any width, so it shows what
Chrome on a phone would do and not what Safari on an iPhone would. The next section is about the
difference.
