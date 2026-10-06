---
title: How many to ask
version: 1
---

The margin of error depends on three things: the confidence level, the spread of the data and the sample size. The first is chosen, the second is a property of what is measured, and the third is what you control. So the margin formula can be turned around to say how large a sample must be.

## For a proportion

The margin for a proportion is 1.96 × √(*p*(1 − *p*) ÷ *n*). Solve for *n*:

```localised
n = 1.96² × p × (1 − p) ÷ margin²
```

Before the survey, *p* is unknown, so use the worst case, 0.5:

- for a margin of **5 points**: 1.96² × 0.25 ÷ 0.05² = 384.2, so **385 people**;
- for a margin of **3 points**: 1.96² × 0.25 ÷ 0.03² = 1,067.1, so **1,068 people**.

Always round **up**: 384.2 people means 385, because 384 would leave the margin slightly over 5 points.

That 1,068 is why so many national opinion polls interview about a thousand people. Lesson 10 explained why the size of the country hardly matters: the margin depends on the sample, not on the population.

## For a mean

For a mean the formula needs a guess at the standard deviation, from earlier data or a pilot sample:

```localised
n = (1.96 × s ÷ margin)²
```

Horta's baskets have a standard deviation of about R$ 59. To estimate the mean basket to within **R$ 10**, Horta needs (1.96 × 59 ÷ 10)² = 133.7, so **134 orders**. To within **R$ 5**, it needs (1.96 × 59 ÷ 5)² = 534.9, so **535 orders**.

Halving the margin quadrupled the sample: lesson 11's square root, showing up in the budget.

## A survey plan in four lines

1. Decide the margin that would change a decision: is ±5 points enough to tell whether satisfaction has fallen, or is ±3 needed?
2. Decide the confidence level, usually 95%.
3. Compute *n*, and round up.
4. Inflate it for non-response: if experience says one invitation in four is answered, invite four times *n*, and remember that the answers still come from the people who chose to reply, which lesson 10 warned about.

The order matters. A survey that collects whatever it can and then reports a margin has let the budget decide the precision. A survey that decides the precision first can tell, before any money is spent, whether the question is worth asking.
