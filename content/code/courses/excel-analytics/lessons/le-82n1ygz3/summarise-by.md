---
title: Sum, count, average, and a share of the total
version: 1
---

**A field in Values is summarised by a function, and the function is a choice, not a fact about
the field.** Excel picks **Sum** for a column that holds only numbers, and **Count** for a column
that holds any text or any empty cell. Both defaults are guesses, and the pivot gives no sign of
which one it made beyond the words at the top of the column.

## Changing the summary

On the `By channel` pivot of section 02, click any number, then right-click and choose **Value
Field Settings**. The **Summarize Values By** tab lists **Sum**, **Count**, **Average**, **Max**,
**Min** and a few more. Each answers a different question about the same rows:

| summary of `Revenue` | Online | Shop | Wholesale | Grand Total |
|---|---|---|---|---|
| **Sum**: how much money | 11,143 | 1,620 | 38,731 | 51,494 |
| **Count**: how many sales | 47 | 23 | 38 | 108 |
| **Average**: a typical sale | 237.09 | 70.43 | 1,019.24 | 476.80 |

The averages are shown here to two decimals; the pivot shows as many as the cell's number format
allows. The count and the average have their formulas too:

```localised
=COUNTIFS(Sales[Channel], "Online")
=AVERAGEIFS(Sales[Revenue], Sales[Channel], "Wholesale")
```

**47** and **1,019.24**. The three rows of the table tell one story between them: wholesale is
fewer sales than online, each one about four times larger, and three quarters of the money.

Rename the column while you are in the dialog: **Custom Name** turns `Sum of Revenue` into
whatever the reader should see, such as `Revenue (R$)`. A name may not be exactly the name of a
field, so `Revenue` alone is refused; add a space or a word.

## The summary that means nothing

Drag `Price` into **Values**. It arrives as **Sum of Price**: 3,576 for Online, 943 for Shop,
3,589 for Wholesale. Those are real sums of real cells, and they mean nothing: adding the price of
a 250 g bag to the price of a 1 kg bag answers no question anybody has. A pivot will sum any
numeric column, so **the test is whether you can say in words what the number is**. "The total
revenue of online sales" passes. "The total of the prices of online sales" does not. Remove
`Price` from the box.

An average price per bag is a real question, and it is not the **Average of Price** either:
lesson 11 shows why, and how a calculated field answers it.

## Show Values As: a share instead of an amount

The second tab of **Value Field Settings**, **Show Values As**, keeps the summary and changes how
it is shown. Choose **% of Grand Total**:

| Row Labels | Sum of Revenue |
|---|---|
| Online | 21.64% |
| Shop | 3.15% |
| Wholesale | 75.21% |
| **Grand Total** | **100.00%** |

On the `Grid` pivot, with products down the side and channels across, **% of Column Total** says
what share of each channel's revenue each product brings, and **% of Row Total** says how each
product's revenue splits between the channels. The same grid, three questions, depending on which
total a cell is divided by. Set it back to **No Calculation** to see amounts again.

A share hides the size it is a share of. Wholesale's 75.21% does not say that it is R$ 38,731, and
the shop's 3.15% does not say that it is 23 sales. When a share matters, put the amount beside it:
drag `Revenue` into **Values** a second time and show one copy as an amount and the other as a
percentage.
