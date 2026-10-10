---
title: A table grows, and its formulas grow with it
version: 1
---

**A row typed directly under a table joins the table, and every formula that names the table
includes it at once.** That is the property the rest of the course leans on: a pivot table, a chart
or a drop-down list built on `Sales` covers next month's sales without anybody editing it. This
section adds one sale to see it happen, then takes it out again.

## Adding a sale

Café Serra sells six bags of `CER1K` to `C01` on 29 June 2026. On the `Sales` sheet, click **A110**,
the first empty cell under the table, and type the sale across the row, pressing **Tab** between
cells:

| A | B | C | D | E | F | G |
|---|---|---|---|---|---|---|
| `S1109` | `2026-06-29` | `C01` | `CER1K` | `6` | `106` | `Wholesale` |

As soon as you leave A110, the banding reaches row 110: the table took it in. And H110, which you
never touched, already shows **636**, because `Revenue` is a calculated column and a new row gets
its formula.

```schooling-figure
{"svg": "<svg data-fig=\"l07-grow\"></svg>", "caption": ""}
```

Now compare the two ways of asking for the bags, in an empty cell outside the table:

```localised
=SUM(Sales[Bags])
=SUM(E2:E109)
=ROWS(Sales[Sale])
```

The first answers **597** and the second **591**. The address still stops at row 109, so the new
sale's six bags are not in it, and no error says so. The table name follows the table, and
`ROWS` now counts **109** sales. `=SUM(Sales[Revenue])` has gone from 51,494 to **52130**, the 636
of the new sale included.

## What stops a table growing

- **A gap.** A row typed in A111 with A110 left empty does not join; the table grows only into the
  row that touches it.
- **A switched-off option.** The growing is an AutoCorrect setting, **Include new rows and columns in
  table**, under **File › Options › Proofing › AutoCorrect Options › AutoFormat As You Type**. It is
  on unless somebody turned it off. If a typed row stays outside, look there.
- **A total row.** With the total row of section 05 switched on, the row under the last sale is the
  total, so typing below it does not extend the data. Press **Tab** in the last cell of the last
  sale instead, which adds a new row inside the table.

Pasting several rows directly under the table extends it just as typing does, which is how a
month of new sales would normally arrive. The table also grows sideways: a header typed in the
first empty column beside it becomes a new column, which section 06 uses.

## Taking it out again

S1109 is not one of the course's sales, and every number from here on is computed on the 108. Click
any cell of row 110, right-click, and choose **Delete › Table Rows**. Deleting the row of the sheet
would do the same here, but **Table Rows** deletes only inside the table, which is the habit to
keep when other things share the sheet. Then check:

```localised
=SUM(Sales[Bags])
```

answers **591** again, and the table ends on row 109.
