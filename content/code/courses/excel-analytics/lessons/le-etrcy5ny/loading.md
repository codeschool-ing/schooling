---
title: Loading the three tables into the model
version: 1
---

**The model is filled from tables, never typed into.** Each table you load keeps its name, its
columns and its rows, and stays connected to where it came from. So the work before loading is the
work of lesson 7: `Sales`, `Products` and `Customers` are Excel tables with those names, and
`Sales` carries the `Revenue` column of lesson 2.

Check the names first. Click inside each table and look at **Table Design › Table Name**. A table
still called `Table1` goes into the model as `Table1`, and every DAX formula in lesson 16 would
then have to say `Table1[Revenue]`. Renaming it later is possible, and a name fixed before loading
is one less thing to break.

## Three doors into the model

1. **From a table on a sheet.** Click any cell of `Sales`, then **Power Pivot › Add to Data Model**.
   The Power Pivot window opens with `Sales` as a tab along its bottom edge. Go back to Excel and do
   the same for `Products` and `Customers`. This is the door this lesson uses.
2. **From a pivot table.** **Insert › PivotTable**, with the box **Add this data to the Data Model**
   ticked, puts the table in the model on the way. It loads one table each time, and it is how many
   people end up with a model without having meant to build one.
3. **From Power Query.** A query of lesson 13 loads to the model when you choose **Close & Load To…**,
   then **Only Create Connection** and **Add this data to the Data Model**. That is the door for data
   that does not live in the workbook at all: a CSV file each month, a database, a folder.

A table loaded through the first door is a **linked table**: the model's copy follows the table on
the sheet. Add a sale on the sheet, and after **Data › Refresh All** the model and every pivot table
built on it have it. It never goes the other way: Power Pivot's window does not let you edit a
value at all, and that is the right way round. The sheet is where records are entered, and the
model is where they are read.

## Checking that it arrived whole

Lesson 1 section 05 counted the rows after pasting, and a model deserves the same habit. Open
**Power Pivot › Manage**. Each table is a tab at the bottom of the window, and the window shows the
table's rows as a grid with a record count beneath it:

| tab | rows |
|---|---|
| `Sales` | 108 |
| `Products` | 6 |
| `Customers` | 11 |

A missing row is usually a table that does not reach the bottom of its data, because a row was
pasted below it rather than into it. Lesson 7 is about that: a table grows when you type
in the row directly beneath it, and not when a block arrives two rows further down.

## The type of every column

Power Pivot gives each column a **data type**, and it reads that type from the sheet. Click a column
heading in the window and look at **Home › Data Type**. `Date` should be a **Date**, `Bags`, `Price`
and `Revenue` **Whole Number**, and the codes **Text**.

The type matters more here than on a sheet. Section 06 joins `Sales[Date]` to a calendar, and a
join only matches a date to a date: a column of dates that arrived as text, the failure of lesson 1
section 08, would match nothing. If a type is wrong, fix the column on the sheet, as lesson 6 does,
rather than in the model, so the next refresh does not bring the mistake back.
