---
title: Counting categories
version: 1
---

Since every summary of a categorical variable starts from a count, the basic tool is the **frequency
table**: each category, how many observations fell into it, and what share of the whole that is.

| payment | count | share |
|---|---|---|
| pix | 6 | 50.0% |
| card | 4 | 33.3% |
| cash | 2 | 16.7% |
| **total** | **12** | **100.0%** |

The count is the **frequency**. The share is the **relative frequency**: the count divided by the
total. A relative frequency can be written as a fraction, a decimal or a percentage. 2/12, 0.167 and
16.7% are the same fact.

## Why shares, when the counts are right there

A count answers *how many*. A share answers *how common*, and that is the one you can compare.

If a second month brought 30 card payments, you could not say whether card had grown more popular
until you knew how many orders that month had. Thirty out of sixty is the same share as four out of
eight. Counts compare totals; **shares compare habits**.

## The shares should add to 100%, and sometimes do not

Shares rounded for a report can add to 99.9% or 100.1%. Above, 50.0 + 33.3 + 16.7 adds to exactly
100.0, but 33.3 is itself a third rounded down, and with other counts the rounding would show. That
is not a mistake in the counting, and a footnote saying the figures are rounded is enough.

A frequency table whose shares add to much more than 100% is a different matter. It means some
observations were counted in more than one category, which breaks the first of the two rules in the
section on categorical variables. Find out why before anybody reads the table.

## Two categorical variables at once

Count by two variables together and you get a **contingency table**, with one variable along the
rows and the other along the columns:

| | pix | card | cash | total |
|---|---|---|---|---|
| Cambuí | 3 | 0 | 1 | 4 |
| Taquaral | 1 | 2 | 0 | 3 |
| Barão Geraldo | 1 | 1 | 0 | 2 |
| Centro | 1 | 1 | 1 | 3 |
| **total** | **6** | **4** | **2** | **12** |

The margins carry the frequency table of each variable on its own, and the cells carry the
combinations. **Three of Cambuí's four orders were paid by pix**, against one of Taquaral's three.

With twelve orders that difference is three against one and means very little. With twelve
thousand, the same pattern might be a fact about how two neighbourhoods pay. Telling those two cases
apart is exactly what a hypothesis test does, and lesson 16 runs the chi-square test on a table
shaped like this one.
