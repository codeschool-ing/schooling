---
title: A robust z-score
version: 1
---

The z-score failed because both its ingredients, the mean and the standard deviation, are pulled by the very values it is trying to find. The fix is to swap them for robust ones: the **median** for the centre, and the **median absolute deviation** for the spread.

## The MAD

The **median absolute deviation**, or **MAD**, is the median of the distances from the median:

1. find the median;
2. compute each value's distance from it, ignoring the sign;
3. take the median of those distances.

For the twelve baskets with both typos, the median is R$ 68.20. The twelve distances from it, sorted, are 5.9, 5.9, 18.2, 20.4, 26.8, 32.6, 36.3, 49.7, 50.0, 55.3, 1,479.3 and 2,057.8. Their median, halfway between the sixth and seventh, is **R$ 34.45**.

The two typos produced the two enormous distances at the end, and the median of the distances ignored them, exactly as the median of the values does.

## The modified z-score

The robust version of the z-score, often called the **modified z-score**, is

```localised
modified z = 0.6745 × (value − median) ÷ MAD
```

The 0.6745 makes the modified z-score line up with the ordinary one when the data is normal: for normal data, the MAD is about 0.6745 standard deviations. A common rule, proposed by Boris Iglewicz and David Hoaglin, flags values with a modified z-score beyond **±3.5**.

For the two typos:

| value | z-score | modified z-score |
|---|---|---|
| R$ 2,126.00 | 2.52 | 40.29 |
| R$ 1,547.50 | 1.69 | 28.96 |

The ordinary z-scores flagged nothing. The modified ones put both errors dozens of units out, far past 3.5. The ordinary baskets, meanwhile, stay small: R$ 95.00 has a modified z of 0.52 and R$ 12.90 one of −1.08.

## On the clean data

Without the typos, the twelve correct baskets have the same median, R$ 68.20, and the same MAD, R$ 34.45, because neither depended on the two values that changed. The largest basket, R$ 212.60, has a modified z of 2.83: unusual, but inside 3.5, so not flagged. That matches what lesson 1 showed: H-1048 was a large order from Barão Geraldo, Horta's farthest neighbourhood, not an error.

## A spreadsheet has no MAD function

None of the common spreadsheets has a built-in MAD, but it takes one formula with the data in A2:A13:

```localised
=MEDIAN(ABS(A2:A13 - MEDIAN(A2:A13)))      34.45
```

It works on a whole range at once, so it has to be entered as an **array formula**, with Ctrl+Shift+Enter, in spreadsheets that do not do that by themselves. Entered that way, LibreOffice Calc returned 34.45 for the twelve baskets with both typos. Entered as an ordinary formula, it returned an error, which is the symptom to recognise.
