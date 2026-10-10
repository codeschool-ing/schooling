---
title: Why a model, and not one more lookup column
version: 1
---

**A lookup copies a fact into every row that needs it; a relationship says once where the fact
lives.** Up to now, a question about something `Sales` does not hold, such as the origin of the
beans, has been answered by fetching it. Lesson 4 put an `XLOOKUP` beside every sale to bring the
origin over from `Products`, and a pivot table in lesson 10 could then group by it.

That works, and it has a cost that grows with every question. Revenue by origin needs one lookup
column. Revenue by customer type needs a second, from `Customers`. Revenue by quarter needs a
third, worked out from the date. Each one is 108 more formulas, each copies a value that already
exists in another table, and each widens `Sales` with columns that are not facts about a sale. The
next person to open the workbook cannot tell the recorded columns from the fetched ones.

## What the data model is

The **data model** is a small database that lives inside the workbook. You put tables into it and
tell it which column of one table points at which column of another. From then on, a pivot table
built on the model can take its rows from `Products`, its columns from a calendar and its numbers
from `Sales`, all at once. Nothing is copied: the model follows the pointers each time it adds up a
cell.

**Power Pivot** is the part of Excel that manages the model. It has its own window, where the
tables appear as grids and the relationships as lines, and its own formula language, **DAX**, which
is lesson 16. The model's tables are not cells on a sheet. You do not type into them; you load them
from somewhere, and in this lesson that somewhere is the three Excel tables of lesson 7.

## What it changes, and what it costs

With a model, the questions above need no new column in `Sales` at all:

| question | lookup columns, lessons 4 and 10 | data model |
|---|---|---|
| revenue by origin | an `XLOOKUP` on every sale | `Origin` from `Products`, through one relationship |
| revenue by customer type | another `XLOOKUP` on every sale | `Type` from `Customers`, through a second |
| revenue by quarter | a formula on every sale, or grouping in the pivot | `Quarter` from a calendar, through a third |

Three things are given up in exchange, and it is better to know them now:

- **Power Pivot exists only in Excel for Windows.** Lesson 1 section 03 said so, and lesson 1
  section 04 says how to switch it on. On a Mac or in the browser this lesson can be read but not
  done.
- **A pivot table built on the model has no calculated fields.** Lesson 11's calculated field
  becomes a **measure** written in DAX, and lesson 10's grouping of dates gives way to the columns of
  a calendar you build in this lesson.
- **The model's formulas are DAX, not worksheet formulas.** They look alike and they do not work
  alike, which is why lesson 16 spends its first section on the difference.

**Nothing in this lesson or the next was run in Excel.** Power Pivot has no engine outside it, and
this course was written without one, as lesson 1 section 02 explains. Each number this lesson quotes
from a model was computed by applying the same relationships to the same rows you pasted, and where
a spreadsheet can check a number, a spreadsheet did.
