---
title: Checking a measure against SUMIFS
version: 1
---

**A measure is checked by computing the same cell another way, and the two must agree to the
real.** A measure can be well formed, accepted by **Check DAX Formula**, formatted, and wrong: a
missing relationship, a filter removed that should have stayed, a date that matches no calendar row.
None of those produces an error. Each produces a number, and the only way to catch it is a second
number you trust for a different reason.

For this model, that second number is the `SUMIFS` of lesson 5. It reads the sheet, not the model,
and has nothing in common with a measure except the rows. Agreement means the relationships, the
filters and the measure all did what you meant.

## Five cells, two ways

Pick cells from the pivot tables of this lesson, write down what each one is about, and compute it on
the sheet. Type these in any empty cells; they name the `Sales` sheet, so they work from anywhere in
the workbook.

```localised
=SUMIFS(Sales!H2:H109,Sales!G2:G109,"Online",Sales!B2:B109,">="&DATE(2026,1,1))
=SUMIFS(Sales!H2:H109,Sales!B2:B109,">="&DATE(2025,1,1),Sales!B2:B109,"<"&DATE(2025,7,1))
=SUMIFS(Sales!H2:H109,Sales!B2:B109,">="&DATE(2026,1,1),Sales!B2:B109,"<"&DATE(2026,4,1))
=COUNTIFS(Sales!B2:B109,">="&DATE(2026,1,1))
=SUM(Sales!H2:H109)
```

| formula | answers | the measure, in the cell | measure's value |
|---|---|---|---|
| the first | **4,295** | `Total Revenue`, `Online` row, `2026` column | 4,295 |
| the second | **17,789** | `Revenue LY`, 2026, slicer on months 1 to 6 | 17,789 |
| the third | **12,139** | `Revenue YTD`, March 2026 | 12,139 |
| the fourth | **36** | `Sales Count`, `2026` column | 36 |
| the fifth | **51,494** | `Total Revenue`, grand total | 51,494 |

The formulas were run in a spreadsheet holding your data, and the measures were computed from the
same rows by applying their definitions, as section 02 explained: **neither column of numbers came
from Excel**, and the two agree on all five. On your own workbook, the measures come from Power Pivot
and the formulas from Excel, and they should agree with each other and with this table.

Each pairing tests something different. The first tests a measure, a relationship and a filter on a
fact column together. The second is the one that tests `SAMEPERIODLASTYEAR`: the formula names the
first half of 2025 outright, and the measure has to arrive there by moving the dates of 2026. The
third tests `TOTALYTD` the same way. The fourth tests `COUNTROWS` and the calendar relationship. The
fifth tests that nothing was lost anywhere: if `Total Revenue` with no filter is not the sum of the
column, a row is missing from the model, and lesson 15 section 04 says where to look.

With `Sales` as the Excel table of lesson 7, `Sales[Revenue]`, `Sales[Channel]` and `Sales[Date]`
can stand in for the three ranges, and the answers are the same; the ranges are printed here so the
formula still works in a workbook where the table was never made.

## When they disagree

A disagreement is information, and it points at a short list of causes, most of them met in lesson
15:

- **every row of the pivot table shows the same number**: a relationship is missing, lesson 15
  section 05;
- **the measure is lower than the formula, on dates**: some `Sales[Date]` values match no calendar
  row, because they carry a time or fall outside 2025 and 2026, lesson 15 section 06;
- **the grand total disagrees and the rows do not**: a slicer or a filter on the pivot table is
  still set, and the formula has no idea about it;
- **an average disagrees**: one side divides sums and the other averages prices, section 03;
- **a share or an "online" measure disagrees**: the filter `CALCULATE` replaced or removed is not
  the one you meant, section 04.

**Check one cell of every new measure before anybody reads it.** It takes a minute, and a measure in
a dashboard is read by people who will never open the model to see why it says what it says.
