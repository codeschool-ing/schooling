---
title: Refresh, and the copy a pivot reads
version: 1
---

**A pivot table does not read the `Sales` table. It reads a copy of it, called the pivot cache,
taken when the pivot was built or last refreshed.** A formula recalculates the moment a cell it
depends on changes; a pivot changes only when somebody refreshes it. Everything that goes wrong
with pivots in practice comes from forgetting this.

```schooling-figure
{"svg": "<svg data-fig=\"l10-cache\"></svg>", "caption": ""}
```

## Seeing the copy

Keep the `By channel` pivot of section 02 on screen, with the check formula from the same section
beside it, or in a cell of the same sheet:

```localised
=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")
```

Both say **38,731**. Now go to the `Sales` table and change the bags of sale `S1001`, in E2, from
`14` to `15`. Its revenue becomes 1,560. Back on `By channel`:

- the formula says **38,835**, the new total, at once;
- the pivot still says **38,731**.

Right-click the pivot and choose **Refresh**. It now says **38,835** as well, and its grand total
is **51,598**. **When a pivot and a formula disagree, refresh the pivot before suspecting
anything else**; it is the commonest cause by far.

Put `14` back in E2 and refresh again, so that the totals return to **38,731** and **51,494**.
The lessons after this one assume the original data.

## Refreshing everything

**Data › Refresh All** refreshes every pivot table in the workbook, and every query, which lessons
13 and 14 add. In **PivotTable Analyze › Options**, on the **Data** tab, the box **Refresh data
when opening the file** makes Excel refresh the pivot each time the workbook opens. That covers a
workbook that somebody else updates and you only read; it does not help while you edit, because the
file is already open.

## New rows

A sale added at the bottom of the `Sales` table joins the table, as lesson 7 showed, and the next
refresh brings it into the pivot, because the pivot's source is the table rather than a fixed
address. To see the source, use **PivotTable Analyze › Change Data Source**: it should read
`Sales`.

A pivot built on an address such as `Sales!$A$1:$H$109` keeps reading those cells. A sale typed in
row 110 is outside them, and no amount of refreshing brings it in; the source has to be widened
through **Change Data Source** by hand, every time. It is the same trap as the fixed list in lesson
8, and the same cure: build on the table.

## When a refresh changes the layout

A refresh re-reads the data, so it can add rows the pivot did not have before: a new product, a new
quarter, or a misspelt channel. It can also make the pivot wider or longer, and **a pivot that grows
does not push cells out of its way**. If there is anything in the cells it needs, Excel asks before
overwriting, or refuses. Leave empty space around a pivot, or give each pivot its own sheet, as this
lesson did.

Keep the pivot sheets of this lesson. Lesson 17 builds a dashboard from pieces of this kind, and
lesson 11 adds calculated fields, slicers and timelines to pivots like these.
