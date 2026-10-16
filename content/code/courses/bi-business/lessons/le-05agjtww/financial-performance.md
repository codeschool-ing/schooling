---
title: Financial performance: what a lender earns
version: 1
---

A retailer earns the difference between what it sells goods for and what they cost. A lender sells
money, and **its income statement is a chain of four subtractions**: the interest it earns on loans,
minus what it pays for the money it lends, minus the loans that are not paid back, minus the cost of
running the company. Each subtraction has a ratio, and the three ratios are the first thing anybody
reading a lender looks at.

## Ipê's two years, in your sheet

Ipê's figures for 2024 and 2025 in millions of reais. The loan book is the average amount lent out
during the year, personal loans and card balances together. Type it into a new sheet from A1:

| | A | B | C |
|---|---|---|---|
| 1 | Line | 2024 | 2025 |
| 2 | Average loan book | 640 | 820 |
| 3 | Interest income | 236 | 291 |
| 4 | Fee income | 30 | 36 |
| 5 | Funding cost | 77 | 98 |
| 6 | Credit losses | 45 | 74 |
| 7 | Operating costs | 64 | 72 |

The funding cost is what Ipê pays to borrow the money it lends, to banks and to investors. Credit
losses are what the year's bad loans cost, as the accounts record them. Fee income is mostly the
card's fees.

## The chain

In A8 type `Net interest income`, and in B8 the interest earned minus the cost of funding it:

```localised
=B3-B5      159
```

In A9 `Total income`, and in B9 net interest income plus fees:

```localised
=B8+B4      189
```

In A10 `Profit before tax`, and in B10 total income minus the two costs:

```localised
=B9-B6-B7      80
```

Copy B8:B10 into C8:C10. **Your 2025 column should read 193, 229 and 83.**

## The three ratios

Each ratio divides one link of the chain by something, and each answers one question.

**Net interest margin** — how much the lending itself earns, per real lent:

```localised
=ROUND(B8/B2*100,1)      24.8
```

**Cost of risk** — how much of the book was lost to loans not repaid:

```localised
=ROUND(B6/B2*100,1)      7
```

**Efficiency ratio** — how many reais of operating cost it takes to earn a hundred reais of income.
Lower is better, which surprises people the first time:

```localised
=ROUND(B7/B9*100,1)      33.9
```

Put them in rows 11 to 13 and copy each to column C:

| ratio | 2024 | 2025 |
|---|---|---|
| net interest margin | 24.8% | 23.5% |
| cost of risk | 7.0% | 9.0% |
| efficiency ratio | 33.9% | 31.4% |

Net interest margins of this size belong to consumer credit in Brazil, where rates on personal loans
are high; a bank lending to companies works on a fraction of them. The comparison that matters is
Ipê against itself.

## What the year says

The 2025 board presentation led with growth. The loan book grew 28.1% and total income 21.2%, and the
efficiency ratio improved from 33.9% to 31.4%: Ipê earns each real of income with less overhead than
a year before. All true.

**Profit before tax grew 3.8%.** Between the income and the profit sits the cost of risk, which went
from 7.0% of the book to 9.0%. Credit losses rose 64.4%, more than twice as fast as the book. Had
losses stayed at 2024's share of the book, 2025 would have lost R$ 16 million less to bad loans.

Two readings are possible, and the income statement cannot choose between them. Either Ipê is lending
to riskier people than before, or its newer loans have simply reached the age at which loans go bad.
**The answer is not in the year's totals at all; it is in the loans grouped by when they were made**,
which is the next section.
