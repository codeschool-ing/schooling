---
title: Filters and the pivot table, which is the one to learn
version: 1
---

Two tools turn a table into an answer, and one of them does more than everything else in this
lesson put together.

## Filters, and the two ways to lose data with one

A filter hides rows that do not match. It changes nothing and it is reversible, which makes it
the safest exploration there is — and it has exactly two hazards.

**The first: a copied selection copies only what is visible**, which is usually what you wanted
and occasionally a silent loss. A paste from a filtered range into an unfiltered one produces a
table with rows missing and no sign that any went.

**The second: `SUM` ignores the filter.** A total below a filtered column shows the total of
everything, including the hidden rows, and it looks like it is describing what is on screen.

`SUBTOTAL(109, range)` is the fix: it totals **only the visible rows** and it moves as the filter
moves. The `109` means *sum, ignoring hidden rows*; `101` is the average, `103` the count. It is
the function that makes a filter honest.

## Sorting, and the rule from lesson nine

**Select the whole range or use a table.** Sorting one column separates it from its rows,
irreversibly, and it is the only operation in this lesson that destroys data silently.

Two further facts:

- **A custom sort takes several levels** — region, then month, then value — which is what the
  three separate sorts people do by hand approximate badly.
- **Sorting by colour works**, which is occasionally exactly what is wanted and is a sign that the
  colour should have been a column.

## The pivot table

Select the table. Insert a pivot table. Drag a field into **Rows**, a field into **Columns**, and
a number into **Values**.

That is the whole of the interface, and what it does is produce the summary that would otherwise
be forty `SUMIF` formulas — grouped, totalled, and rebuilt in a second when the question changes.

| you drag | and you get |
|---|---|
| `region` into Rows, `amount` into Values | the total per region |
| `month` into Columns as well | a grid of region against month |
| `product` into Filters | the same grid, for one product at a time |
| `amount` into Values twice | the total and the count, side by side |

**Three things about it are worth knowing before you rely on one:**

- **It does not update by itself.** Add rows to the data and the pivot shows yesterday's answer
  until you refresh it. Building the pivot on a *table* rather than a range is what makes the
  range grow; refreshing is still a click.
- **Values default to Count when the column contains any text.** A `Count of Amount` where you
  expected a `Sum of Amount` is the text-in-a-number-column problem from lesson nine, announcing
  itself.
- **Double-clicking a number in a pivot produces a new sheet with the rows behind it.** That is
  the most useful checking tool in the product, and almost nobody knows it is there.

## Which of the two to reach for

**Filter to look at rows. Pivot to look at groups.** A question with the word *each* in it — the
total for each region, the average per month, how many of each kind — is a pivot table, and doing
it with formulas is an afternoon spent reproducing a feature.
