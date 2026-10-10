---
title: Lookups between tables
version: 1
---

**A lookup written with structured references names the column it returns, so it survives the
changes that break one written with a column number.** Lesson 4 looked prices and names up in
`Products` by address. With three tables, the same lookup can say *the unit cost of this row's
product* in so many words, and keep saying it after somebody rearranges `Products`.

## A cost column, by lookup

How much did the bags sold cost Café Serra to roast? `Sales` knows the bags and `Products` knows the
cost of one bag, so each sale needs a lookup. Type `Cost` in **I1**, the first empty header beside
the table. The table grows to take the column in, as section 04 showed for rows. In **I2** type:

```localised
=[@Bags]*XLOOKUP([@Product], Products[Code], Products[Unit cost])
```

Read it aloud: *this row's bags, times the unit cost of the product whose code is this row's
product*. It is a calculated column, so it fills the 108 rows at once, and I2 answers **854**: 14
bags of `CER1K` at R$ 61. Then, outside the table:

```localised
=SUM(Sales[Cost])
=SUM(Sales[Revenue])-SUM(Sales[Cost])
```

**30390** of cost and **21104** of gross margin, about **41%** of the R$ 51,494 of revenue. Take
those as an estimate, not an account. `Unit cost` holds what a bag costs today, and the 2025 sales
were roasted at whatever it cost then, which these tables do not record.

## Why not VLOOKUP

The same cost can be fetched with lesson 4's `VLOOKUP`, pointed at the whole table:

```localised
=VLOOKUP([@Product], Products, 7, FALSE)
```

On row 2 it answers **61**, like the `XLOOKUP`. Pointing it at `Products` rather than at
`Products!A2:G7` already helps: a product added to the table is found without editing the formula.
What it still carries is the **7**, the position of `Unit cost` counted from the left.

Try what that costs. On the `Products` sheet, right-click the `Grams` header, choose **Insert ›
Table Columns to the Left**, and call the new column `Supplier`. `Unit cost` is now the eighth
column. The `VLOOKUP` on row 2 answers **118**, which is the list price of `CER1K`, the column that
moved into seventh place. No error, just a different and wrong number. The `XLOOKUP` in the `Cost`
column still answers 854 on row 2 and **30390** in total, because `Products[Unit cost]` names the
column, wherever it now sits.

Press **Ctrl+Z** to take the `Supplier` column out again.

## What the tables leave for the rest of the course

The `Cost` column was for this section. Later lessons work from the eight columns lesson 2 left,
and lessons 15 and 16 relate the tables in a data model instead of copying values across with
lookups. Right-click the `Cost` header and choose **Delete › Table Columns**.

What stays is three tables: `Sales` with its eight columns and 108 rows, `Products` and
`Customers`. Check the size with `=ROWS(Sales[Sale])`, which should answer 108, and save. From here
on, the formulas in this course name the tables rather than their addresses, and the pivot tables of
lesson 10, the drop-downs of lesson 8 and the queries of lesson 13 all start from them.
