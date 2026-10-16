---
title: The first pivot table, checked against a formula
version: 1
---

**A pivot table is a summary that Excel builds from a table of records: you say which field to
group by and which to add up, and it writes every total.** Lesson 5 answered "revenue by channel"
with one `SUMIFS` per channel, typed by hand. A pivot table answers the same question with two
drags, and answers the next question with two more.

It needs the shape lesson 1 insisted on: one row per record, one header per column, no blank rows
or totals inside the range. The `Sales` table has that shape, which is why everything below works
first time.

## Building it

1. Click any cell of the `Sales` table.
2. Choose **Insert › PivotTable**. Excel proposes the table itself, `Sales`, as the source: keep it.
   Choose **New Worksheet** and **OK**.
3. A new sheet opens with an empty pivot on the left and the **PivotTable Fields** pane on the
   right, which lists the eight columns of `Sales` as fields. Rename the sheet `By channel`.
4. Drag `Channel` from the list into the **Rows** box at the bottom of the pane.
5. Drag `Revenue` into the **Values** box. It arrives as **Sum of Revenue**.

The pivot now reads:

| Row Labels | Sum of Revenue |
|---|---|
| Online | 11,143 |
| Shop | 1,620 |
| Wholesale | 38,731 |
| **Grand Total** | **51,494** |

If your pivot uses another layout, the first heading reads `Channel` instead of `Row Labels`; the
numbers are the same.

## Checking it

**A number you have not checked is a number you are trusting**, and the course promised in lesson
1 that every pivot would be checked against a formula. In an empty cell of any sheet:

```localised
=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")
=SUM(Sales[Revenue])
```

**38,731** and **51,494**, the same as the pivot. Two different mechanisms, one written by you and
one by Excel, reading the same 108 rows and agreeing: that is what makes either of them worth
believing.

## What Excel did

For each distinct value in the `Rows` field, the pivot collected the rows holding that value and
added up their `Revenue`. It is the `SUMIFS` above, written once per channel, plus a grand total,
with the channels sorted from A to Z. Nothing was typed, so nothing can be mistyped: a pivot never
forgets a channel, because it lists the channels it finds rather than the ones somebody remembered.

That also means it lists the channels **as they are spelt**. Had sale `S1003` been typed as
`Onlnie`, one of lesson 8's typos, the pivot would show a fourth channel called `Onlnie` with 115
beside it, and Online would drop to 11,028. A pivot is a quick way to see every distinct value of a
column, misspellings included.
