---
title: Averages of averages
version: 1
---

Horta has two stores. Last month the Cambuí store took 300 orders with a mean basket of R$ 80, and the Taquaral store took 100 orders with a mean basket of R$ 40. What was the mean basket across both?

The tempting answer is to average the two averages: (80 + 40) ÷ 2 = **R$ 60**. It is wrong.

## Weight each mean by its count

The 300 Cambuí orders took 300 × 80 = R$ 24,000. The 100 Taquaral orders took 100 × 40 = R$ 4,000. Together that is R$ 28,000 over 400 orders:

```localised
(300 × 80 + 100 × 40) ÷ (300 + 100) = 28,000 ÷ 400 = 70
```

The mean basket across both stores is **R$ 70**. Averaging the two averages gave each store the same say, as if each had taken the same number of orders. The **weighted mean** gives each store a say in proportion to its orders, which is what the overall mean is.

The plain average of averages is right only when the groups are the same size. When they differ, it is wrong by an amount that grows with the difference.

## The same thing in a frequency table

A frequency table is a set of groups, each with a count, so its mean is a weighted mean. Here are 100 of Horta's orders counted by the number of items in them:

| items | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| orders | 14 | 22 | 31 | 18 | 9 | 6 |

Multiply each number of items by its count, add, and divide by the total count:

```localised
(1×14 + 2×22 + 3×31 + 4×18 + 5×9 + 6×6) ÷ 100 = 304 ÷ 100 = 3.04
```

The mean is **3.04 items**. In a spreadsheet, with the items in A2:A7 and the counts in B2:B7:

```localised
=SUMPRODUCT(A2:A7, B2:B7) / SUM(B2:B7)      3.04
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 270\" role=\"img\" data-fig=\"l03-items-frequency\" aria-label=\"A bar chart of 100 orders by number of items: 14 with one, 22 with two, 31 with three, 18 with four, 9 with five and 6 with six. The weighted mean, 3.04, sits just right of three. The plain average of the labels 1 to 6, 3.5, sits further right.\"><path d=\"M80.0 60.0 L80.0 215.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 215.0 L80.0 215.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"215.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 192.9 L560.0 192.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 192.9 L80.0 192.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"192.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M80.0 170.7 L560.0 170.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 170.7 L80.0 170.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"170.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M80.0 148.6 L560.0 148.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 148.6 L80.0 148.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"148.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M80.0 126.4 L560.0 126.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 126.4 L80.0 126.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"126.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M80.0 104.3 L560.0 104.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 104.3 L80.0 104.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"104.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M80.0 82.1 L560.0 82.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 82.1 L80.0 82.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"82.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M80.0 60.0 L560.0 60.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 60.0 L80.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35</text><text x=\"80.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><path d=\"M92.8 215.0 L92.8 153.0 L147.2 153.0 L147.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"120.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><path d=\"M172.8 215.0 L172.8 117.6 L227.2 117.6 L227.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"200.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2</text><path d=\"M252.8 215.0 L252.8 77.7 L307.2 77.7 L307.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"280.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><path d=\"M332.8 215.0 L332.8 135.3 L387.2 135.3 L387.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"360.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4</text><path d=\"M412.8 215.0 L412.8 175.1 L467.2 175.1 L467.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"440.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5</text><path d=\"M492.8 215.0 L492.8 188.4 L547.2 188.4 L547.2 215.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"520.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6</text><path d=\"M80.0 215.0 L560.0 215.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"320.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">items in the order</text><path d=\"M283.2 215.0 L283.2 44.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"283.2\" y=\"36.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">weighted mean 3.04</text><path d=\"M320.0 215.0 L320.0 44.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"320.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mean of the labels 3.5</text></svg>", "caption": "Each bar weighs as much as the orders in it. Averaging the labels 1 to 6 gives every bar the same weight, and lands at 3.5."}
```

The mistake to avoid is `=AVERAGE(A2:A7)`, which averages the six labels 1 to 6 and returns 3.5, as if every bar held the same number of orders.

## The median of a frequency table

The median comes from the cumulative counts. Running down the table, the counts add up to 14, then 36, then 67. The 50th and 51st orders both fall in the third group, so the median is **3 items**, and the mode, the tallest bar, is 3 as well.
