---
title: A sheet for new sales, and a rule on each column
version: 1
---

**A validation rule belongs to a cell, checks a value when somebody types it and presses Enter,
and refuses or questions the value when the rule says no.** This section builds a sheet called
`New sales` where the next sale would be typed, and puts a rule on each of its columns.

## The sheet

1. Add a sheet with the **+** beside the tabs and name it `New sales`.
2. In A1 to G1 type the same headers as `Sales`, without `Revenue`: `Sale`, `Date`, `Customer`,
   `Product`, `Bags`, `Price`, `Channel`.
3. Select A1:G2 and choose **Insert › Table**, with **My table has headers** ticked. You now have
   a table with one empty row.
4. On the **Table Design** tab, type `NewSales` in **Table Name** (a table name takes no spaces).

The table is there for one reason: **a rule put on a whole column of a table is copied to every
row the table grows by**, as lesson 7 showed for formulas. Type a sale in the row under the table
and the row joins it, rules included.

## Where the rules are set

Select the cells a rule is for, then **Data › Data Validation**. The **Settings** tab holds the
rule itself, and its **Allow** list says what kind of value the cells take:

| Allow | the cell takes | in `New sales` |
|---|---|---|
| **Whole number** | an integer, compared with a bound | `Bags`: between 1 and 50 |
| **Decimal** | any number, compared with a bound | |
| **List** | one value from a list | `Customer`, `Product`, `Channel`, in the next section |
| **Date** | a date, compared with a bound | `Date`: from 1 January 2025 to today |
| **Time** | a time of day | |
| **Text length** | text of a certain number of characters | |
| **Custom** | anything for which a formula answers `TRUE` | `Sale`, below, and `Price`, in section 05 |

Under **Allow**, the **Data** list chooses the comparison: *between*, *greater than*,
*less than or equal to* and the others. The boxes under it take a number, a cell, or a formula.

## Bags and Date

Select the `Bags` cell of the table (E2), choose **Whole number**, **between**, and type `1` and
`50`. A value of `2.5`, `0`, `140` or `fourteen` is now refused.

For the `Date` cell (B2), choose **Date**, **between**, and type a formula in each box:

```localised
=DATE(2025,1,1)
=TODAY()
```

The first is the first day of the year Café Serra's records start in. The second is recomputed every day, so the upper
bound moves on its own, and a date in the future is refused tomorrow as it is today. A formula in
the box is safer than a typed date, because how a typed date is read depends on the region
Windows is set to, and lesson 6 shows what that does.

## Sale: a custom rule

A sale code has to be five characters, and it must not already be used, neither in `Sales` nor
further up `New sales`. No item of the **Allow** list says that, so the rule is a formula. Select
A2, choose **Custom**, and type:

```localised
=AND(LEN(A2)=5, COUNTIF(Sales!A:A, A2)=0, COUNTIF(A:A, A2)=1)
```

**A custom rule is written for the first cell selected, and it moves like a formula filled down.**
`A2` is a relative reference, so on row 3 Excel reads it as `A3`, on row 4 as `A4`. The three
conditions say: five characters long, not anywhere in column A of `Sales`, and only once in column
A of this sheet, where the cell being typed counts as the one.

On the data you pasted, `S1050` is refused because sale `S1050` exists, `S110` is refused for its
length, and `S1109` is accepted. Type `S1109` again in the row below and that one is refused,
because column A now holds it twice. The formula has to name ordinary cells: the rule box does not
take a structured reference such as `Sales[Sale]`.

## A blank cell always passes

Every rule has an **Ignore blank** box, ticked by default, and even unticked it does not make a
cell compulsory: a cell nobody types in is never checked at all. Validation decides what may go
into a cell. Whether something was typed is a different question, and lesson 9 answers it with
formatting that shows an empty cell in a row that should be complete.
