---
title: Building a chart from a summary or a pivot table
version: 1
---

**Chart the summary, never the records.** Select the table `Sales` and insert a column chart, and
Excel draws a cluster of columns for each of the 108 sales: a picket fence that answers nothing.
A chart draws a handful of numbers that somebody has already added up, and there are two places to
add them up: a small range of formulas you lay out yourself, or a pivot table.

## A chart from a range of formulas

Add a sheet called `Monthly`. Type the headers `Month`, `Revenue` and `Bags` in A1, B1 and C1, and
the date `2025-01-01` in A2. Then, in A3:

```localised
=EDATE(A2,1)
```

`EDATE` moves a date by whole months, so A3 shows the first of February. Fill it down to A19, the
first of June 2026. In B2 and C2:

```localised
=SUMIFS(Sales[Revenue], Sales[Date], ">="&A2, Sales[Date], "<"&EDATE(A2,1))
=SUMIFS(Sales[Bags], Sales[Date], ">="&A2, Sales[Date], "<"&EDATE(A2,1))
```

Each adds the sales from the first of its month up to, but not including, the first of the next,
the date criteria of lesson 5. Fill both down to row 19, and check the columns against the whole
table:

```localised
=SUM(B2:B19)
=SUM(C2:C19)
```

They answer 51,494 and 591, the totals of lessons 1 and 2. Give column A the custom number
format `mmm yyyy` so it reads `Jan 2025`.

Now select A1:B19 and choose **Insert › Insert Line or Area Chart › Line**. Excel sees dates in the
first column and makes it a date axis, one point per month in calendar order. The line peaks at R$
5,004 in January 2026 and falls to R$ 971 in April 2026. That fall is the most important thing the
chart shows, and a formula explains it:

```localised
=COUNTIFS(Sales[Channel], "Wholesale", Sales[Date], ">="&DATE(2026,4,1), Sales[Date], "<"&DATE(2026,6,1))
```

It answers 0. There was no wholesale sale in April or May 2026, and wholesale is three quarters of
the revenue. The chart found the question; the formula answered it.

**A chart drawn on a plain range draws exactly that range.** When July's sales arrive, row 20 has to
be added by hand and the chart's range widened to take it. Turn the summary into a table with
**Ctrl+T**, as in lesson 7, and a row added to the table joins the chart by itself.

## A PivotChart

Lesson 11's `Report` sheet already has `ByProduct`, the revenue of each product. Sort it first:
right-click any revenue cell and choose **Sort › Sort Largest to Smallest**. Then click in the pivot
table and choose **PivotTable Analyze › PivotChart**, and pick **Bar › Clustered Bar**.

The bars come out upside down. A bar chart draws its first category at the bottom, next to the
axis, so the largest product, `CER1K` with 21,356, sits at the foot of the chart. Double-click the
product axis and, in **Format Axis**, tick **Categories in reverse order**; the largest bar moves to
the top, where a reader starts.

A PivotChart is drawn from the pivot table and follows it in everything:

- **Slicers move it.** Click `Wholesale` in lesson 11's `Channel` slicer and the chart redraws with
  four bars, the products wholesale customers buy.
- **The layout moves it.** Drag another field into **Rows** and the chart gains a level of
  categories; remove one and it loses it.
- **It carries buttons.** The grey field buttons on the chart filter it like the pivot table's own
  menus. **PivotChart Analyze › Field Buttons** hides them when the chart is for reading rather than
  for steering.

One limit is worth knowing before choosing one. A PivotChart cannot be a scatter, a bubble or a
stock chart: a scatter needs each record as a point, and a pivot table has already added the
records up.

## Which to use

A chart on a range of formulas stays exactly as you built it: you decide every row, and nothing
reshapes it but you. A PivotChart reshapes itself with every slicer and every change of layout,
which is a fault in a report printed once a month and the whole point of a dashboard that somebody
explores with slicers, the subject of lesson 17.
