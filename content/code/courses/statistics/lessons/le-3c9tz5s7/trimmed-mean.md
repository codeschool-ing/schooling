---
title: The trimmed mean
version: 1
---

The mean uses every value's size and the median uses almost none. A **trimmed mean** sits between them: sort the values, cut off a fixed share at each end, and take the mean of what remains.

## Trimming the payroll

Sort Horta's nine salaries and remove one from each end — the lowest R$ 2,100 and the founder's R$ 28,000. The seven left are 2,100, 2,250, 2,300, 2,400, 2,600, 2,900 and 3,400, and their mean is **R$ 2,564.29**.

That is close to the median of R$ 2,400 and nowhere near the mean of R$ 5,338.89. Trimming one value at each end was enough, because only one value was extreme.

## Trimming the baskets

For larger data the cut is a percentage. A **10% trimmed mean** of the 400 baskets drops the 40 smallest and the 40 largest and averages the 320 in the middle:

| summary | value |
|---|---|
| mean | R$ 82.78 |
| 5% trimmed mean | R$ 76.28 |
| 10% trimmed mean | R$ 73.31 |
| median | R$ 66.74 |

As the trim grows the trimmed mean moves from the mean towards the median. Trim half from each end and you have nothing left but the middle, which is the median. The mean and the median are the two ends of one family, and the trim chooses a place between them.

Spreadsheets have it built in. With the baskets in A2:A401:

```localised
=TRIMMEAN(A2:A401, 0.2)      73.31309375
```

That is the value LibreOffice Calc returned for the course's 400 baskets. The second argument is the **total** share removed, split between the two ends, so 0.2 drops 10% from each end. It is easy to get wrong, and getting it wrong trims twice as much as you meant.

## Where it is used

Trimmed means turn up wherever a few extreme values are expected and should not decide the result. Judged sports such as diving drop the highest and lowest judges' scores before averaging the rest, so that one generous or harsh judge cannot decide a medal. Some official price statistics use a trimmed mean of price changes as a measure of underlying inflation, so that one product's price jump does not dominate the month.

Its weakness is the same as its strength: it throws data away. If the extreme values are real and matter — the founder's salary for the payroll, the big baskets for the revenue — trimming them hides exactly what needed seeing.
