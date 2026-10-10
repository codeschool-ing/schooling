---
title: Grouping dates into quarters, and numbers into bands
version: 1
---

**A pivot groups by the values a field holds, and the `Date` field holds 108 different days.** Put
`Date` in **Rows** as it is and the pivot has a row for every sale, which is the data again
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
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" data-fig=\"l10-quarters\" aria-label=\"Horizontal bars for the six quarters from the first of 2025 to the second of 2026, each split into Wholesale, Online and Shop revenue. The first quarter of 2026 is the longest bar, 12,139. The second quarter of 2026 is the shortest by far, 3,804, and almost all of the drop is in its wholesale segment, 1,166.\"><rect x=\"110.0\" y=\"16.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"128.0\" y=\"22.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Wholesale</text><rect x=\"230.0\" y=\"16.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"248.0\" y=\"22.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Online</text><rect x=\"350.0\" y=\"16.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"368.0\" y=\"22.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop</text><text x=\"100.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Q1 2025</text><rect x=\"110.0\" y=\"50.0\" width=\"267.5\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"377.5\" y=\"50.0\" width=\"91.6\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"469.2\" y=\"50.0\" width=\"13.0\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"490.1\" y=\"62.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">9,303</text><text x=\"100.0\" y=\"98.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Q2 2025</text><rect x=\"110.0\" y=\"86.0\" width=\"268.2\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"378.2\" y=\"86.0\" width=\"62.5\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"440.6\" y=\"86.0\" width=\"8.8\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"457.4\" y=\"98.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">8,486</text><text x=\"100.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Q3 2025</text><rect x=\"110.0\" y=\"122.0\" width=\"249.3\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"359.3\" y=\"122.0\" width=\"63.9\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"423.2\" y=\"122.0\" width=\"10.2\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"441.5\" y=\"134.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">8,087</text><text x=\"100.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Q4 2025</text><rect x=\"110.0\" y=\"158.0\" width=\"319.1\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"429.1\" y=\"158.0\" width=\"55.9\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"485.0\" y=\"158.0\" width=\"12.0\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"505.0\" y=\"170.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">9,675</text><text x=\"100.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Q1 2026</text><rect x=\"110.0\" y=\"194.0\" width=\"398.5\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"508.5\" y=\"194.0\" width=\"70.7\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"579.2\" y=\"194.0\" width=\"16.4\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"603.6\" y=\"206.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">12,139</text><text x=\"100.0\" y=\"242.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Q2 2026</text><rect x=\"110.0\" y=\"230.0\" width=\"46.6\" height=\"24.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"156.6\" y=\"230.0\" width=\"101.1\" height=\"24.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><rect x=\"257.7\" y=\"230.0\" width=\"4.4\" height=\"24.0\" rx=\"0\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"0.5\"></rect><text x=\"270.2\" y=\"242.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3,804</text><text x=\"332.2\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">wholesale: 1,166</text></svg>", "caption": "Revenue by quarter and channel. The year total hid that the best quarter and the worst are next to each other, and that the fall is wholesale."}
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
