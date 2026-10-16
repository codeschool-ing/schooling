---
title: Turning a range into a table
version: 1
---

**A range is an address; a table is a named object that knows its own edges and the names of its
columns.** `E2:E109` in lesson 5 meant *the bags*, but only while the sales ended on row 109. The
address said nothing about bags and nothing about where the data stopped, so the first sale added
on row 110 would sit outside every formula. An Excel table keeps track of both for you.

## Making the three tables

Before you start, the data must stand alone: nothing typed in the row under it or in the column
beside it. The lessons before this one asked you to delete their helper cells, from column J
onward, for exactly this reason. Then, on the `Sales` sheet:

1. Click any cell inside the data, for example **A1**.
2. Use **Insert › Table**, or press **Ctrl+T** (on a Mac, **Cmd+T**).
3. Excel proposes the range `=$A$1:$H$109` and ticks **My table has headers**. Check both, then
   click **OK**.
4. With a cell of the table selected, a **Table Design** tab appears on the ribbon. Its left end has
   a **Table Name** box holding something like `Table1`. Type `Sales` there and press Enter.

Do the same on the other two sheets: `Products`, from A1 to G7, named `Products`, and `Customers`,
from A1 to F12, named `Customers`. A table has the same name as its sheet here because that is the
clearest choice, and Excel keeps the two kinds of name apart.

If Excel proposes a bigger range than the one above, something is touching the data, usually a
forgotten helper cell. Cancel, delete it, and start again. If it proposes a smaller one, there is an
empty row or column inside the data, which lesson 1 section 07 warned about.

A table name may not contain spaces and may not look like a cell address, so `Sales 2025` and `S1`
are both refused. `Sales`, `Products` and `Customers` are what every later lesson calls them.

## What changed, and what did not

The values are where they were. The table adds four things around them:

- **bands of colour** on alternate rows, which are only a style and can be changed or removed on
  the **Table Design** tab;
- **filter buttons** in every header cell, so that sorting and filtering always cover the whole
  table and never half of it;
- **headers that stay visible**: scroll down past row 1 and the column letters at the top of the
  sheet are replaced by `Sale`, `Date`, `Customer` and the rest;
- **names**: the table is now called `Sales`, and each column is called by its header.

The last one is what the next four sections use.

## Revenue as a calculated column

Column H still holds lesson 2's formulas, `=E2*F2` on row 2, `=E3*F3` on row 3, and so on. Inside a
table there is a better way to write them. Click **H2**, type

```localised
=[@Bags]*[@Price]
```

and press Enter. `[@Bags]` means *the Bags value on this row*. Excel fills the formula down the
whole column, and every row now holds the same text: one formula for the column instead of 108
copies of a pattern. That is a **calculated column**, and a new row gets it automatically. If Excel
does not fill the column by itself, click the small **AutoCorrect Options** button that appears
beside H2 and choose **Overwrite all cells in this column with this formula**.

The numbers do not change, and you can check it in an empty cell outside the table:

```localised
=SUM(Sales[Revenue])
```

answers **51494**, the R$ 51,494 of lesson 2.

To turn a table back into a plain range, **Table Design › Convert to Range** does it. Nothing in
this course needs that, and the tables stay until the end.
