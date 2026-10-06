---
title: The median
version: 1
---

The **median** is the middle value once the values are in order. Half the observations are at or below it and half are at or above it.

## An odd number of values

With an odd count there is one value in the middle. Take the first five deliveries: 34.5, 41.0, 52.5, 29.0, 38.5. Sorted, they are

```localised
29.0   34.5   38.5   41.0   52.5
              ^^^^
```

The third of five is the middle, so the median is **38.5 minutes**.

## An even number of values

With an even count there are two values in the middle, and the median is halfway between them. Here are Horta's twelve baskets, sorted:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 150\" role=\"img\" data-fig=\"l03-median\" aria-label=\"The twelve baskets sorted from R$ 12.90 to R$ 212.60, as twelve boxes in a row. The sixth and seventh, R$ 62.30 and R$ 74.10, are highlighted; the median is halfway between them, R$ 68.20.\"><rect x=\"30.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12.90</text><rect x=\"82.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"106.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">18.50</text><rect x=\"134.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"158.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">31.90</text><rect x=\"186.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">35.60</text><rect x=\"238.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">47.80</text><rect x=\"290.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"314.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">62.30</text><rect x=\"342.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"366.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">74.10</text><rect x=\"394.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">86.40</text><rect x=\"446.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">95.00</text><rect x=\"498.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">118.20</text><rect x=\"550.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"574.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">154.75</text><rect x=\"602.0\" y=\"40.0\" width=\"48.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">212.60</text><path d=\"M340.0 30.0 L340.0 84.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"184.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">six below</text><text x=\"496.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">six above</text><text x=\"340.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">median = (62.30 + 74.10) ÷ 2 = 68.20</text></svg>", "caption": "With an even count there is no single middle value, so the median is halfway between the two in the middle."}
```

The sixth and seventh are R$ 62.30 and R$ 74.10, so the median basket is (62.30 + 74.10) ÷ 2 = **R$ 68.20**.

Do the same with the twelve delivery times — sorted, the sixth and seventh are 36.0 and 38.5 — and the median is **37.25 minutes**, a little below the mean of 38.96.

## Finding the middle in a long list

For *n* sorted values the median sits at position (*n* + 1) ÷ 2. With 12 values that is position 6.5, which means halfway between the sixth and the seventh. With 101 values it is position 51, a single value.

Sorting is the whole work. Forgetting to sort is the mistake: the middle of an unsorted list is just whatever happened to be typed in the middle.

## What the median ignores

The median looks at the order of the values and at one or two of them in the middle, and at nothing else. Change the slowest delivery from 61 minutes to 610 and the median does not move: it is still halfway between 36.0 and 38.5.

That makes it **robust**: a single wild value, a typing error or one extraordinary case cannot drag it about. The mean, which uses every value's size, moves with each of them. Lesson 4 turns that difference into a rule for choosing between them.

The median also needs only an **order**, not distances. That is why lesson 2 allowed it for ordinal variables like star ratings, where the mean rests on an assumption.
