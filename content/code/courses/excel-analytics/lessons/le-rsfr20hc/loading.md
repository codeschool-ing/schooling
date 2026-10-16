---
title: Where a query's result goes, and when it refreshes
version: 1
---

**Where a query's result lands is a separate decision from what the query does, and it can be
changed at any time without touching a single step.** So far this lesson has used two answers:
a table on a new sheet, and a connection with no table at all. There is a third, and the choice
between the three is about who reads the result.

## The three destinations

**Home › Close & Load** sends the result to the default, a table on a new sheet. **Home › Close &
Load To…** opens the **Import Data** dialog instead, which offers the choices:

| choice | what you get | when it is right |
|---|---|---|
| **Table** | the rows on a sheet, as an Excel table named after the query | a person needs to read or filter the rows, or a formula needs them |
| **PivotTable Report** or **PivotChart** | a pivot built straight on the query, with no rows on any sheet | the rows are only ever read summarised |
| **Only Create Connection** | nothing on any sheet; the query exists and other queries can use it | an intermediate step, like `Sales` and `Products` in section 05 |

Under them, a box called **Add this data to the Data Model** loads the rows into the model that
lesson 15 builds, where tables are related to each other instead of looked up. Leave it unticked
for now; lesson 15 comes back to it.

To change the destination of a query that already exists, open **Data › Queries & Connections**,
right-click the query and choose **Load To…**. The same dialog opens. Changing a table to a
connection removes the table from its sheet, and says so before it does.

## What the pane tells you

The **Queries & Connections** pane lists every query with one line under its name. For `WebOrders`
it reads **24 rows loaded**, which is the same check lesson 1 section 05 made with `COUNTA`, done
for you: if the number is not the one you expected, something upstream is wrong. For `Sales` it
reads *Connection only*.

When some cells could not be converted, such as the courier's dates read with the wrong locale in
section 03, the line also says how many **errors** there were, and clicking it opens a query that
lists the rows holding them. An error in a loaded table arrives as an empty cell, so this line is
often the only place the problem shows.

## Refreshing

A query runs when it is told to:

- **Data › Refresh All** runs every query in the workbook, in the order they depend on each other;
- right-click one query in the pane and **Refresh** runs that one, and any it reads from;
- in the pane, right-click › **Properties…** opens the query's settings, where **Refresh data when
  opening the file** makes the workbook refresh itself on opening, and **Refresh every … minutes**
  does it on a timer while the file is open.

Refreshing on opening suits a file other people open, such as lesson 17's dashboard, because they
see current numbers without knowing a query exists. It also means the file reads its sources every
time anybody opens it, and somebody who cannot reach those files gets an error instead of the
numbers you saw. Lesson 17 comes back to this when the dashboard is shared.

## Do not type into a loaded table

A loaded table is the query's output, and the query owns it. Type a correction into a cell of
`WebOrders` and it stays there only until the next refresh, which writes the query's result over
it. If a value in the source is wrong, fix it in the source file or with a step, and the fix
survives every refresh after it. A correction typed into the output is a correction somebody makes
again every month.

## What you have now

At the end of this lesson the workbook should hold these queries, and lesson 14 starts from them:

| query | from | loaded to |
|---|---|---|
| `WebOrders` | the `web` folder, three files | a table on its own sheet, 24 rows |
| `Freight` | `freight-2026-q3.csv` | a table on its own sheet, 20 rows |
| `Sales` | the `Sales` table of this workbook | connection only |
| `Products` | the `Products` table of this workbook | connection only |

Save the workbook. Its sheets and formulas from lessons 1 to 12 are untouched: every query reads
from them or from your files, and none of them writes to anything but its own table.
