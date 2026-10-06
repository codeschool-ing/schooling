---
title: Which summary each scale can carry
version: 1
---

Everything so far comes down to one table. Find the column's scale, and the table says which
summaries describe it honestly.

| scale | example | count, mode | median, percentiles | mean, standard deviation | ratios |
|---|---|---|---|---|---|
| nominal | payment | yes | no | no | no |
| ordinal | rating | yes | yes | with care | no |
| interval | °C | yes | yes | yes | no |
| ratio | basket | yes | yes | yes | yes |

Read it as a set of permissions. Moving down a row never takes a permission away.

## Using it

Faced with a new column, the steps are short:

1. Ask whether the values are names or amounts. Names are nominal or ordinal; amounts are interval
   or ratio.
2. For names, ask whether they have an order. If they do, the median is available.
3. For amounts, ask whether zero means none of it. If it does, ratios are available.

Apply it to Horta's columns. *neighbourhood*: names with no order, so **nominal**: report counts and
shares. *rating*: names with an order, so **ordinal**: report the median and the distribution, and
the mean with a caveat. The temperature at the door, which Horta's system also records in °C: amounts with an arbitrary
zero, so **interval**: report means and differences. *basket*: amounts with a true zero, so **ratio**:
everything is available.

## A summary that is allowed can still mislead

The table answers *may I?*, not *should I?*. A basket column permits a mean, and lesson 4 shows a
case where the mean is the worst number you could report. Being allowed is the first test a summary
has to pass, not the last.

## And the software does not know

None of this is stored in a spreadsheet. A column of digits is a column of numbers to the software,
whether it holds baskets, ratings or postcodes. The software will compute an average of anything you
point it at. The scale lives in your head and in your documentation, and that is why the next
section exists.
