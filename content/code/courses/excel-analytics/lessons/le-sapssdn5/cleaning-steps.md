---
title: Cleaning, one step at a time
version: 1
---

**Each cleaning command adds one step, and the steps run in order on every refresh, so a
cleaning done once is done for every month that follows.** This section cleans `WebOrders`, the
three web-shop exports lesson 13 combined, with five steps. None of them touches the files.

Lesson 13 left the query with **24 rows** and seven columns, and with three things wrong in them:
two cancelled orders, two product codes in lower case (`dec250` and `mog250`), and columns named by
the platform rather than by you. As in lesson 13, **nothing here was run in Excel**: each number
below is what the same step gives when it is applied to the same rows by a script.

## Opening the query again

In **Data › Queries & Connections**, double-click `WebOrders`. The editor opens where lesson 13
left it, with the locale step last in **Applied Steps**. Every step you add now goes after it.

## The five steps

**1. Keep the paid orders.** Click the arrow in the `Status` header and choose **Text Filters ›
Equals…**, then type `paid`. The query drops to **22 rows**. Keeping what you want, rather than
removing what you do not, is a choice with a consequence: if the platform one day adds a status
called `refunded`, a filter that keeps `paid` leaves it out, and a filter that only removed
`cancelled` would let it in.

**2. Make the codes upper case.** Select the `SKU` column and choose **Transform › Format ›
UPPERCASE**. `dec250` becomes `DEC250`, and the column now holds six distinct codes instead of
eight. In the same menu, **Trim** removes spaces at either end of a text, which is the other common
reason two codes that look equal are not.

**3. Remove what nobody needs.** Select `Source.Name` and `Status` with Ctrl-click and choose
**Home › Remove Columns**. `Status` has done its job, since every remaining row is paid, and the
months are in `Date`.

**4. Rename the columns.** Double-click a header and type: `SKU` becomes `Product`, `Qty` becomes
`Bags`, `Unit price` becomes `Price`. These are the names the `Sales` table uses, and section 04
relies on that. Renaming several columns one after another makes a single step.

**5. Add the revenue.** Choose **Add Column › Custom Column**, name the column `Revenue` and write
the formula `[Bags] * [Price]`. A name in square brackets is a column of the same row, the way
`[@Bags]` is in an Excel table. A custom column arrives with no type, so finish with the type
icon at the left of its header: **Decimal Number**.

`WebOrders` now holds **22 rows** and six columns, `Order`, `Date`, `Product`, `Bags`, `Price` and
`Revenue`, with **58 bags** and a revenue of **R$ 3,125.50**. Close it with **Home › Close & Load**,
and the table on its sheet is replaced by the clean one.

## What the five steps look like as code

Each command wrote one line of M. These are the lines the five steps added, after the locale step
lesson 13 made:

```schooling-example
{"language": "powerquery", "file": "WebOrders", "parts": [
 {"code": "    #\"Filtered Rows\" = Table.SelectRows(#\"Changed Type with Locale\", each [Status] = \"paid\"),", "note": "`each` means \"for every row\": the row is kept when its `Status` equals `paid`. The step reads the one before it by name."},
 {"code": "    #\"Uppercased Text\" = Table.TransformColumns(#\"Filtered Rows\", {{\"SKU\", Text.Upper, type text}}),", "note": "Applies `Text.Upper` to every value of one column and leaves the others alone."},
 {"code": "    #\"Removed Columns\" = Table.RemoveColumns(#\"Uppercased Text\", {\"Source.Name\", \"Status\"}),", "note": "Names the columns it removes. If one of them ever stops existing, this is the step that fails, which section 07 comes back to."},
 {"code": "    #\"Renamed Columns\" = Table.RenameColumns(#\"Removed Columns\", {{\"SKU\", \"Product\"}, {\"Qty\", \"Bags\"}, {\"Unit price\", \"Price\"}}),", "note": "Old name, new name, in pairs. Three renames in a row became one step."},
 {"code": "    #\"Added Custom\" = Table.AddColumn(#\"Renamed Columns\", \"Revenue\", each [Bags] * [Price]),\n    #\"Changed Type\" = Table.TransformColumnTypes(#\"Added Custom\", {{\"Revenue\", type number}})", "note": "The formula is computed once per row. The type follows as a step of its own, because the custom column was created without one."}
]}
```

You can read a query this way without ever writing one. Each line starts with the step's name as
it appears in **Applied Steps**, and each one names the step before it, which is how the list
becomes a chain. Section 07 of this lesson is about that chain.

## Other cleaning steps worth knowing

The same menus hold the rest of the everyday kit, and each one is also a step:

| command | where | what it does |
|---|---|---|
| **Replace Values** | Transform | swaps one value for another in a column, such as `n/a` for nothing |
| **Remove Duplicates** | Home › Remove Rows | keeps the first of rows that are equal in the selected columns |
| **Fill › Down** | Transform | copies a value into the empty cells below it, the repair for a report's group labels of lesson 1 section 07 |
| **Split Column** | Transform | the Power Query version of lesson 6's split, by a delimiter or a number of characters |
| **Data Type** | the icon at the left of a header | sets the type; a column of dates with a time of day becomes plain days when its type is set to **Date** |

None of them changes the source, and every one of them runs again on next month's rows.
