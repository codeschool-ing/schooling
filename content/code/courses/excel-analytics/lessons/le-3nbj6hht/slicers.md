---
title: Slicers, a filter you can see
version: 1
---

**A slicer is a pivot table's filter drawn as a row of buttons, and what it adds over the Filters
area is that it shows what is selected.** A field in **Filters** with two items chosen reads
`(Multiple Items)` and makes the reader open it to find out which. A slicer lights the chosen
buttons, so anybody looking at the sheet knows what the numbers are numbers of.

## Adding one

This section and the next three work on one pivot table. Build it from the table `Sales` on a **New
Worksheet**, rename the sheet `Report`, and put `Product` in **Rows** and `Revenue` in **Values**.
Then:

1. Click a cell of the pivot table.
2. Choose **PivotTable Analyze › Insert Slicer**.
3. Tick `Channel` and click **OK**.

A box with three buttons, `Online`, `Shop` and `Wholesale`, appears over the sheet. It floats like a
picture: drag it beside the pivot table so it covers nothing. Now click `Wholesale`.

| `Product` | `Sum of Revenue` |
|---|---|
| `CER1K` | 17,168 |
| `DEC250` | 1,330 |
| `MOG250` | 2,397 |
| `SUL1K` | 17,836 |
| Grand Total | 38,731 |

Two things changed besides the numbers. `CER250` and `SUL250` left the table, because no wholesale
customer ever bought them. And `SUL1K` moved ahead of `CER1K`: over all channels the Cerrado bag
leads, 21,356 to 21,082, and in wholesale it is second. The formulas of lesson 5 say the same:

```localised
=SUMIFS(Sales[Revenue], Sales[Product], "SUL1K", Sales[Channel], "Wholesale")
=SUMIFS(Sales[Revenue], Sales[Product], "CER1K", Sales[Channel], "Wholesale")
```

They answer 17,836 and 17,168.

`Channel` is in none of the four areas of the pivot table, and it filters anyway. **A slicer can
filter by any field of the source**, whether the layout shows that field or not.

## Choosing more than one

Hold Ctrl and click a second button to add it to the selection, or click the **Multi-Select** button
in the slicer's header, after which every click switches one button on or off. With `Online` and
`Shop` lit, the grand total is **12,763**: the `Direct` revenue of the previous section, reached
without adding a row anywhere.

To show everything again, click **Clear Filter**, the funnel with a cross in the slicer's header,
or select the slicer and press Alt+C.

## Buttons with no data

Insert a second slicer, on `Product`, and keep `Wholesale` lit in the first. In the `Product` slicer,
`CER250` and `SUL250` are drawn faded and moved to the end. They are still there and still
clickable, but nothing in the current selection contains them. The two slicers are answering each
other: each one shows which of its buttons still have something to show after what the others
chose.

That behaviour is a setting. Right-click a slicer and choose **Slicer Settings** to change it, to
rename the caption over the buttons, or to sort them. On the **Slicer** tab, **Columns** lays the
buttons out side by side, which suits a field with a few short values such as `Channel`.

Delete the `Product` slicer before going on: click it and press Delete. Keep the `Channel` slicer,
with every button lit.
