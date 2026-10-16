---
title: Wiring pivots, charts and slicers to one screen
version: 1
---

**Nothing on the dashboard is new; what is new is that every piece answers to the same two
controls.** The pivot tables are lesson 10's, the slicer and timeline lesson 11's, the charts lesson
12's and the measures lesson 16's. Built one by one, they work. Wired carelessly, they disagree with
each other on the same screen, and the reader cannot tell which one is right.

Nothing in this lesson was run in Excel. The numbers the dashboard shows are lesson 16's measures,
computed by applying them to the same sales, and the check formulas at the end of this section were
computed by a spreadsheet holding your data, as lesson 1 section 02 describes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 390\" role=\"img\" data-fig=\"l17-wiring\" aria-label=\"How the dashboard is wired. On the left, the data model with the tables Sales, Products, Customers and Calendar and the measures of lesson 16. In the middle, a sheet called Calc holding four pivot tables built from the model: KPI, Month, Channel and Product. On the right, the Dashboard sheet: KPI cells that read the KPI pivot with GETPIVOTDATA, and three PivotCharts drawn from the other three pivots. Below, a Channel slicer and a Calendar Date timeline whose report connections run to all four pivot tables.\"><rect x=\"20.0\" y=\"30.0\" width=\"180.0\" height=\"270.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">data model</text><rect x=\"30.0\" y=\"58.0\" width=\"160.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38.0\" y=\"69.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Sales</text><rect x=\"30.0\" y=\"84.0\" width=\"160.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Products</text><rect x=\"30.0\" y=\"110.0\" width=\"160.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38.0\" y=\"121.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Customers</text><rect x=\"30.0\" y=\"136.0\" width=\"160.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38.0\" y=\"147.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Calendar</text><text x=\"30.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">measures, lesson 16</text><text x=\"38.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Total Revenue</text><text x=\"38.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Revenue LY</text><text x=\"38.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Revenue YoY %</text><text x=\"38.0\" y=\"245.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Bags Sold</text><text x=\"38.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Sales Count</text><text x=\"38.0\" y=\"279.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Average Sale</text><rect x=\"250.0\" y=\"30.0\" width=\"196.0\" height=\"270.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"260.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Calc</text><text x=\"438.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hidden sheet</text><path d=\"M200.0 46.0 L248.0 46.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M248.0 46.0 L240.0 42.0 L240.0 50.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"560.0\" y=\"30.0\" width=\"180.0\" height=\"270.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"570.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Dashboard</text><rect x=\"290.0\" y=\"64.0\" width=\"140.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">KPI</text><text x=\"300.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pivot table</text><rect x=\"575.0\" y=\"64.0\" width=\"150.0\" height=\"40.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"84.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">KPI cells</text><path d=\"M430.0 84.0 L573.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M573.0 84.0 L565.0 80.0 L565.0 88.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"502.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">GETPIVOTDATA</text><rect x=\"290.0\" y=\"122.0\" width=\"140.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Month</text><text x=\"300.0\" y=\"151.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pivot table</text><rect x=\"575.0\" y=\"122.0\" width=\"150.0\" height=\"40.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"142.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chart of months</text><path d=\"M430.0 142.0 L573.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M573.0 142.0 L565.0 138.0 L565.0 146.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"502.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">PivotChart</text><rect x=\"290.0\" y=\"180.0\" width=\"140.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Channel</text><text x=\"300.0\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pivot table</text><rect x=\"575.0\" y=\"180.0\" width=\"150.0\" height=\"40.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"200.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chart of channels</text><path d=\"M430.0 200.0 L573.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M573.0 200.0 L565.0 196.0 L565.0 204.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"502.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">PivotChart</text><rect x=\"290.0\" y=\"238.0\" width=\"140.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"300.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Product</text><text x=\"300.0\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pivot table</text><rect x=\"575.0\" y=\"238.0\" width=\"150.0\" height=\"40.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"258.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chart of products</text><path d=\"M430.0 258.0 L573.0 258.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M573.0 258.0 L565.0 254.0 L565.0 262.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"502.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">PivotChart</text><rect x=\"575.0\" y=\"318.0\" width=\"70.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"610.0\" y=\"333.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Channel</text><rect x=\"652.0\" y=\"318.0\" width=\"88.0\" height=\"30.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"696.0\" y=\"333.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Calendar[Date]</text><path d=\"M575.0 333.0 L270.0 333.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M270.0 333.0 L270.0 84.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M270.0 84.0 L288.0 84.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M288.0 84.0 L280.0 80.0 L280.0 88.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M270.0 142.0 L288.0 142.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M288.0 142.0 L280.0 138.0 L280.0 146.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M270.0 200.0 L288.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M288.0 200.0 L280.0 196.0 L280.0 204.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M270.0 258.0 L288.0 258.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M288.0 258.0 L280.0 254.0 L280.0 262.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"280.0\" y=\"350.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Report Connections: all four pivot tables ticked</text><text x=\"740.0\" y=\"366.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slicer and timeline, on Dashboard</text></svg>", "caption": "Three layers: the model holds the data and the measures, the hidden Calc sheet holds the pivot tables, and the Dashboard shows what they answer. The slicer and the timeline reach every pivot table through their report connections, so the whole screen moves together."}
```

## Two new sheets

Add two sheets to `cafe-serra.xlsx`: `Dashboard`, which is all the reader sees, and `Calc`, which
holds the pivot tables the dashboard reads. **Keeping the pivots off the dashboard is the point.** A
pivot table changes size when a slicer changes: filter it to one channel and it loses rows, add a
year and it gains a column. On a sheet of its own it can grow and shrink freely. On the dashboard
it would push charts around, or run into the card below it.

The data sheets stay as they are, and so does the model.

## Four pivot tables on `Calc`

On `Calc`, insert four pivot tables from the data model (**Insert › PivotTable › From Data Model**),
with ten or so empty rows between them. Excel refuses to refresh a pivot that would grow over
another, so leave them room.

| pivot | rows | columns | values |
|---|---|---|---|
| `KPI` | none | none | `Total Revenue`, `Revenue LY`, `Revenue YoY %`, `Bags Sold`, `Sales Count`, `Average Sale` |
| `Month` | the calendar's month | the calendar's year | `Total Revenue` |
| `Channel` | `Channel` from `Sales` | none | `Total Revenue`, `Revenue LY` |
| `Product` | `Product` from `Sales`, sorted by `Total Revenue`, largest first | none | `Total Revenue` |

The `KPI` pivot has no rows at all, so each value has one cell, the total of whatever the slicer and
timeline let through. Put it at the top left of `Calc`, with its first cell in **A3**, because the
formulas below refer to that cell.

Give each pivot its name in the **PivotTable Name** box at the left of the **PivotTable Analyze**
tab. `PivotTable1` to `PivotTable4` are what the next step lists otherwise, and choosing among four
identical names is how a pivot gets left out.

## Three charts, moved to the dashboard

Click inside `Month` and choose **PivotTable Analyze › PivotChart**, then a clustered column chart:
one column per month for each year, side by side. Right-click the chart, choose **Move Chart**, and
put it as an object in `Dashboard`. A PivotChart can live on a different sheet from its pivot table
and still follow it. Do the same for `Channel` and `Product`, as bar charts.

On each chart, hide the field buttons with **PivotChart Analyze › Field Buttons**. They are
controls for somebody editing the chart, and on a dashboard they look like a second set of filters
that disagree with the slicer.

## One slicer and one timeline, connected to everything

Click inside any of the four pivots. **PivotTable Analyze › Insert Slicer** and tick `Channel` from
`Sales`; **PivotTable Analyze › Insert Timeline** and tick the date column of `Calendar`. Cut both
and paste them on `Dashboard`, in the band above the cards.

Now the step that breaks dashboards. A new slicer is connected only to the pivot you clicked in.
Right-click the slicer, choose **Report Connections**, and tick all four pivots. Then do the same
for the timeline.

**Leave one unticked and the screen contradicts itself.** Choose `Wholesale` on the slicer with
`KPI` left out: the channel chart shows R$ 11,128 for the half-year, and the Revenue card beside it
still shows R$ 15,943, the total of every channel. Each number is correct for what its pivot was
told. The screen is wrong, and nothing on it says so.

## The KPI cells

On `Dashboard`, click the cell where the Revenue card's number goes, type `=`, and click the
`Total Revenue` value of the `KPI` pivot on `Calc`. Excel writes the formula for you:

```localised
=GETPIVOTDATA("[Measures].[Total Revenue]", Calc!$A$3)
=GETPIVOTDATA("[Measures].[Revenue YoY %]", Calc!$A$3)
```

The name in brackets is how a pivot built from the data model calls a measure, and lesson 11 met
`GETPIVOTDATA` on an ordinary pivot. If Excel writes a plain `=Calc!B4` instead, the option is off:
it is **Generate GetPivotData**, in the **Options** list at the left of **PivotTable Analyze**.

**Use the `GETPIVOTDATA` form, not the plain reference.** `=Calc!B4` points at a position. The day
somebody adds a field to the pivot, the values move and the card shows a different number, with no
error. `GETPIVOTDATA` asks for a value by name and finds it wherever it is.

There is a second way to the same cells. **PivotTable Analyze › OLAP Tools › Convert to Formulas**
turns a pivot from the data model into one `CUBEVALUE` formula per cell, which can then be moved
anywhere. A cube formula follows a slicer when it is given the slicer's name, which **Slicer
Settings** shows as the name to use in formulas:

```localised
=CUBEVALUE("ThisWorkbookDataModel", "[Measures].[Total Revenue]", Slicer_Channel)
```

This lesson uses `GETPIVOTDATA`, because a pivot connected to both controls already carries both
filters, and there is less to get wrong.

Format the change cells with the number format `+0.0%;-0.0%;0.0%`, which writes the sign in front
of every change, and add the conditional format of lesson 9 for the colour. The sign is what a
colour-blind reader and a black-and-white printout still see.

The date in the title is one more formula, on the `Sales` table, formatted as a date:

```localised
=MAX(Sales[Date])
```

It answers 23 June 2026, the last sale in the data, and it moves on its own when new sales arrive.

## Checking the cards

With the timeline on January to June 2026 and the slicer on every channel, the cards read
R$ 15,943 and 168 bags in 36 sales, against R$ 17,789, 218 and 36 a year earlier. Revenue is down
10.4% and bags 22.9%. The measures already agreed with these formulas in lesson 16, but the
dashboard adds a slicer, a timeline and a pivot in between, and each is a place for the agreement
to break. Type these on any empty sheet:

```localised
=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2026,1,1), Sales[Date], "<"&DATE(2026,7,1))
=SUMIFS(Sales[Revenue], Sales[Date], ">="&DATE(2025,1,1), Sales[Date], "<"&DATE(2025,7,1))
=COUNTIFS(Sales[Date], ">="&DATE(2026,1,1), Sales[Date], "<"&DATE(2026,7,1))
```

They answer **15,943**, **17,789** and **36**. Now choose `Wholesale` on the slicer. Every part of
the screen should move together: the Revenue card to R$ 11,128 against R$ 13,392, 16.9% down, from
9 sales against 15. The same check with the channel added:

```localised
=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale", Sales[Date], ">="&DATE(2026,1,1), Sales[Date], "<"&DATE(2026,7,1))
```

answers **11,128**. Choose `Online`, and revenue reads R$ 4,295 against R$ 3,853, up 11.5%, the one
channel that grew.

Last, clear the slicer and drag the timeline to April to June 2026. Revenue drops to R$ 3,804
against R$ 8,486 a year before; January to March reads R$ 12,139 against R$ 9,303. If a card did
not move with the chart of months, its pivot is missing from the timeline's report connections.
