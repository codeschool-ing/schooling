---
title: Finance: the income statement, and why profit is not cash
version: 1
---

Finance is where every other function's numbers end up, so it is the function a BI analyst has to
understand first. Its central document is the **income statement**: sales at the top, costs taken
off in a fixed order, profit at the bottom. **Each line answers a different question, and the
margins between them are the numbers a board actually reads.** Varanda's for 2025 is small enough to
type.

## Varanda's 2025, simplified

Add a sheet and type the lines in thousands of reais. It is simplified on purpose: sales are counted
after the taxes charged on them, and the costs below operating profit — interest, income tax — are
left out, because they belong to Otávio's world more than to an analyst's.

| | A | B |
|---|---|---|
| 1 | Line | R$ thousand |
| 2 | Sales | 98000 |
| 3 | Cost of goods sold | 55370 |
| 4 | Gross profit | |
| 5 | People | 18750 |
| 6 | Stores and rent | 9800 |
| 7 | Marketing | 4410 |
| 8 | Warehouse and deliveries | 3920 |
| 9 | Other | 2890 |
| 10 | Operating expenses | |
| 11 | Operating profit | |

The three empty cells are formulas:

```localised
B4    =B2-B3          42630
B10   =SUM(B5:B9)     39770
B11   =B4-B10         2860
```

**Cost of goods sold** is what Varanda paid its suppliers for the goods it sold this year — not for
everything it bought, since what is still in the warehouse has not been sold. **Gross profit** is
what the selling earned before running the company. **Operating expenses** are the cost of running
it: people, stores, marketing, logistics. **Operating profit** is what is left.

## Margins: each line as a share of sales

A line on its own says little; the same R$ 2.86 million would be a fine year for a small shop and a
disaster for a large one. Dividing by sales makes the lines comparable across years and companies.
In C1 type `Margin %`, and:

```localised
C4    =ROUND(B4/B2*100,1)     43.5
C11   =ROUND(B11/B2*100,1)    2.9
```

**A gross margin of 43.5% and an operating margin of 2.9%.** Read together, they say that Varanda
buys well enough — for every R$ 100 of sales, R$ 43.50 is left after paying for the goods — and that
running nine stores, a warehouse and an online shop consumes almost all of it. The two largest
operating lines, people at 19.1% of sales and stores and rent at 10.0%, are where a finance director
looks first when the operating margin falls.

## Profit is not cash

The income statement records a sale when it happens, not when the money arrives. That gap is one
of the most common misreadings of a profitable company.

In December a customer buys a R$ 6,000 sofa on ten interest-free card instalments, which is ordinary
in Brazilian furniture retail. **The whole R$ 6,000 is December's sale, and its margin is December's
profit.** The money arrives at R$ 600 a month over the following ten months:

```localised
=6000/10      600
```

Now multiply that by every instalment sale of a good December. **The income statement shows a record
month while the bank account fills slowly**, and meanwhile the suppliers who sent the Christmas stock
in October want paying. Retailers can ask the card companies to pay the instalments early, for a
fee, and that fee is a cost of selling on instalments that the sales figure does not show.

Finance therefore watches cash separately from profit, in a cash-flow statement and a forecast of the
bank balance week by week. **An analyst asked "how did we do?" by finance should ask "in profit or in
cash?"** — the two answers differ every month, and most of all in December.
