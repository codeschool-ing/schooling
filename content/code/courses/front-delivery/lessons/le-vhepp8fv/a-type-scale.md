---
title: A type scale, from one ratio
version: 1
---

**A type scale is a short list of font sizes where each one is the one before it multiplied by the same
ratio.** The planner's base is `1rem` and its ratio 1.25, so its sizes are 1, 1.25, 1.5625, 1.953125 and
2.44140625 rem, rounded. Five sizes cover every piece of text in the app; a sixth would need a reason.

The usual alternative is no scale: each heading gets the size that looked right on the day, in pixels, and
a year later the product has nineteen font sizes, three of them a pixel apart. A ratio makes the
relationships visible and the steps distinct enough that no two are confused for each other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"The planner&#x27;s five font sizes drawn side by side, each the one before it times 1.25: 1, 1.25, 1.563, 1.953 and 2.441 rem.\"><text x=\"30\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22.4\" fill=\"var(--paper)\">Aa</text><text x=\"30\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-0</text><text x=\"30\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1 rem</text><text x=\"140\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"28.0\" fill=\"var(--paper)\">Aa</text><text x=\"140\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-1</text><text x=\"140\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1.25 rem</text><text x=\"250\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"35.0\" fill=\"var(--paper)\">Aa</text><text x=\"250\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-2</text><text x=\"250\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1.563 rem</text><text x=\"360\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"43.7\" fill=\"var(--paper)\">Aa</text><text x=\"360\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-3</text><text x=\"360\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1.953 rem</text><text x=\"470\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"54.7\" fill=\"var(--paper)\">Aa</text><text x=\"470\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-4</text><text x=\"470\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">2.441 rem</text><text x=\"30\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each step is the one before it × 1.25</text></svg>", "caption": "A type scale is a rule, not a list: change the ratio and every size moves in proportion."}
```

The generated file has them:

```
ana@dev:~/planner$ grep font-size src/tokens.css
  --font-size-0: 1rem;
  --font-size-1: 1.25rem;
  --font-size-2: 1.563rem;
  --font-size-3: 1.953rem;
  --font-size-4: 2.441rem;
```

## Choosing the ratio

The ratio sets how much louder each step is than the last, and the common ones have musical names from
the intervals they share a proportion with:

| ratio | name | five steps from 1rem reach | suits |
|---|---|---|---|
| 1.125 | major second | 1.6rem | dense interfaces: tables, dashboards |
| 1.25 | major third | 2.44rem | most apps, the planner included |
| 1.333 | perfect fourth | 3.16rem | content with clear hierarchy: articles, documentation |
| 1.5 | perfect fifth | 5.06rem | marketing pages, where a headline should dominate |

A larger ratio makes headings stand out and runs out of room faster on a phone. Choosing one is a design
decision, and **changing it is one line of `tokens.json`**: every size in the app moves together, in
proportion, which is the point of having the rule rather than the list.

## Why `rem`

The sizes are in `rem`, multiples of the root element's font size, which is 16 pixels in every browser
unless the reader changed it. A reader who set their browser's text larger, because they need to, gets
every size in the planner scaled with it. Sizes in `px` ignore that setting. HTML and CSS lesson 6
compared the units; here the consequence is that **a token in `rem` keeps the whole scale accessible
without a line of extra code**, and WCAG 2.2's success criterion 1.4.4 asks for text that can be resized
to 200% without losing anything.
