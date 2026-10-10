---
title: Choosing the chart from the question
version: 1
---

**A chart is chosen by the question it answers, never by the gallery.** Excel's **Insert ›
Recommended Charts** looks at the shape of the range you selected and offers what fits that shape.
It cannot know what the reader is supposed to see, and the same six numbers can be drawn in a way
that shows the answer or in a way that hides it.

Five questions cover almost everything a business chart is asked:

| the question | the form | at Café Serra |
|---|---|---|
| how do these amounts compare? | bars or columns, sorted | revenue by product |
| how did it change over time? | a line, or columns for a few periods | revenue by month |
| what share of the whole is each part? | a single bar split into parts, or a pie when there are two or three parts that differ clearly | revenue by channel |
| do two measures move together? | a scatter, one point per record | bags against price, sale by sale |
| what is the number? | not a chart at all: one cell, written large | total revenue |

## The pie, put to the test

The six products' revenue is the classic pie. Here it is beside the same numbers as bars:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" data-fig=\"l12-pie-bar\" aria-label=\"The revenue of the six products drawn twice. On the left, a pie: the two largest slices, CER1K at 41.5% and SUL1K at 40.9%, look the same size. On the right, the same values as bars sorted from largest to smallest, starting at zero, with the value at the end of each bar: CER1K 21356, SUL1K 21082, and the other four far below.\"><text x=\"40.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a pie: which slice is bigger?</text><path d=\"M170 175 L170.0 60.0 A115 115 0 0 1 228.7 273.9 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--phosphor)\"></path><text x=\"298.3\" y=\"139.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CER1K</text><path d=\"M170 175 L228.7 273.9 A115 115 0 0 1 67.3 123.3 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--amber)\"></path><text x=\"79.3\" y=\"272.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SUL1K</text><path d=\"M170 175 L67.3 123.3 A115 115 0 0 1 99.2 84.4 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--wire)\"></path><path d=\"M170 175 L99.2 84.4 A115 115 0 0 1 141.1 63.7 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--wire)\"></path><path d=\"M170 175 L141.1 63.7 A115 115 0 0 1 158.3 60.6 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--wire)\"></path><path d=\"M170 175 L158.3 60.6 A115 115 0 0 1 170.0 60.0 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--wire)\"></path><text x=\"40.0\" y=\"316.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the four small slices together: 17.6%</text><text x=\"400.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">bars, sorted, from zero</text><path d=\"M470.0 52.0 L470.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"462.0\" y=\"71.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CER1K</text><path d=\"M470.0 60.0 L666.0 60.0 Q670.0 60.0 670.0 64.0 L670.0 78.0 Q670.0 82.0 666.0 82.0 L470.0 82.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor)\"></path><text x=\"676.0\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">21,356</text><text x=\"462.0\" y=\"109.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SUL1K</text><path d=\"M470.0 98.0 L663.4 98.0 Q667.4 98.0 667.4 102.0 L667.4 116.0 Q667.4 120.0 663.4 120.0 L470.0 120.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"673.4\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">21,082</text><text x=\"462.0\" y=\"147.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DEC250</text><path d=\"M470.0 136.0 L499.9 136.0 Q503.9 136.0 503.9 140.0 L503.9 154.0 Q503.9 158.0 499.9 158.0 L470.0 158.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"509.9\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3,622</text><text x=\"462.0\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MOG250</text><path d=\"M470.0 174.0 L497.4 174.0 Q501.4 174.0 501.4 178.0 L501.4 192.0 Q501.4 196.0 497.4 196.0 L470.0 196.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"507.4\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3,354</text><text x=\"462.0\" y=\"223.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SUL250</text><path d=\"M470.0 212.0 L477.6 212.0 Q481.6 212.0 481.6 216.0 L481.6 230.0 Q481.6 234.0 477.6 234.0 L470.0 234.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"487.6\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1,243</text><text x=\"462.0\" y=\"261.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CER250</text><path d=\"M470.0 250.0 L473.9 250.0 Q477.8 250.0 477.8 253.9 L477.8 268.1 Q477.8 272.0 473.9 272.0 L470.0 272.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"483.8\" y=\"261.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">837</text><text x=\"400.0\" y=\"316.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CER1K leads SUL1K by R$ 274, which the pie cannot show</text></svg>", "caption": "The same six numbers as a pie and as sorted bars. An eye compares lengths along one baseline far better than angles, so the bars show what the pie hides: which product leads, and by how little."}
```

`CER1K` brings in 41.5% of the revenue and `SUL1K` 40.9%. In the pie the two slices look the same,
and nobody can say which is larger. A formula says so at once:

```localised
=SUMIFS(Sales[Revenue], Sales[Product], "CER1K")-SUMIFS(Sales[Revenue], Sales[Product], "SUL1K")
```

It answers 274: `CER1K` leads by R$ 274 in R$ 51,494. **The eye compares lengths along one baseline
well and angles badly**, so in the bars the lead is visible, if small, and the four little products
are readable rather than four slivers. Sorting the bars from largest to smallest does the reader's
first job for them.

A pie is defensible for two or three parts that differ clearly. Revenue by channel is one: wholesale
75.2%, online 21.6%, the shop 3.1%. Even then a bar does the job as well, and the next sections use
bars.

## Bars, columns and lines

Bars run across and columns stand up; they show the same thing. Use **bars** when the category names
are long or there are many of them, because the names then sit on their own lines, and **columns**
when the categories are periods of time, which a reader expects to run from left to right.

**A line joins its points, and joining them claims an order and a path from one to the next.** The
months come one after another, so revenue by month is a line. The products come in no order at all,
and a line through the six would draw a trend from `CER1K` to `CER250` that does not exist.

## A scatter, for two measures at once

A scatter puts one point per record: here, each of the 108 sales, with its bags across and its
price up. It is the form for the question "do these two move together?", and on Café Serra's data it
shows two clouds. These two formulas measure where they meet:

```localised
=MINIFS(Sales[Bags], Sales[Channel], "Wholesale")
=MAXIFS(Sales[Bags], Sales[Channel], "<>Wholesale")
```

No wholesale sale is smaller than **4** bags, and no online or shop sale is larger than **5**. The
two groups touch at 4 and 5 bags and nowhere else.

## And sometimes no chart

"What was the revenue?" has one answer, R$ 51,494, and a chart of one number is a bar with nothing to
compare it against. Write the number in a cell, large, with what it is beside it. Lesson 17 builds
those cells for the dashboard.
