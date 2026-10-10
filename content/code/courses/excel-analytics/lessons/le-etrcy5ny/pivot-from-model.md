---
title: A pivot table that reads the whole model
version: 1
---

**A pivot table built on the model lists every table of the model in its field list, and takes each
field from wherever it lives.** That is the whole payoff of the last four sections: the question
"revenue by origin and year" needs `Origin` from `Products`, `Year` from `Calendar` and `Revenue`
from `Sales`, and the pivot table takes all three without a lookup column anywhere.

Make one from a new sheet with **Insert › PivotTable › From Data Model**, or from the Power Pivot
window with **Home › PivotTable**. The field list shows four tables, each with a small arrow to
open it. Then:

1. from `Products`, drag `Origin` to **Rows**;
2. from `Calendar`, drag `Year` to **Columns**;
3. from `Sales`, drag `Revenue` to **Values**, where it becomes **Sum of Revenue**.

The model answers with this table. It was computed, like every number in this lesson, by following
the three relationships over the rows you pasted, not by Excel:

| `Origin` | 2025 | 2026 | Grand Total |
|---|---|---|---|
| `Cerrado` | 14,110 | 8,083 | 22,193 |
| `Mogiana` | 2,969 | 385 | 3,354 |
| `Sul de Minas` | 18,472 | 7,475 | 25,947 |
| **Grand Total** | **35,551** | **15,943** | **51,494** |

Two checks take a second each, and the habit is worth more than the seconds. The grand total, R$
51,494, has to equal the sum of the `Revenue` column on the sheet:

```localised
=SUM(Sales!H2:H109)
```

answers **51,494**, in a spreadsheet. The year totals can be checked the same way with the `SUMIFS`
of lesson 5, and lesson 16 section 06 does exactly that. Compare this table with the one in
section 05 where every row said 51,494: the only difference is the line between `Sales` and
`Products`.

## Swapping a field takes a drag

Replace `Origin` with `Type` from `Customers` and the same pivot table splits the revenue by kind of
customer: `Café` 13,532, `Individual` 12,763, `Office` 7,031 and `Retail` 18,168. With lookup
columns that was a second `XLOOKUP` on every sale; here it is a second relationship drawn once, in
section 05.

Replace it with `State` and one row is labelled `(blank)`, with R$ 12,763. That is `C00`, the walk-in
and web customer, whose state is empty in `Customers`: all 70 of its sales land on the blank row. It
is the empty cell of lesson 4 again, and here it is honest rather than a trap. The money is counted,
and the label says the state is unknown.

Put `Quarter` from `Calendar` in the rows, with `Year` still in the columns, and the 2026 column is
empty for `Q3` and `Q4`. The calendar has those days, and no sale fell in them, so their cells hold
nothing rather than a zero. Lesson 16 section 05 meets those empty quarters again, in a comparison
where they matter.

## The rule that keeps it right

Section 03's rule of thumb is the one to hold on to here. **Put dimension columns in Rows, Columns,
Filters and slicers; put fact columns in Values.** Grouping by `Products[Code]` and by
`Sales[Product]` gives the same six rows, because each sale carries one product code; grouping by
`Origin` only works from `Products`, because `Sales` does not have it. And section 05
showed what a value taken from a dimension does when the rows come from the facts: six on every
row.

Two tools of lessons 10 and 11 give way to the model here. Grouping dates by hand is the wrong tool:
the calendar's `Year`, `Quarter` and `Month` columns already are the groups, and they are the same in
every pivot table built on the model. And **Calculated Field** is not offered at all: a calculation
on a model is a **measure**, written in DAX, and dragging `Revenue` into **Values** has just made one
without saying so. Lesson 16 starts there.
