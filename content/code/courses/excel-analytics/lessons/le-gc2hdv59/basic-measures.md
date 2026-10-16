---
title: The first measures, sums, counts and a ratio
version: 1
---

**Most of what a report needs is a handful of measures built from five functions.** `SUM` adds a
column, `COUNTROWS` counts rows, `DISTINCTCOUNT` counts different values, `DIVIDE` divides without
failing on zero, and `SUMX` works out an expression on every row before adding. Each is written
once, named, and then used by every pivot table in the workbook.

Create the eight below with **Power Pivot › Measures › New Measure**, one at a time, all in the
table `Sales`, and in this order: the later ones use the earlier ones by name.

```schooling-example
{"language": "dax", "parts": [
 {"code": "Total Revenue := SUM(Sales[Revenue])", "note": "Adds the Revenue column of lesson 2, over whatever rows the cell is about. Every other money measure in this lesson starts from this one."},
 {"code": "Bags Sold := SUM(Sales[Bags])", "note": "The same for bags. These first two are what dragging a column into Values would have made; the rest are not."},
 {"code": "Sales Count := COUNTROWS(Sales)", "note": "Counts rows of the table, not values of a column, so it does not care which column is empty. One row is one sale."},
 {"code": "Customers Buying := DISTINCTCOUNT(Sales[Customer])", "note": "Counts the different customer codes among the cell's sales. C00, the walk-in and web customer, counts once however many times it bought."},
 {"code": "Average Price := DIVIDE([Total Revenue], [Bags Sold])", "note": "A measure in square brackets with no table name is another measure. DIVIDE answers blank instead of an error when there are no bags to divide by."},
 {"code": "Total Cost := SUMX(Sales, Sales[Bags] * RELATED(Products[Unit cost]))", "note": "SUMX goes through the cell's sales one by one, multiplies the bags by the product's cost, and adds the results. RELATED fetches the cost along the relationship to Products, from the many side to the one."},
 {"code": "Gross Margin := [Total Revenue] - [Total Cost]", "note": "Arithmetic on two measures, done per cell. No row of Sales ever holds a margin."},
 {"code": "Margin % := DIVIDE([Gross Margin], [Total Revenue])", "note": "The ratio of the sums, per cell. Give it the percentage format in the dialog."}
]}
```

Put `Sales[Channel]` in a pivot table's Rows and the measures in Values, and the model answers
this. As with everything in this lesson, it was computed by applying the definitions above to your
rows, not by Excel:

| `Channel` | Total Revenue | Bags Sold | Sales Count | Customers Buying | Average Price | Margin % |
|---|---|---|---|---|---|---|
| `Online` | 11,143 | 149 | 47 | 1 | 74.79 | 45.5% |
| `Shop` | 1,620 | 39 | 23 | 1 | 41.54 | 44.6% |
| `Wholesale` | 38,731 | 403 | 38 | 10 | 96.11 | 39.5% |
| **Grand Total** | **51,494** | **591** | **108** | **11** | **87.13** | **41.0%** |

## Three things the table says about measures

**`Customers Buying` does not add up, and it is right.** The rows say 1, 1 and 10, which would
make 12; the total says 11. `C00` bought online and in the shop, so it is one customer in each of
those rows and still one customer in the total. A distinct count is computed from the total's own
context, as section 02 showed, and adding the rows would count `C00` twice. Any measure that counts
different things behaves like this, and a total that equals the sum of its rows would be the bug.

**`Average Price` is not the average of the `Price` column.** Dragging `Price` into Values and
choosing **Average** gives the mean of 108 prices, 75.07, where a one-bag sale weighs as much as a
twenty-bag one. `Average Price` divides revenue by bags, R$ 87.13 a bag, which is what Café Serra
actually received for each bag it sold. The 1 kg bags make the difference. They cost more, and they
sell in larger orders, 7.71 bags a sale against 3.61 for the 250 g bags, so they weigh more in the
ratio of the sums than in a plain average of prices.

**`Total Cost` uses today's cost for every sale.** `Products[Unit cost]` holds one cost per
product, the current one, so a 2025 sale is costed at 2026 prices. The model does exactly what the
data allows, and a margin by year from it is only as good as that assumption. A cost with a date
on it would need its own table, like the price history of lesson 4.

## SUMX and the row it is standing on

`SUM(Sales[Bags])` adds a column that already exists. `Total Cost` needs bags times cost, and there
is no such column: the cost lives in `Products`. `SUMX` builds the number one sale at a time. For
each row of `Sales` that the cell is about, it evaluates `Sales[Bags] * RELATED(Products[Unit
cost])`, and `RELATED` follows that one sale's product code to its row in `Products` and returns its
cost. Then it adds the results.

That is the same arithmetic a calculated column would do, without storing a column: Café Serra's
total cost comes to R$ 30,390 and its gross margin to R$ 21,104. Any function ending in **X**,
such as `SUMX`, `AVERAGEX` or `MAXX`, works the same way: a table to walk, and an expression to
work out on each row of it.
