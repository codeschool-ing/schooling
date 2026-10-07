---
title: Ordering the bars
version: 1
---

A bar chart has a free channel that people forget is a channel: **the order of the bars**. Software
fills it by default, usually alphabetically or in the order of the data, and the default almost
never matches the question.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 230\" role=\"img\" data-fig=\"l03-sorted\" aria-label=\"Two bar charts of the 2025 regional totals. On the left the regions are in alphabetical order, Centre-West, North, Northeast, South, Southeast, and the eye zigzags to rank them. On the right they are sorted from Southeast, the largest, to North, the smallest, and the ranking is the picture.\"><text x=\"20.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">alphabetical</text><rect x=\"110.0\" y=\"40.0\" width=\"39.0\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"50.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Centre-West</text><rect x=\"110.0\" y=\"71.0\" width=\"28.1\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"81.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">North</text><rect x=\"110.0\" y=\"102.0\" width=\"94.8\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"112.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Northeast</text><rect x=\"110.0\" y=\"133.0\" width=\"82.9\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"143.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">South</text><rect x=\"110.0\" y=\"164.0\" width=\"184.2\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"174.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Southeast</text><path d=\"M110.0 36.0 L110.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"350.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sorted by value</text><rect x=\"440.0\" y=\"40.0\" width=\"184.2\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"50.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Southeast</text><rect x=\"440.0\" y=\"71.0\" width=\"94.8\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"81.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Northeast</text><rect x=\"440.0\" y=\"102.0\" width=\"82.9\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"112.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">South</text><rect x=\"440.0\" y=\"133.0\" width=\"39.0\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"143.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Centre-West</text><rect x=\"440.0\" y=\"164.0\" width=\"28.1\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"174.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">North</text><path d=\"M440.0 36.0 L440.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "Alphabetical order helps somebody look a name up and helps nobody compare. Sorted by value, the chart answers \"which is largest, which is second\" before it is asked."}
```

In alphabetical order the eye has to jump: Southeast is last, North is second, and finding the
second-largest region means comparing every bar with every other. **Sorted by value, the ranking is
the picture.** Southeast is first, Northeast is second, and the gap between them, which is the size
of Southeast's lead, is visible as the step between the first two bars.

## Which way to sort

- **Largest at the top** for bars, because people read downwards and the first thing read should be
  the first in rank.
- **Largest at the left** for columns, for the same reason in the other direction.
- **Keep the order the same across related charts.** If one chart puts Southeast first, the next
  chart about the same regions should too, even if its numbers would sort differently; otherwise
  the reader has to find each region again.

## When not to sort by value

**Some categories have an order of their own, and it wins.** Months, hours of the day, age bands,
satisfaction from "very unhappy" to "very happy", the steps of a funnel: sorting these by value
destroys the sequence the reader needs. A column chart of orders by month sorted by size is a
puzzle, not a chart.

An order of its own is the *small, medium, large* case from lesson 1: ordered categories, between a
name and a quantity. The rule is to **keep any order the categories already have**, and to sort by
value only when they have none.

## And "other"

When a long tail of small categories is merged into "Other", put Other **last**, whatever its size.
It is not a category like the rest, and a reader who sees it in second place will think it is one.
