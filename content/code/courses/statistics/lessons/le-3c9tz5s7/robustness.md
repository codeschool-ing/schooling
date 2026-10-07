---
title: A typing error and two summaries
version: 1
---

Somebody types order H-1048's basket as R$ 2,126.00 instead of R$ 212.60: one slipped decimal point. What happens to the summaries of the twelve baskets?

| | correct | with the typo |
|---|---|---|
| mean | R$ 79.17 | R$ 238.62 |
| median | R$ 68.20 | R$ 68.20 |

The mean triples. The median does not move at all, because H-1048 was the largest basket before the typo and is still the largest after it. The median only cares that it is above the middle.

## The breakdown point

Statisticians measure this resistance with the **breakdown point**: the share of the data that would have to be wrong, by any amount, before a summary could be pushed as far as you like.

- **The mean breaks down with one value.** Make a single basket large enough and the mean goes wherever you push it. With *n* values the breakdown point is 1 out of *n*, which shrinks towards zero as the data grows.
- **The median breaks down at half.** To drag it anywhere you would have to corrupt half the values. Fewer than that, however wild, and the median stays among the honest ones.

A summary with a high breakdown point is called **robust**. The median is the standard example; the next section meets a compromise between the two.

## Robust is not the same as better

Robustness protects against values that should not be there: typos, a sensor that misfired, a test order somebody forgot to delete. It also ignores values that should be there. The founder's salary is real, and the payroll has to pay it. The R$ 421.78 basket is real money in the till.

So the question is never just "which is more robust?". It is **"are the extreme values errors, or are they part of what I am trying to describe?"** Lesson 9 is about answering that, one suspicious value at a time. Until then, a large gap between the mean and the median is a reason to look, not an instruction to switch.
