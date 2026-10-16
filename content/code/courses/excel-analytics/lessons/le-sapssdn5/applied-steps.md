---
title: Applied Steps, and the code behind them
version: 1
---

**A query is a list of steps read from the top, and each step works on the result of the one
before it, by name.** That one fact explains why the order of steps changes the answer, why
deleting a step in the middle breaks the ones below it, and how to read the error when a source
changes under you.

## The whole query at once

**Home › Advanced Editor** opens the query as one block of M, the same lines the formula bar shows
one at a time. Open it on `WebOrders` and you will recognise the shape from sections 02 and 05:
`let`, a list of named steps separated by commas, `in`, and the name of the last one. Each line
reads the step above it, as `Table.SelectRows(#"Changed Type with Locale", …)` reads the locale
step.

You can edit here, and sometimes it is the quickest way, but the clicks remain the safer habit.
A step made by a command is one Excel knows how to reopen: the gear icon beside a step in **Applied
Steps** brings back the dialog that made it, with its choices, so you can change them without
touching any code.

## Order is part of the answer

Three examples from this lesson, each with the number it changes:

| this step first | then this | gives | the other way round gives |
|---|---|---|---|
| uppercase the codes | merge with `Products` | **22 of 22** rows matched | 20 of 22, two orders with no cost |
| keep the paid orders | group by product | `SUL250` **5** bags | 6, counting a cancelled bag |
| set `Price` to a number | multiply it by `Bags` | the revenue | an error in every row: text cannot be multiplied |

**Move a step by dragging it** up or down the list, or right-click it and choose **Move Before** or
**Move After**. To add a step in the middle, select the step it should follow and use the command:
Excel asks before inserting it there, since every step below will now read something different.

## Deleting, and what breaks

Right-click a step and **Delete** removes it. The steps after it now read what came before it,
which is harmless when they did not depend on what it did, and fatal when they did. Delete the
renaming step of section 02, and the custom column's `[Bags] * [Price]` names two columns that no
longer exist under those names: every row of `Revenue` becomes an error. **Delete Until End**
removes a step and everything after it, which is the safe way to start again from a point.

## The error that says a column was not found

Lesson 13 section 04 warned that a platform may rename a column. Suppose next month's export
calls `Qty` by the name `Quantity`. Refresh, and the locale step, which names `Qty`, stops with a
message of this form:

```
Expression.Error: The column 'Qty' of the table wasn't found.
```

Read it literally: a step asked for a column by name, and the table it received has no column by
that name. Click through **Applied Steps** from the top, and the last step that works is the one
before the failure; its preview shows the column under its new name. The repair is a step that puts
the old name back, a rename of `Quantity` to `Qty`, inserted before the step that failed, so that
every step below keeps working as written. When the change is permanent, editing the names in the
failing step itself is the cleaner fix.

The automatic **Changed Type** step that Excel adds when it detects types is the commonest place
for this error, because it names every column of the file. That is one more reason, after lesson
13's locale, to set types yourself and only on the columns you use.

## Naming the steps

Step names like `Filtered Rows` and `Added Custom` say what command made a step, not why.
Right-click › **Rename** and call it `Kept paid orders` or `Revenue`, and every reference to it in
the code is renamed with it. A query read six months later by somebody else, or by you, explains
itself.

## Which query feeds which

This lesson has built a small web of queries: `WebOrders` feeds `WebMargin`, `WebAsSales` and
`WebByProduct`; `WebAsSales` and `Sales` feed `AllSales`; `Budget` and `Sales` feed
`BudgetVsActual`. **View › Query Dependencies** in the editor draws it, from the files and tables
on the left to the loaded results on the right. Before deleting or renaming a query, look there:
anything with an arrow from it will break.
