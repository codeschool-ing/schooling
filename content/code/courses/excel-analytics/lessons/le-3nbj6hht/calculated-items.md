---
title: Calculated items, and why to avoid them
version: 1
---

**A calculated item is a new row inside a field, built from other rows of the same field, and the
grand total adds it like any other row.** That is the whole problem with it. Wherever the new row
repeats money that is already in the field, the total counts that money twice, and the pivot table
gives no sign of it.

## Building one, to watch it fail

Café Serra calls its web shop and its counter together the *direct* channels, as against
wholesale. Make a second pivot table from the table `Sales` on a **New Worksheet**, rename the sheet
`Channels`, and put `Channel` in **Rows** and `Revenue` in **Values**. Then:

1. Click one of the channel names in the pivot, such as `Online`. The command is greyed out until
   the active cell is an item of the field the new item will join.
2. Choose **PivotTable Analyze › Fields, Items, & Sets › Calculated Item**.
3. In **Name**, type `Direct`. In **Formula**, type the formula below; double-clicking an item in
   the **Items** list types its name.
4. Click **Add**, then **OK**.

```localised
=Online+Shop
```

`Direct` arrives as a fourth channel, and the grand total has grown:

| `Channel` | `Sum of Revenue` |
|---|---|
| `Online` | 11,143 |
| `Shop` | 1,620 |
| `Wholesale` | 38,731 |
| `Direct` | 12,763 |
| Grand Total | **64,257** |

Café Serra's revenue is 51,494. The grand total is 12,763 too high, by 24.8%, because every online
and shop sale is now counted once under its own channel and again under `Direct`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 250\" role=\"img\" data-fig=\"l11-item\" aria-label=\"Two pivot tables of revenue by channel. On the left, a calculated item Direct, equal to Online plus Shop, sits in the Channel field beside them, and the grand total adds all four rows: 64257 instead of 51494. On the right, Online and Shop are grouped under Direct and the grand total stays 51494.\"><text x=\"40.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a calculated item: Direct = Online + Shop</text><rect x=\"40.0\" y=\"34.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"47.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Row Labels</text><rect x=\"190.0\" y=\"34.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"47.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Sum of Revenue</text><rect x=\"40.0\" y=\"60.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"73.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Online</text><rect x=\"190.0\" y=\"60.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"73.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">11,143</text><rect x=\"40.0\" y=\"86.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"99.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop</text><rect x=\"190.0\" y=\"86.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"99.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1,620</text><rect x=\"40.0\" y=\"112.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"125.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Wholesale</text><rect x=\"190.0\" y=\"112.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"125.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">38,731</text><rect x=\"40.0\" y=\"138.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"151.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Direct</text><rect x=\"190.0\" y=\"138.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"151.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">12,763</text><rect x=\"40.0\" y=\"164.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"177.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Grand Total</text><rect x=\"190.0\" y=\"164.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"177.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">64,257</text><path d=\"M332 73 L340 73 L340 99 L332 99\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M332 151 L340 151\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M340.0 99.0 L340.0 151.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"348.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">12,763 counted twice</text><text x=\"40.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the real total is 51,494</text><text x=\"505.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a group: Online and Shop under Direct</text><rect x=\"505.0\" y=\"34.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"47.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Row Labels</text><rect x=\"625.0\" y=\"34.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"47.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Sum of Revenue</text><rect x=\"505.0\" y=\"60.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"73.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Direct</text><rect x=\"625.0\" y=\"60.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"73.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">12,763</text><rect x=\"505.0\" y=\"86.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"99.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">   Online</text><rect x=\"625.0\" y=\"86.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"99.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">11,143</text><rect x=\"505.0\" y=\"112.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"125.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">   Shop</text><rect x=\"625.0\" y=\"112.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"125.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1,620</text><rect x=\"505.0\" y=\"138.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"151.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Wholesale</text><rect x=\"625.0\" y=\"138.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"151.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">38,731</text><rect x=\"505.0\" y=\"164.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"177.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Grand Total</text><rect x=\"625.0\" y=\"164.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"177.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">51,494</text><text x=\"505.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">each sale is in exactly one row</text><text x=\"505.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">so the total is still the total</text></svg>", "caption": "A calculated item is a new row in the field, and the grand total adds every row it finds. A group puts the same sales under a new heading without counting them again."}
```

## What else it costs

The grand total is the visible failure. Three others are quieter:

- **It turns up everywhere.** Drag `Product` into **Rows** above `Channel` and every product grows a
  `Direct` row of its own, computed whether or not it means anything there.
- **It does not mix with grouping.** Excel refuses to add a calculated item to a field while that
  field is grouped, so the grouping of lesson 10 and a calculated item cannot share a field.
- **Its formula is hidden.** Somebody reading the pivot sees a row called `Direct` and has no way to
  tell that it is not a channel in the data. The formula lives in a dialog nobody opens.

A pivot table built on the data model of lesson 15 does not offer calculated items at all.

Delete it before going on: **Fields, Items, & Sets › Calculated Item**, choose `Direct` in the
**Name** list, and click **Delete**. The grand total returns to 51,494.

## Two ways to have `Direct` without one

**Group the items.** In the pivot, click `Online`, hold Ctrl and click `Shop`, then right-click
and choose **Group**. Excel adds a new field called `Channel2` with two items: `Group1`, holding
`Online` and `Shop`, and `Wholesale`, holding itself. Click the cell `Group1` and type `Direct` to
rename it. The rows now read `Direct` 12,763 and `Wholesale` 38,731, and the grand total stays
51,494, because a group is a heading over sales and not a copy of them. Right-click a group and
choose **Ungroup** to take it away.

**Put it in the data.** If `Direct` is a word the business uses in more than one report, it is a
fact about each sale, and a fact about a row belongs in a column. Type `Route` in I1 of the
`Sales` sheet, next to the table, and the table takes the column in, as lesson 7 showed. Then in
I2:

```localised
=IF([@Channel]="Wholesale", "Wholesale", "Direct")
```

The table fills it down. Refresh the pivot table and `Route` is a field like any other, ready for
every pivot table, every formula and every chart:

```localised
=SUMIFS(Sales[Revenue], Sales[Route], "Direct")
=COUNTIFS(Sales[Route], "Direct")
```

The first gives **12,763** and the second **70** sales. The group is quicker for one pivot table;
the column is the one that lasts.

The rest of this course works with the eight columns of lesson 7, so delete `Route` now: right-click
a cell of it and choose **Delete › Table Columns**, then refresh the pivot table.
