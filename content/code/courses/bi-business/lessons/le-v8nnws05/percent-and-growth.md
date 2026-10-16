---
title: Percentages and growth
version: 1
---

Nearly every comparison in a descriptive report ends up as a percentage, and percentages are where
correct arithmetic produces wrong sentences. **A growth rate is a ratio, so it has a denominator, and
most mistakes with growth are a denominator nobody looked at.** Four of them come up at Varanda often
enough to learn now.

## Growth is new over old, minus one

The formula from the last section is the whole of it: `(new / old − 1) × 100`. Varanda's 2025 against
2024 is 98,000 ÷ 92,700 − 1, which is 5.7%. **The old value is the denominator, and it decides the
size of the percentage.** October fell by R$ 60 thousand, which is 0.7% of October 2024's 8,020. The
year grew by R$ 5,300 thousand, which is 5.7% of 2024's 92,700. A report that gives the change in
reais and not the base it is a change on leaves the reader to guess which of those it was.

## The average of the months is not the growth of the year

Average the twelve year-over-year rates in column D:

```localised
=ROUND(AVERAGE(D2:D13),1)      5.6
```

**5.6, while the year grew 5.7.** Neither is a typing error. The average gives every month one vote,
so February's 6,510 counts as much as December's 12,240. The year's growth weighs each month by its
size, because it is computed on the totals. December grew 8.4% and is the largest month, so it pulls
the year up more than it pulls the average. When somebody asks how much the year grew, the answer is
the one from the totals. An average of rates is a different number, and it is right only when every
month is the same size.

## Growth compounds

If Varanda grew 5.7% a year for three years, how much bigger would it be at the end? Not 3 × 5.7,
which is 17.1. Each year's growth is on a base the previous year already raised:

```localised
=ROUND((1.057^3-1)*100,1)      18.1
```

**18.1%, a point more than the sum.** Over three years the gap is small; over ten it is large, and
it is the reason lesson 16 measures growth across years with a rate that compounds. The same
arithmetic runs the other way, and it surprises people more. Sales that fall 10% one month and rise
10% the next do not come back where they started:

```localised
=100*0.9*1.1      99
```

The rise was 10% of 90, not of 100. A store manager who says "we lost 10% and we got it back" has
lost 1% on the way.

## Percent and percentage points

December was 12.2% of Varanda's sales in 2024 and 12.5% in 2025. How much did December's share grow?
There are two right answers, and they are different numbers:

```localised
=ROUND(C13/C14*100-B13/B14*100,1)      0.3
=ROUND((C13/C14)/(B13/B14)*100-100,1)      2.6
```

**The share rose by 0.3 percentage points, and it rose by 2.6 percent.** The first is the difference
between two percentages; the second is the growth of one percentage over the other. Both are
correct, and writing "December's share rose 0.3%" is wrong, because 0.3 is in points, not percent.
The word decides which number the reader thinks of, and when the share is small the gap between them
is large. Lesson 12 comes back to this with numbers chosen to mislead, which is where the difference
does real damage.
