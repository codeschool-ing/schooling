---
title: Rows, Columns, Values and Filters
version: 1
---

**The bottom of the PivotTable Fields pane has four boxes, and the whole of pivot design is
deciding which field goes in which.** Rows and Columns choose how the records are grouped, Values
chooses what is added up for each group, and Filters chooses which records are let in at all.
Moving a field from one box to another is the "pivot" in the name.

```schooling-figure
{"svg": "<svg data-fig=\"l10-areas\"></svg>", "caption": ""}
```

## A grid from two fields

Start a second pivot from `Sales` on a new sheet, as in section 02, and call the sheet `Grid`. Put
`Product` in **Rows**, `Channel` in **Columns** and `Revenue` in **Values**:

| Sum of Revenue | Online | Shop | Wholesale | Grand Total |
|---|---|---|---|---|
| CER1K | 4,188 | | 17,168 | 21,356 |
| CER250 | 451 | 386 | | 837 |
| DEC250 | 1,776 | 516 | 1,330 | 3,622 |
| MOG250 | 587 | 370 | 2,397 | 3,354 |
| SUL1K | 3,246 | | 17,836 | 21,082 |
| SUL250 | 895 | 348 | | 1,243 |
| **Grand Total** | **11,143** | **1,620** | **38,731** | **51,494** |

Every cell is a `SUMIFS` with two conditions. Check one:

```localised
=SUMIFS(Sales[Revenue], Sales[Product], "CER1K", Sales[Channel], "Wholesale")
```

**17,168**, as in the grid. An empty cell means that combination never happened: the shop has
never sold a 1 kg bag, and wholesale customers have never bought the 250 g bags of Sul de Minas or
Cerrado. A blank is information here, and it is easier to see in the grid than in 108 rows.

Now drag `Channel` from **Columns** to **Rows**, below `Product`. The same numbers rearrange into
a list, each product with its channels indented underneath. Drag it back. Nothing was recomputed
in a way you could get wrong; only the layout changed.

## Filters: which records are let in

Drag `Customer` into **Filters**. A drop-down appears above the pivot, reading **(All)**. Open it,
choose `C00`, and **OK**. The grid now counts only the sales to walk-in and web customers:

| Sum of Revenue | Online | Shop | Grand Total |
|---|---|---|---|
| **Grand Total** | **11,143** | **1,620** | **12,763** |

shown here by its totals row. Two things changed besides the numbers. The `Wholesale` column has
gone, because `C00` never bought wholesale and a pivot shows only the items that have data. And the
Online and Shop totals did not move at all: **every online and every shop sale in the data is a
sale to `C00`**. That is a fact about Café Serra's customers that no one asked about, and the
filter showed it in a second. The formula agrees:

```localised
=SUMIFS(Sales[Revenue], Sales[Customer], "C00")
```

answers **12,763**. Set the filter back to **(All)** before going on.

A field in **Filters** filters the whole pivot. A field in **Rows** or **Columns** can be filtered
too, from the arrow beside its heading, and then it both groups and filters. The **Filters** box is
for a field you want to choose by without showing it as rows or columns.

## Values: more than one

**Values** takes more than one field. Drag `Bags` in beside `Revenue`, and each cell of the grid
splits into two: the bags and the revenue for that product and channel. A box called **Σ Values**
appears in **Columns**, and moving it to **Rows** stacks the two measures instead of placing them
side by side. Remove `Bags` again by dragging it out of the box.
