---
title: Structured references, formulas that say what they mean
version: 1
---

**A structured reference names a table and a column instead of giving an address.** `Sales[Bags]`
is the `Bags` column of the `Sales` table: every data row, however many there are, and never the
header. It is the same cells as `E2:E109` today. The difference shows the day the table has 109
sales, and in the meantime the formula reads like the question it asks.

## The parts of a table, by name

```schooling-figure
{"svg": "<svg data-fig=\"l07-table\"></svg>", "caption": ""}
```

| reference | what it covers |
|---|---|
| `Sales[Bags]` | the data rows of one column |
| `Sales[@Bags]`, or `[@Bags]` inside the table | the value of that column on the formula's own row |
| `Sales[#Headers]` | the header row |
| `Sales[#Totals]` | the total row, when the table has one (section 05) |
| `Sales[#All]` | everything: headers, data and total row |
| `Sales` | the data rows of every column |

Inside the table Excel drops the table's name and writes `[@Bags]`, because the table is obvious.
Outside it, on any sheet of the workbook, the name is needed and is enough: a table belongs to the
workbook, so `Sales[Bags]` needs no sheet name in front of it, unlike `Sales!E2:E109`.

You rarely type these. Start a formula, click a column of the table, and Excel writes the reference
itself: clicking E2 down to E109 while typing `=SUM(` produces `Sales[Bags]`.

## Lesson 5, rewritten

In an empty cell of any sheet:

```localised
=SUM(Sales[Bags])
=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")
=ROWS(Sales[Sale])
```

answer **591**, **38731** and **108**. The second is lesson 5's first `SUMIFS`, and it now reads
almost as the sentence it stands for: *add the revenue of the sales whose channel is Wholesale*.
The third counts the rows of the table, which is the number every check in lesson 1 began with,
and it will keep answering correctly when that number changes.

The `Report` grid of lesson 5, if you kept it, can take the same treatment:

```localised
=SUMIFS(Sales[Bags], Sales[Product], $A3, Sales[Date], ">="&B$2, Sales[Date], "<"&EDATE(B$2, 1))
```

gives the same **116** for the quarter once it fills the grid. There is no `$` on the table
references because they do not need one to stay put when **copied**. They do need care when
**dragged**: filling a structured reference to the right with the fill handle moves it to the next
column, so `Sales[Bags]` in B3 becomes `Sales[Price]` in C3. Copy and paste the cell instead, or
write the column as `Sales[[Bags]:[Bags]]`, which stays where it is however it is filled.

## When an address is still right

A structured reference points at a table, so it is the right reference for data. An address is
still right for a single cell that is not part of any table, such as the header dates of the
`Report` grid. Most of the formulas in the rest of this course mix the two, and that is fine:
the table names the data, and the addresses name the cells around it.
