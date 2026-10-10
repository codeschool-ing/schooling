---
title: Grouping dates into quarters, and numbers into bands
version: 1
---

**A pivot groups by the values a field holds, and a date field holds 103 different days.** Put
`Date` in **Rows** as it is and the pivot has a row for nearly every sale, which is the data again
rather than a summary of it. Grouping tells the pivot to collect the days into years, quarters or
months first, and to group by those.

## Dates into years and quarters

Start a pivot on a new sheet called `By quarter`. Drag `Date` into **Rows**. Recent versions of
Excel group a date field on their own as it lands, and add fields such as `Years` and `Quarters`
to the list; older ones show one row per day. Either way, make the grouping the one this section
uses: right-click any date or period in the pivot, choose **Group**, select **Years** and
**Quarters** and nothing else in the **By** list, and **OK**.

Add `Revenue` to **Values**. Collapse the quarters for a moment, with the minus signs beside the
years, and read the years alone:

| Row Labels | Sum of Revenue |
|---|---|
| 2025 | 35,551 |
| 2026 | 15,943 |
| **Grand Total** | **51,494** |

**This is the moment a pivot misleads more readers than any other.** It looks as though revenue
fell by more than half. It did not: the data runs to June 2026, so the 2026 row is six months set
against twelve. The fair comparison is the same half-year:

```localised
=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2025,1,1), Sales[Date], "<="&DATE(2025,6,30))
```

answers **17,789**, against **15,943** for the first half of 2026. Revenue fell, by about a tenth.
Expand the years again and drag `Channel` into **Columns** to see where:

```schooling-figure
{"svg": "<svg data-fig=\"l10-quarters\"></svg>", "caption": ""}
```

| Years | Quarters | Online | Shop | Wholesale | Grand Total |
|---|---|---|---|---|---|
| 2025 | Qtr1 | 2,291 | 324 | 6,688 | 9,303 |
| | Qtr2 | 1,562 | 220 | 6,704 | 8,486 |
| | Qtr3 | 1,598 | 256 | 6,233 | 8,087 |
| | Qtr4 | 1,397 | 300 | 7,978 | 9,675 |
| 2026 | Qtr1 | 1,768 | 409 | 9,962 | 12,139 |
| | Qtr2 | 2,527 | 111 | 1,166 | 3,804 |

The first quarter of 2026 is the best quarter in the data. The second is the worst by far, and the
whole fall is wholesale: **1,166** against 9,962 three months earlier. Online grew in the same
quarter. Check that one cell before believing it:

```localised
=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale", Sales[Date], ">="&DATE(2026,4,1), Sales[Date], "<="&DATE(2026,6,30))
```

**1,166**. A year total said "collapse", a half-year said "a tenth down", and the quarters said
"wholesale stopped buying in April". Each is true, and only the last is something Café Serra can
act on. Lesson 9's grid showed the same gap as two empty months.

The pivot labels quarters `Qtr1` to `Qtr4`. Your Excel may also add a pivot row for each year's
subtotal, depending on the layout; the quarters and the grand total are the same either way.

## Numbers into bands

A number field can be grouped into equal bands. Start one more pivot, put `Bags` in **Rows** and
`Sale` in **Values**. `Sale` is text, so it arrives as **Count of Sale**: the number of sales of
each size. Right-click a number of bags, choose **Group**, and set **Starting at** `1`, **Ending
at** `20` and **By** `5`:

| Row Labels | Count of Sale |
|---|---|
| 1-5 | 76 |
| 6-10 | 11 |
| 11-15 | 17 |
| 16-20 | 4 |
| **Grand Total** | **108** |

Seventy per cent of the sales are of five bags or fewer. Each band is a `COUNTIFS` with two bounds:

```localised
=COUNTIFS(Sales[Bags], ">=1", Sales[Bags], "<=5")
```

**76**. The `16-20` band is the four sales lesson 8 circled.

To undo a grouping, right-click a group and choose **Ungroup**. The field returns to its own
values.
