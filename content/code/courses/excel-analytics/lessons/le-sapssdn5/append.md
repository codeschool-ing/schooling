---
title: Append, one table under another
version: 1
---

**Append stacks the rows of two or more queries into one, and it lines the columns up by their
names, not by their position.** Columns with the same name become one column; a name that exists
on one side only becomes a column of its own, empty on the other side's rows. So the work of an
append is almost always done before it: making the names agree.

## The question

`Sales` ends in June 2026. `WebOrders` holds the web shop's July to September. One table with both
would let a pivot table see the whole history of the web channel, and that is what an append makes.

## The first attempt, and what it shows

Choose **Home › Append Queries › Append Queries as New**, pick `Sales` as the first table and
`WebOrders` as the second, and click **OK**. The result has **130 rows**, 108 and 22, which is
right, and **nine** columns, which is not.

| column | on the 108 rows from `Sales` | on the 22 rows from `WebOrders` |
|---|---|---|
| `Date`, `Product`, `Bags`, `Price`, `Revenue` | filled | filled: the names agree, so they are one column |
| `Sale`, `Customer`, `Channel` | filled | **empty**: `WebOrders` has no columns by these names |
| `Order` | **empty** | filled: `Sales` has no `Order` |

The order code is in `Order` on one side and in `Sale` on the other, so they sit in two columns,
each half empty. Nothing failed, and a pivot table of `Channel` would quietly show the 22 web
orders under an empty label. Section 02's renaming is why five of the columns already line up; the
other three need the same treatment.

Delete that query and do it again, properly.

## Making the names agree

The steps belong in a query of their own, so that `WebOrders` stays as it is for `WebMargin` and
anything else that reads it.

1. In the **Queries** list at the left of the editor, right-click `WebOrders` and choose
   **Reference**. A new query appears whose only step is `WebOrders` itself, so it follows every
   change made there. Rename it `WebAsSales`.
2. Rename `Order` to `Sale`.
3. **Add Column › Custom Column**, name `Customer`, formula `"C00"`. Every web order is a customer
   without an account, which is what `C00` means in lesson 1's `Customers`.
4. **Add Column › Custom Column**, name `Channel`, formula `"Online"`.

Now **Append Queries as New** with `Sales` and `WebAsSales`. The result has **130 rows** and the
eight columns of `Sales`, every one filled on every row. The order of the columns in `WebAsSales`
did not matter; only their names did. Set `Price` and `Revenue` to **Decimal Number**, since
September's promotion has centavos, and rename the query `AllSales`.

`AllSales` holds **649 bags** and a revenue of **R$ 54,619.50**: the R$ 51,494 of `Sales` and the
R$ 3,125.50 of the paid web orders. Its `Online` rows number **69**, the 47 of `Sales` and the 22
new ones.

Load `WebAsSales` and `AllSales` with **Close & Load To… › Only Create Connection**. Lessons 15 and
16 build their model on the `Sales` table as it is, ending in June 2026, so that their numbers agree
with lessons 1 to 12; `AllSales` is how the next quarter would join it.

## Append or From Folder

Both stack rows, and they suit different jobs:

- **From Folder**, lesson 13 section 04, stacks **files of one shape** from one place, and a new
  file joins by being saved there.
- **Append** stacks **queries**, which may come from different sources: a table and a folder here,
  or a workbook and a database. Each side can be shaped by its own steps first, which is what
  `WebAsSales` is for.

In both, the stacking is by name, and a column renamed on one side becomes a column of its own.
