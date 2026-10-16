---
title: AVERAGEIFS, and what is being averaged
version: 1
---

**An average is a total divided by a count, and the hard part is deciding what the count counts.**
`AVERAGEIFS` takes the same arguments as `SUMIFS`, with the range to average first, and divides
for you. That convenience hides the choice, and the choice changes the answer.

## Bags per sale, by channel

```localised
=AVERAGEIFS(E2:E109, G2:G109, "Wholesale")
```

answers **10.605…**, about 10.6 bags per wholesale sale. The same formula with `"Online"` gives
**3.17** and with `"Shop"` **1.70**, rounded to two places. A wholesale order is more than three times
the size of an online one.

It is exactly the total divided by the count, as you can prove in the next cell:

```localised
=SUMIFS(E2:E109, G2:G109, "Wholesale")/COUNTIFS(G2:G109, "Wholesale")
```

gives the same 10.605…, from 403 bags over 38 sales. Writing it this way once is worth the extra
typing, because it shows what `AVERAGEIFS` divides by: **rows that passed**, here sales.

## When no row passes

```localised
=AVERAGEIFS(E2:E109, D2:D109, "CER1K", G2:G109, "Shop")
```

answers `#DIV/0!`. Café Serra has never sold a 1 kg bag of Cerrado over the counter, so the count is
zero and there is nothing to divide by. That error is information: it says the group is empty,
which is different from a group whose average is zero. Hiding it behind `IFERROR`, from lesson 3,
would turn *no sales* into a blank or a 0 that a reader takes as a measurement.

## Per sale or per bag

What did Café Serra get for a 1 kg bag of Cerrado? Two formulas give two answers:

```localised
=AVERAGEIFS(F2:F109, D2:D109, "CER1K")
=SUMIFS(H2:H109, D2:D109, "CER1K")/SUMIFS(E2:E109, D2:D109, "CER1K")
```

The first answers **110.107…**, about R$ 110.11. The second answers **106.78**. Both are
averages of the price of `CER1K`; they disagree because they count different things.

`AVERAGEIFS` averages the `Price` column over **sales**. A wholesale sale of 15 bags at R$ 104
counts once, exactly like an online sale of one bag at R$ 115. The second formula divides revenue,
R$ 21,356, by **bags**, 200, so the fifteen wholesale bags count fifteen times. Wholesale customers
buy many bags at a lower price, so weighting by bags pulls the average down.

Neither is wrong; they answer different questions. *What does a typical sale of `CER1K` charge per
bag* is the first. *What did a bag of `CER1K` bring in* is the second, and it is the one that
multiplies back: 106.78 × 200 bags is the R$ 21,356 of revenue, which 110.11 × 200 is not. When an
average is going to be multiplied by a quantity, as in a forecast or a budget, it has to be the
one weighted by that quantity.

## Never average the averages

The same mistake in a different shape: the three channel averages of bags per sale are 10.6, 3.17
and 1.70, and their plain average is about 5.16. The real average over all 108 sales is

```localised
=AVERAGE(E2:E109)
```

which answers **5.472…**, 591 bags over 108 sales. Averaging the three gave each channel
the same weight, as if 38 wholesale sales and 23 shop sales were the same number of sales. An
average of averages is right only when every group has the same count, which in real data almost
never happens. Go back to the totals and divide once.
