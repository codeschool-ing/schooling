---
title: GETPIVOTDATA, a reference by name
version: 1
---

**Click a pivot table's cell while typing a formula and Excel does not write `=B4`. It writes a
formula that finds the number by its field and item names, wherever the pivot table has put it.**
That formula, `GETPIVOTDATA`, surprises everybody the first time, and most people switch it off
before learning what it protects them from.

## What Excel writes

On the `Report` sheet, with every slicer button lit, click F4, type `=` and click B4, the revenue of
`CER1K`. Excel writes this and answers 21,356:

```localised
=GETPIVOTDATA("Revenue",$A$3,"Product","CER1K")
```

The arguments, in order:

| argument | here | what it says |
|---|---|---|
| the value field | `"Revenue"` | which number: the field's own name, not `Sum of Revenue` |
| a cell of the pivot table | `$A$3` | which pivot table: any cell of it does, and Excel uses its top-left corner |
| field and item, in pairs | `"Product","CER1K"` | which cell: as many pairs as it takes to name exactly one |

With no pairs at all, it names the grand total, and answers 51,494:

```localised
=GETPIVOTDATA("Revenue",$A$3)
```

## Why a name is safer than a position

Type `=B5` in F5 instead. B5 is the cell beside `CER250`, so it shows 837. Now click `Wholesale` in
the slicer. `CER250` has no wholesale sales and leaves the table, every row below it moves up one,
and B5 now holds the wholesale revenue of `DEC250`. `=B5` shows 1,330, and nothing on the sheet says
it has stopped being `CER250`.

Ask for the same product by name:

```localised
=GETPIVOTDATA("Revenue",$A$3,"Product","CER250")
```

With `Wholesale` lit it answers `#REF!`: there is no `CER250` in the pivot table to read. A wrong
number that looks right is the worst thing a report can contain, and an error that says something
moved is the best way to fail.

The formula for `CER1K` in F4 now shows 17,168, the wholesale figure. **`GETPIVOTDATA` returns what
the pivot table shows**, so a slicer or a timeline changes its answer exactly as it changes the
cell. To keep a number that ignores the slicers, use a `SUMIFS` on the table instead, as lesson 5
does.

## A cell in place of the item

The item does not have to be typed into the formula. Light every slicer button, type `SUL1K` in F3,
and in G3:

```localised
=GETPIVOTDATA("Revenue",$A$3,"Product",F3)
```

It answers 21,082, and typing another product code in F3 changes the answer. The formula has become
a lookup into the pivot table, and the key performance cells of lesson 17's dashboard are built this
way.

## Switching it off, and when to

`GETPIVOTDATA` gets in the way when you want a formula you can fill down beside the pivot table: a
filled-down copy keeps naming `"CER1K"` on every row, where `=B4` would have moved to `B5`, `B6` and
on. For that, switch the behaviour off with **PivotTable Analyze › Options**, the arrow beside it,
and **Generate GetPivotData**, which is a switch that flips each time you click it. The same switch
is in **File › Options › Formulas**, as **Use GetPivotData functions for PivotTable references**.
It is a setting of Excel on your computer, not of the workbook, so it stays off in every file until
you turn it back on.

Clicking a pivot cell then types a plain reference. Turn it back on when you are done: the rest of
this course takes it as on.
