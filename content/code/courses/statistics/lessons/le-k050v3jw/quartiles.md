---
title: Quartiles
version: 1
---

The **quartiles** are the three values that cut sorted data into four equal parts.

- **Q1**, the first quartile: a quarter of the data at or below it. The 25th percentile.
- **Q2**, the second quartile: the median. The 50th percentile.
- **Q3**, the third quartile: three quarters at or below it. The 75th percentile.

## The twelve delivery times

Sorted, they are

```localised
27.5   29.0   31.5   33.0   34.5   36.0   38.5   39.0   41.0   44.0   52.5   61.0
```

With the spreadsheet's rule, Q1 sits at position 0.25 × 11 + 1 = 3.75, three quarters of the way from 31.5 to 33.0, so **Q1 = 32.625**. Q3 sits at position 9.25, a quarter of the way from 41.0 to 44.0, so **Q3 = 41.75**. The median, as lesson 3 found, is 37.25.

```localised
=QUARTILE.INC(A2:A13, 1)      32.625
=QUARTILE.INC(A2:A13, 3)      41.75
```

## Three rules, three answers

Here is something that surprises people: **there is more than one correct way to compute a quartile**, and they give different answers on small data.

| method | Q1 | Q3 |
|---|---|---|
| `QUARTILE.INC`, the spreadsheet default | 32.625 | 41.75 |
| `QUARTILE.EXC`, another spreadsheet option | 31.875 | 43.25 |
| median of each half, the usual hand method | 32.25 | 42.5 |

The hand method splits the twelve values into the lower six and the upper six and takes the median of each: (31.5 + 33.0) ÷ 2 = 32.25 and (41.0 + 44.0) ÷ 2 = 42.5. The two spreadsheet functions interpolate with slightly different position rules. Statistical software offers about nine variants in all.

None of them is wrong. They disagree because a quarter of twelve values does not fall neatly on a value, and each rule makes a different choice about where between two values the cut should go. **On large data the differences shrink to nothing**; on twelve values they are about a minute.

The practical rule: **pick one method and use it throughout a piece of work**, and when comparing your quartiles with somebody else's, check which method they used before concluding that the data differ. This course uses `QUARTILE.INC` from here on.
