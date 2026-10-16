---
title: Sparklines, a chart in a cell
version: 1
---

**A sparkline is a chart the size of one cell: no title, no axes, no labels, only the shape of a row
of numbers.** It answers one question a table of numbers hides, *which way is this going?*, and it
answers it for every row at once, beside the numbers themselves.

## A grid to draw from

A sparkline draws one row (or one column) of a range, so it needs the numbers laid out as a grid:
products down the side, months across the top. Add a sheet called `Trends`:

1. Type `Product` in A1 and the six product codes in A2:A7, in the order of the `Products` sheet.
2. Type the date `2025-01-01` in B1. In C1 type the formula below and fill it right to S1, the first
   of June 2026.

```localised
=EDATE(B1,1)
```

3. In B2, the bags of one product in one month:

```localised
=SUMIFS(Sales[Bags], Sales[Product], $A2, Sales[Date], ">="&B$1, Sales[Date], "<"&EDATE(B$1,1))
```

`$A2` keeps the column and lets the row move, and `B$1` keeps the row and lets the column move: the
mixed references of lesson 2, which let one formula fill the whole grid. Fill B2 right to S2, then
fill B2:S2 down to row 7. Check the grid against the table:

```localised
=SUM(B2:S7)
```

It answers 591, every bag in lesson 1's data.

## Inserting them

Select T2:T7, choose **Insert › Sparklines › Line**, type `B2:S7` in **Data Range**, and click
**OK**. The **Location Range** is already T2:T7, the cells you selected. Each of the six cells now
holds a small line, one per product, eighteen months long. Widen column T so the lines have room.

On the **Sparkline** tab, **Show › High Point** marks each line's best month with a dot. For `CER1K`
it lands on October 2025, 39 bags; for `CER250` on July 2025, 6 bags. The same tab changes the type to
**Column**, which suits counts like these as well as a line does, or to **Win/Loss**, which draws
only whether each value is above or below zero.

## Each its own scale, or one for all

By default every sparkline is scaled to its own highest and lowest values. So `CER250`, whose best
month was 6 bags, rises to the top of its cell exactly as `CER1K` does for 39. Looking down column T,
the six products seem equally busy.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" data-fig=\"l12-sparklines\" aria-label=\"Bags sold per month, January 2025 to June 2026, as one small line per product, drawn twice. In the first column every line is scaled to its own highest month, so CER250, whose best month was 6 bags, swings as wildly as CER1K, whose best was 39. In the second column every line shares one scale, from 0 to 39 bags, and the small products lie almost flat.\"><text x=\"130.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">each sparkline, its own scale</text><text x=\"400.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">one scale for all, 0 to 39</text><text x=\"668.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">best month</text><rect x=\"30.0\" y=\"40.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CER1K</text><path d=\"M130.0 57.3 L143.5 66.7 L157.1 70.0 L170.6 68.0 L184.1 60.7 L197.6 70.0 L211.2 67.3 L224.7 60.0 L238.2 67.3 L251.8 44.0 L265.3 61.3 L278.8 62.0 L292.4 53.3 L305.9 54.0 L319.4 70.0 L332.9 66.7 L346.5 65.3 L360.0 62.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"251.8\" cy=\"44.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 57.3 L413.5 66.7 L427.1 70.0 L440.6 68.0 L454.1 60.7 L467.6 70.0 L481.2 67.3 L494.7 60.0 L508.2 67.3 L521.8 44.0 L535.3 61.3 L548.8 62.0 L562.4 53.3 L575.9 54.0 L589.4 70.0 L602.9 66.7 L616.5 65.3 L630.0 62.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"521.8\" cy=\"44.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"57.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">39</text><rect x=\"30.0\" y=\"80.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CER250</text><path d=\"M130.0 110.0 L143.5 110.0 L157.1 110.0 L170.6 101.3 L184.1 88.3 L197.6 110.0 L211.2 84.0 L224.7 110.0 L238.2 110.0 L251.8 110.0 L265.3 97.0 L278.8 105.7 L292.4 97.0 L305.9 105.7 L319.4 110.0 L332.9 110.0 L346.5 101.3 L360.0 105.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"211.2\" cy=\"84.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 110.0 L413.5 110.0 L427.1 110.0 L440.6 108.7 L454.1 106.7 L467.6 110.0 L481.2 106.0 L494.7 110.0 L508.2 110.0 L521.8 110.0 L535.3 108.0 L548.8 109.3 L562.4 108.0 L575.9 109.3 L589.4 110.0 L602.9 110.0 L616.5 108.7 L630.0 109.3\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"481.2\" cy=\"106.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"97.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><rect x=\"30.0\" y=\"120.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DEC250</text><path d=\"M130.0 148.6 L143.5 130.8 L157.1 124.0 L170.6 143.2 L184.1 137.7 L197.6 143.2 L211.2 148.6 L224.7 148.6 L238.2 150.0 L251.8 144.5 L265.3 150.0 L278.8 140.4 L292.4 145.9 L305.9 148.6 L319.4 150.0 L332.9 145.9 L346.5 144.5 L360.0 134.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"157.1\" cy=\"124.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 149.3 L413.5 140.7 L427.1 137.3 L440.6 146.7 L454.1 144.0 L467.6 146.7 L481.2 149.3 L494.7 149.3 L508.2 150.0 L521.8 147.3 L535.3 150.0 L548.8 145.3 L562.4 148.0 L575.9 149.3 L589.4 150.0 L602.9 148.0 L616.5 147.3 L630.0 142.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"427.1\" cy=\"137.3\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"137.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">19</text><rect x=\"30.0\" y=\"160.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">MOG250</text><path d=\"M130.0 190.0 L143.5 178.6 L157.1 180.2 L170.6 190.0 L184.1 190.0 L197.6 170.5 L211.2 177.0 L224.7 172.1 L238.2 186.8 L251.8 190.0 L265.3 190.0 L278.8 164.0 L292.4 183.5 L305.9 186.8 L319.4 190.0 L332.9 190.0 L346.5 188.4 L360.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"278.8\" cy=\"164.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 190.0 L413.5 185.3 L427.1 186.0 L440.6 190.0 L454.1 190.0 L467.6 182.0 L481.2 184.7 L494.7 182.7 L508.2 188.7 L521.8 190.0 L535.3 190.0 L548.8 179.3 L562.4 187.3 L575.9 188.7 L589.4 190.0 L602.9 190.0 L616.5 189.3 L630.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"548.8\" cy=\"179.3\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"177.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">16</text><rect x=\"30.0\" y=\"200.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SUL1K</text><path d=\"M130.0 217.4 L143.5 227.0 L157.1 217.4 L170.6 216.6 L184.1 230.0 L197.6 212.2 L211.2 226.3 L224.7 224.1 L238.2 213.7 L251.8 230.0 L265.3 221.1 L278.8 230.0 L292.4 218.1 L305.9 230.0 L319.4 204.0 L332.9 230.0 L346.5 230.0 L360.0 230.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"319.4\" cy=\"204.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 218.7 L413.5 227.3 L427.1 218.7 L440.6 218.0 L454.1 230.0 L467.6 214.0 L481.2 226.7 L494.7 224.7 L508.2 215.3 L521.8 230.0 L535.3 222.0 L548.8 230.0 L562.4 219.3 L575.9 230.0 L589.4 206.7 L602.9 230.0 L616.5 230.0 L630.0 230.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"589.4\" cy=\"206.7\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"217.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">35</text><rect x=\"30.0\" y=\"240.0\" width=\"700.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"44.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SUL250</text><path d=\"M130.0 261.3 L143.5 248.3 L157.1 270.0 L170.6 261.3 L184.1 265.7 L197.6 261.3 L211.2 270.0 L224.7 252.7 L238.2 261.3 L251.8 265.7 L265.3 252.7 L278.8 270.0 L292.4 270.0 L305.9 261.3 L319.4 265.7 L332.9 244.0 L346.5 270.0 L360.0 270.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"332.9\" cy=\"244.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><path d=\"M400.0 268.7 L413.5 266.7 L427.1 270.0 L440.6 268.7 L454.1 269.3 L467.6 268.7 L481.2 270.0 L494.7 267.3 L508.2 268.7 L521.8 269.3 L535.3 267.3 L548.8 270.0 L562.4 270.0 L575.9 268.7 L589.4 269.3 L602.9 266.0 L616.5 270.0 L630.0 270.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" stroke-linejoin=\"round\" stroke-linecap=\"round\"></path><circle cx=\"602.9\" cy=\"266.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--panel)\" stroke-width=\"1.5\"></circle><text x=\"712.0\" y=\"257.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"130.0\" y=\"290.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the dot marks the high point, as Sparkline › High Point does</text></svg>", "caption": "Sparklines scaled one by one show the shape of each product's months and hide their size; one shared scale shows the size and flattens the small ones. Which is right depends on whether the rows are being compared with each other."}
```

**Sparkline › Axis** changes that. Under **Vertical Axis Maximum Value Options** choose **Same for
All Sparklines**, and do the same under **Vertical Axis Minimum Value Options**. Now every line runs
on one scale, from 0 to 39 bags, and the small products lie almost flat, as small products should.

Neither setting is wrong. **Each its own scale shows the shape** of each product's eighteen months,
which suits a reader asking whether a product is growing. **One scale for all shows the size**,
which suits a reader comparing products. Say which one the column uses, in its header or a note
beside it, because a sparkline carries no axis to say it for you.

## A sparkline is part of a cell

A sparkline is not an object floating over the sheet like a chart. It belongs to its cell: it sits
behind whatever the cell holds, prints with it, and is removed with **Sparkline › Clear** rather than
the Delete key, which leaves it where it is. A column of them beside a table of numbers is where they
work best.
