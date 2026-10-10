---
title: Tables in this workbook, and other workbooks
version: 1
---

**Inside your own workbook, Power Query reads an Excel table by its name; from another workbook,
it reads the file as it was last saved.** The first is how a table you already keep joins the
queries of lesson 14. The second is how a colleague's workbook becomes a source you refresh rather
than a range you copy.

## A table in this workbook

Lesson 7 turned `Sales!A1:H109` into a table named `Sales`. Click any cell inside it and choose
**Data › From Table/Range**. The editor opens on a query also called `Sales`, holding the **108
rows** and eight columns of the table, `Revenue` included. Its first step reads:

```powerquery
Source = Excel.CurrentWorkbook(){[Name="Sales"]}[Content]
```

That line is the reason to use a table rather than a range. It names the table, not the cells, so
when a sale is added under the last row and the table grows to row 110, the query reads 109 rows
at the next refresh without anyone touching it. Pointed at a plain range, the same command first
asks to turn it into a table, through the same **Create Table** dialog as lesson 7, for exactly
that reason.

This query should **not** be loaded to a sheet: that would make a second copy of `Sales`, which
then has to be kept in step with the first. Close the editor with **Home › Close & Load To…**,
choose **Only Create Connection**, and click **OK**. The query appears in **Queries & Connections**
marked *Connection only*, ready for lesson 14 to use.

Do the same for the `Products` table: click inside it, **Data › From Table/Range**, then **Close &
Load To… › Only Create Connection**. You now have two connection-only queries, `Sales` and
`Products`, and the workbook looks no different. `Customers` works the same way; lesson 14 does
not need it.

## Another workbook

Lesson 1 asked you to keep an untouched copy of the data, `cafe-serra-original.xlsx`. It makes a
good second source, because you know exactly what is in it.

Go to **Data › Get Data › From File › From Workbook** (on some versions **From Excel Workbook**)
and pick that file. A **Navigator** opens, listing what the file holds: three sheets, `Sales`,
`Products` and `Customers`, each with a sheet icon. Had the file contained tables, they would be
listed too, with a table icon. Tick `Sales` and click **Transform Data**.

The query reads **108 rows** and seven columns: the original was saved in lesson 1, before lesson 2
added `Revenue`. Its steps differ from the table's:

```powerquery
Source = Excel.Workbook(File.Contents("C:\Users\you\Documents\cafe-serra-original.xlsx"), null, true),
Sales_Sheet = Source{[Item="Sales",Kind="Sheet"]}[Data],
#"Promoted Headers" = Table.PromoteHeaders(Sales_Sheet, [PromoteAllScalars=true])
```

A sheet is not a table, so the first row arrives as data and a **Promoted Headers** step turns it
into column names. And a sheet brings every cell anybody ever used on it, which is the difference
that matters: a note typed in `J1` of that sheet arrives as an extra column, mostly empty, and the
query has no way to know it is not data. A table brings its own rectangle and nothing else, so
when the other workbook is yours to arrange, make the data a table before you point a query at it.

Two things about the file itself are worth knowing:

- **The query reads the saved file.** Changes somebody has typed into it and not saved are not
  there. The usual surprise is a refresh that "did not pick up" a correction made a minute ago in
  a window still open.
- **The path is written into the query.** Move or rename the file and the next refresh fails with
  a message naming the path it could not find. **Data › Get Data › Data Source Settings** lists
  every file the workbook's queries read, and **Change Source…** there points one at the new place
  without opening the query.

This query was to see the Navigator, and nothing later uses it. Close the editor, then delete the
query from **Queries & Connections**. If you loaded it, delete its sheet too.
