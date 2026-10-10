---
title: Measures and calculated columns
version: 1
---

DAX can add two kinds of thing to a model, and choosing the wrong one is the commonest beginner's
mistake in Power BI.

A **calculated column** is computed once per row, when the data is loaded, and stored like any other
column. It is right for an attribute of a row that you want to group or filter by:

```
Order Size = IF ( orders[gross] >= 400, "large", "small" )
```

A **measure** is computed when a visual asks for it, over whatever rows the visual is showing at
that moment. It is right for anything that adds up:

```
Net Revenue = SUM ( orders[net_revenue] )

Orders = COUNTROWS ( orders )

Net Revenue per Order = DIVIDE ( [Net Revenue], [Orders] )
```

(Not run: these are written from Microsoft's documentation, as every formula in this lesson is.)

The difference shows the moment you divide. A calculated column that divides something on each row,
averaged afterwards by a visual, gives an average of ratios; a measure that divides a sum by a count
gives the ratio of sums. Those are lesson 2's two averages, and lesson 2 said that
"the shop's" figure is the ratio of sums — so a ratio is a measure, always.

`DIVIDE` instead of `/` is a habit worth having from the first day: it returns blank rather than an
error when the denominator is zero, which in a report is a month with no orders in some region.

## Implicit measures, and why to avoid them

Drag `net_revenue` onto a chart and Power BI sums it without being asked: an **implicit measure**. It
works, and it is the semantic-layer problem of lesson 3 in a new place. Every report author who drags
the column chooses the aggregation again — sum here, average there — and the name on the chart is
*Sum of net_revenue* rather than a definition anybody owns. **Write the measure once, name it, hide
the raw column**, and the people building reports on the model choose *Net Revenue* from a list, as
they chose it from Metabase's menu in lesson 3.
