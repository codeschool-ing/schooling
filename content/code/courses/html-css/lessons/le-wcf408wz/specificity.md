---
title: Specificity, counted
version: 1
---

**Specificity is three numbers, written (a,b,c)**, worked out from the selector alone:

- **a**: the number of **ids** in it;
- **b**: the number of **classes, attribute selectors and pseudo-classes**;
- **c**: the number of **element names and pseudo-elements**.

The universal selector `*` and the combinators count nothing. Two specificities are compared **a first**; only if the two `a`s are equal is `b` compared, and only then `c`. They are not added up: (1,0,0) beats (0,12,0), because one id beats any number of classes.

Here is `cascade.css`, five rules that all colour the note on the events page:

```css
p { color: #333333; }
.event p { color: #2f6f4e; }
p.note { color: #555555; }
#events .note { color: #7a5c00; }
.cancelled p { color: #8a1c1c; }
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 274\" role=\"img\" aria-label=\"Specificity as three counts. a counts ids, b counts classes, attribute selectors and pseudo-classes, c counts elements and pseudo-elements. p is 0,0,1. .event p, p.note and .cancelled p are each 0,1,1. #events .note is 1,1,0 and is highest. Compare a first; only if a ties compare b, then c. One id beats any number of classes.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">count each kind of thing in the selector</text><text x=\"300\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">a</text><text x=\"400\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">b</text><text x=\"560\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">c</text><text x=\"300\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ids</text><text x=\"400\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">classes, [attr], :hover</text><text x=\"560\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">elements, ::before</text><rect x=\"20\" y=\"84\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">p</text><text x=\"300\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"400\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"560\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"686\" y=\"97\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(0,0,1)</text><rect x=\"20\" y=\"116\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">.event p</text><text x=\"300\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"400\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"560\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"686\" y=\"129\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(0,1,1)</text><rect x=\"20\" y=\"148\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">p.note</text><text x=\"300\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"400\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"560\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"686\" y=\"161\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(0,1,1)</text><rect x=\"20\" y=\"180\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">.cancelled p</text><text x=\"300\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"400\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"560\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"686\" y=\"193\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(0,1,1)</text><rect x=\"20\" y=\"212\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">#events .note</text><text x=\"300\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"400\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"560\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"686\" y=\"225\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(1,1,0)</text><text x=\"20\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Compare a first; only if a ties, compare b; then c. One id beats any number of classes.</text></svg>", "caption": "The selectors from cascade.css, counted. Three of them tie at (0,1,1), and order decides between those."}
```

And here is what `probe rules` printed: every rule that sets `color` on the note, in the order the cascade weighs them, with the specificity Chromium computed for each, and at the end the colour that applied:

```
ana@laptop:~/site$ probe cascade.html rules .note color
p (0,0,1)              color: #333333                  cascade.css
.event p (0,1,1)       color: #2f6f4e                  cascade.css
p.note (0,1,1)         color: #555555                  cascade.css
#events .note (1,1,0)  color: #7a5c00                  cascade.css
computed color: rgb(122, 92, 0)
```

Four rules matched the note. Three are low: `p` at (0,0,1), `.event p` and `p.note` at (0,1,1). `#events .note` has an id and is **(1,1,0)**, so it wins outright, and the note is `rgb(122, 92, 0)`, which is `#7a5c00`. The fifth rule, `.cancelled p`, does not match the note at all, because the note is not in the cancelled event, and so it is not listed.

Now the paragraph inside the cancelled event:

```
ana@laptop:~/site$ probe cascade.html rules '.cancelled p' color
p (0,0,1)             color: #333333                  cascade.css
.event p (0,1,1)      color: #2f6f4e                  cascade.css
.cancelled p (0,1,1)  color: #8a1c1c                  cascade.css
computed color: rgb(138, 28, 28)
```

Here `.event p` and `.cancelled p` are **both (0,1,1)**: a tie on all three numbers. Specificity has nothing more to say, and the last of the four questions decides: `.cancelled p` comes later in the file, so the paragraph is red, `#8a1c1c`.

## What specificity does to a stylesheet over time

Every time somebody fixes a style by writing a more specific selector, the next person has to be more specific still. A stylesheet that started with `.note` ends up with `#events article.event p.note`, and then with `!important`. **Keep specificity low and flat**: style with single classes, avoid ids in selectors, and let order do the rest. `:where()` is a tool for it: it works like `:is()` and counts **zero**, so `:where(.event) p` is (0,0,1) and anything can override it. Lesson 10 shows how layers keep a whole stylesheet tidy on the same principle.
