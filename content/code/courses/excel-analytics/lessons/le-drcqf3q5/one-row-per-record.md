---
title: One row per record, one column per field
version: 1
---

**A sheet that is going to be analysed has one shape, and everything else in this course assumes
it.** Each row is one record of the same kind. Each column is one field, with its name in row 1.
Each cell holds one value. Nothing else lives in the range: no titles above it, no totals inside
it, no blank rows to make it easier on the eye.

The `Sales` sheet you pasted has that shape, and it is worth saying exactly what makes it so:

- **one kind of record**: every row from 2 to 109 is a sale, and nothing else is;
- **one header row**: row 1 names the seven fields, and every name is different;
- **one value per cell**: `14` in `Bags`, not `14 bags` and not `14 + 3`;
- **no gaps**: no empty row or column breaks the block, so Excel can find its edges.

## Say what a row is before anything else

The most useful sentence about a table is the one that finishes *each row is one…*. For `Sales`
it is **one sale**, and a sale here is one product in one quantity on one day. That sentence is
called the table's **grain**, and getting it wrong is how a total doubles. If a row were one
*order*, an order with two products would need two `Product` columns, and every question about
products would have to look in both. If it were one *bag*, a wholesale sale of 20 bags would be 20
identical rows.

The other two sheets have a grain too: one product per row in `Products`, one customer per row in
`Customers`. Three tables, three kinds of record, and each fact lives in exactly one of them.

## Keys: how one table points at another

`Sales` does not say what `CER1K` is called or what it costs to make. It says `CER1K`, and the
`Products` sheet has one row whose `Code` is `CER1K`. A column whose values identify one row each
is a **key**: `Sale` in `Sales`, `Code` in `Products`, `Customer` in `Customers`. A column holding
another table's key, like `Product` and `Customer` in `Sales`, points at a row there.

That arrangement is why the product's name is written once and not 28 times. If Café Serra renames
its Cerrado 1 kg bag, one cell changes, and every sale of it follows. Lesson 4 follows those
pointers with lookup formulas, and lesson 15 lets Excel follow them by itself.

## Why everything depends on this shape

Every tool in the rest of the course reads a range in this shape and only in this shape:

- `SUMIFS` and its family, lesson 5, compare a column against a condition, row by row;
- an **Excel table**, lesson 7, is this shape given a name;
- a **pivot table**, lesson 10, turns each column into a field you can drag;
- **Power Query**, lessons 13 and 14, spends most of its effort turning other shapes into this one;
- the **data model**, lesson 15, is several tables of this shape joined by their keys.

A sheet laid out for a person to read, which is the subject of the next section, defeats all five.
