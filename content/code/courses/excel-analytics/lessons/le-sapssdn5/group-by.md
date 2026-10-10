---
title: Group By, a summary that other steps can use
version: 1
---

**Group By collapses the rows that share a value into one row each, with the totals you ask for
beside it.** It is the summary a pivot table makes, with one difference that decides when to use
it: the result is a query, so another step can filter it, merge it or append it, and a pivot table
is the end of the line.

## Orders by product

Make a query for it: right-click `WebOrders` in the editor's **Queries** list, **Reference**, and
rename it `WebByProduct`. Then **Transform › Group By**, choose **Advanced**, and set:

- group by `Product`;
- a column `Orders`, operation **Count Rows**;
- a column `Bags`, operation **Sum**, of `Bags`;
- a column `Revenue`, operation **Sum**, of `Revenue`.

Use **Add aggregation** for each new column after the first. The 22 orders become **6 rows**, one
per product, sorted here by revenue:

| `Product` | `Orders` | `Bags` | `Revenue` |
|---|---|---|---|
| `DEC250` | 7 | 23 | 1,035 |
| `MOG250` | 5 | 12 | 610.50 |
| `CER1K` | 3 | 4 | 472 |
| `CER250` | 3 | 11 | 407 |
| `SUL1K` | 2 | 3 | 396 |
| `SUL250` | 2 | 5 | 205 |

The decaf sold most on the web this quarter, by orders, bags and money alike.

The grouping sees the rows as they stand after every step above it, which is why the order of steps
matters. `WebByProduct` reads `WebOrders` after section 02's filter, so the cancelled orders are not
in it. Grouped before that filter, `SUL250` would show 6 bags and `CER1K` 5, each counting a bag
nobody paid for. Section 07 comes back to order.

## The freight, made unique

Section 03 found that `W2014` has two rows in `Freight`, which doubled it in a merge. Group By is
the repair. Reference `Freight`, group by `Order`, and add one column, `Freight`, as the **Sum** of
`Freight`. The 20 rows become **19**, one per order, with the two shipments of `W2014` added
together. Merged with `WebOrders` by a Left Outer join, this gives **22 rows**, one per paid order,
and the revenue sums to R$ 3,125.50 again. When a merge grows a table, grouping the other side by
its key first is nearly always the fix.

## The budget against what was sold

Now the question the budget exists for: how did January to June 2026 go against the plan? The
actual figures come from `Sales`, the planned ones from section 05's `Budget`, and Group By puts
each in the same shape before a merge puts them side by side.

1. **Actual.** Reference `Sales`, name it `Actual2026`. Filter `Date` with **Date Filters › After…**
   and `2025-12-31`; `Sales` ends in June. Group by `Channel`, with one column,
   `Revenue`, the **Sum** of `Revenue`. Three rows.
2. **Plan.** Reference `Budget`, name it `Plan2026H1`. Filter `Month` with **Date Filters ›
   Before…** and `2026-07-01`. Group by `Channel`, with one column, `Budget`, the **Sum** of
   `Budget`. Three rows.
3. **Together.** **Merge Queries as New**: `Plan2026H1` on top, `Actual2026` below, both keyed on
   `Channel`, Left Outer. Expand `Revenue`, then add a custom column `Variance` with
   `[Revenue] - [Budget]`. Name it `BudgetVsActual`.

| `Channel` | `Budget` | `Revenue` | `Variance` |
|---|---|---|---|
| `Wholesale` | 15,000 | 11,128 | -3,872 |
| `Online` | 3,900 | 4,295 | 395 |
| `Shop` | 900 | 520 | -380 |

Against a plan of R$ 19,800 the half year sold R$ 15,943. The web shop beat its budget by about a
tenth; wholesale fell short by about a quarter, which is the line a manager reads first.

## Checking it against a formula

A number produced by a query deserves the same check lesson 1 gave the paste, and lesson 5 has the
tool. These two formulas, typed in any empty cell, total the 2026 revenue of a channel straight
from the sheet:

```localised
=SUMIFS(Sales!H:H, Sales!G:G, "Online", Sales!B:B, ">="&DATE(2026,1,1))
=SUMIFS(Sales!H:H, Sales!G:G, "Wholesale", Sales!B:B, ">="&DATE(2026,1,1))
```

They answer **4,295** and **11,128**, the `Revenue` of the query's first two rows. The formulas were
computed by a spreadsheet, like every formula of this course; the query's figures by a script that
applies its steps. Two different routes to the same number is the reason to trust both.

## Group By or a pivot table

They summarise the same way, and the choice is about what happens next:

- a **pivot table**, lessons 10 and 11, when a person is going to read the summary and rearrange it;
- **Group By**, when the summary is an input: to merge with a budget, to make a key unique before a
  merge, or to load a smaller table where the detail is never needed.

Load `BudgetVsActual` as a table on its own sheet. The other queries of this section, `WebByProduct`,
`Actual2026` and `Plan2026H1`, can stay as connections only.
