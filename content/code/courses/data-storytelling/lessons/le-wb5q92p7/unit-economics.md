---
title: Faro's unit economics, in a spreadsheet
version: 1
---

**Unit economics** is the arithmetic of one customer: what they cost, what they bring, and when the two
cross. It is a handful of multiplications, and doing them yourself is what lets you answer a finance
question in the room instead of promising to ask finance.

## Margin per box

```localised
=189.9*0.31
```

Price times gross margin. Calc gives **58.869**: R$ 58.87 of margin from each box.

## How long a customer stays

Faro's customers who survive the first ninety days then leave at about 4% a month. When a constant share
leaves each month, the average remaining stay is one divided by that share, so **1 / 0.04 = 25 months**,
plus the three already survived:

```localised
=3+1/0.04
```

Calc gives **28** months. The 4% is Faro's measured rate; the formula assumes it stays constant, which is
the kind of assumption the finance team should confirm before the number goes on a board slide.

## Lifetime value, two ways

```localised
=189.9*0.31*(3+1/0.04)
```

For a customer who survives: **R$ 1,648.33** of margin over their lifetime. For one who cancels early, the
1.6 boxes instead of 28:

```localised
=189.9*0.31*1.6
```

**R$ 94.19.** The difference, R$ 1,554.14, is what each early cancellation costs Faro in margin it would
otherwise have earned.

## Two ratios finance will ask about

- **LTV to CAC.** R$ 1,648.33 against R$ 152 is **10.8**. A common rule of thumb in subscription businesses
  treats three as healthy; Faro's survivors are very profitable, which is why losing them early hurts.
- **Payback.** R$ 152 divided by R$ 58.87 is **2.6 boxes**. An early canceller, at 1.6, never gets there.

Put these formulas in a spreadsheet saved next to `faro.csv`, as `faro.ods`, with a label in the next
cell saying what each one is. When Renata asks where R$ 1,554 came from, **the answer is a file she can open**, which is
a stronger answer than any sentence.
