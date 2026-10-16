---
title: The total row, and totals that follow a filter
version: 1
---

**A table's total row adds up what is visible, so it changes when you filter and stays put when
you do not.** That makes it the quickest way to answer *how much, for the rows I am looking at*.
It also makes it the wrong place to keep a number anybody will quote later, because a filter is not
written down anywhere a reader will look.

## Switching it on

Click inside the `Sales` table and tick **Total Row** on the **Table Design** tab. A row appears
under the last sale, with `Total` in column A and, under `Revenue`, **51494**.

Click the total row's cell under `Bags`. It has a small arrow that opens a list of functions:
**Sum**, **Count**, **Average**, **Max** and others. Choose **Sum**, and the cell shows **591**.
Click it again and read the formula bar:

```localised
=SUBTOTAL(109,[Bags])
```

That is what the total row writes for every function in its list: `SUBTOTAL`, with a number that
says which calculation to do. 109 means *sum*; 101 would be an average and 103 a count. Inside the
table the column is written `[Bags]`, without the table name.

## Filtering

Open the filter button on the `Channel` header, leave only **Wholesale** ticked, and click **OK**.
The table now shows the 38 wholesale sales, and the total row answers **403** bags and **38731** of
revenue: the same numbers `SUMIFS` gave in lesson 5, without a condition anywhere.

Now type, in a cell outside the table,

```localised
=SUM(Sales[Bags])
=SUBTOTAL(109, Sales[Bags])
```

The first still answers **591**: `SUM` adds every row of the column, visible or not. The second
answers **403**, like the total row, because `SUBTOTAL` leaves out the rows a filter hides. Counting
the visible sales works the same way:

```localised
=SUBTOTAL(103, Sales[Sale])
```

answers **38**.

## 9 or 109

`SUBTOTAL` takes two families of function numbers. Both leave out rows hidden by a **filter**. They
differ on rows somebody hid **by hand**, with right-click › **Hide**: 1 to 11 still count those,
and 101 to 111 leave them out. So `SUBTOTAL(9, …)` and `SUBTOTAL(109, …)` agree on this filtered
table, and disagree as soon as somebody hides a row themselves. The total row uses the 100s, so it
always adds what is on screen and nothing else, which is the only rule a reader can check by looking.

## Where a filtered total belongs

A filtered total answers a question for the person looking at the screen. Copy it into a report
and the filter that produced it is lost: the next reader sees 403 and has no way to know it means
*wholesale only*. A number that will be quoted belongs in a formula that states its own condition,
which is what `SUMIFS` is for. Use the total row to look, and `SUMIFS` to keep.

Before you go on, clear the filter with the button on the `Channel` header, **Clear Filter From
"Channel"**, so that all 108 sales show. Then untick **Total Row**: the later lessons work with the
table without it, and it leaves the row under the last sale free.
