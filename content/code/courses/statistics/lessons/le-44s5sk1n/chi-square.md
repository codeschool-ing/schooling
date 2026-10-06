---
title: "Counts in a table: the chi-square test"
version: 1
---

Horta tests a new checkout page. Of 2,000 visitors who saw the old page, 220 bought something; of 2,000 who saw the new one, 262 did.

| | bought | did not | total |
|---|---|---|---|
| old page | 220 | 1,780 | 2,000 |
| new page | 262 | 1,738 | 2,000 |
| **total** | **482** | **3,518** | **4,000** |

The conversion rates are 11.0% and 13.1%. Is the difference real?

## What no difference would look like

The null hypothesis is that the page makes no difference: both pages convert at the same rate, and the overall rate, 482 out of 4,000, applies to each. Then each page's 2,000 visitors would be expected to produce 241 purchases and 1,759 non-purchases.

The **expected count** for each cell is its row total times its column total, divided by the grand total: 2,000 × 482 ÷ 4,000 = 241.

## The statistic

The **chi-square statistic** adds up, over every cell, how far the observed count is from the expected one, squared and scaled by the expected count: **χ² = Σ (observed − expected)² ÷ expected**.

For the checkout table: (220 − 241)² ÷ 241 + (1,780 − 1,759)² ÷ 1,759 + (262 − 241)² ÷ 241 + (1,738 − 1,759)² ÷ 1,759 = **4.16**.

Under the null, the statistic follows the chi-square distribution with (rows − 1) × (columns − 1) degrees of freedom, here 1. The p-value for 4.16 is **0.041**. Below 0.05: the new page converts better, though not by a wide margin of evidence.

A spreadsheet's `CHISQ.TEST` takes the observed table and the table of expected counts and returns the p-value directly:

```localised
=CHISQ.TEST(E2:F3, G2:H3)      0.0413607680611259
```

## Goodness of fit

The same statistic checks a model. Lesson 8 compared 60 days of complaints with a Poisson distribution. Grouping five or more complaints together so that every expected count is reasonably large, the chi-square statistic is 7.98 with 5 degrees of freedom, and p = 0.16: the Poisson model is consistent with the data, as lesson 8's eye suggested.

## Its conditions

- The counts must be of **independent units**: each visitor counted once.
- The **expected counts should not be small**: a common rule asks for at least 5 in every cell. Lesson 1's table of twelve orders by neighbourhood and payment fails badly, with expected counts below 1, and should not be tested this way.
- It works on **counts**, never on percentages: 11% of 2,000 and 11% of 20 are very different evidence, and the counts carry that difference.
