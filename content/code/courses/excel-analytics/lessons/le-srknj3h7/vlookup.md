---
title: VLOOKUP, and its three traps
version: 1
---

**`VLOOKUP` is the lookup most existing workbooks are built on, and it fails silently in three
ways that `XLOOKUP` was designed to remove.** You will meet it in every file older than a few years,
and in files written by people who learnt Excel before 2021, so you need to read it and to know
where it breaks, even if you choose not to write it.

## How it is written

`VLOOKUP` takes the key, a whole table whose **first column** is searched, the **number** of the
column to bring back, counted from the left of that table, and a fourth argument about matching.
The list price of S1001:

```localised
=VLOOKUP(D2,Products!$A$2:$G$7,6,FALSE)
```

It answers **118**, the same as `XLOOKUP`. The 6 is `List price`, counted along A to G: `Code` 1,
`Product` 2, `Origin` 3, `Roast` 4, `Grams` 5, `List price` 6. The `FALSE` asks for an exact match.

## Trap 1: the column is a number

The 6 is not a reference. It is a count, typed once, and nothing updates it. Suppose somebody
inserts a column in `Products` to the left of `List price`, say a `Supplier` column after `Grams`.
The table reference follows the insertion and becomes `$A$2:$H$7`, but the 6 stays 6, and column 6
is now the new, empty `Supplier`. Every list price brought back by the formula becomes **0**. No
error: zero is a number, and a column of zeros sums without complaint.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-shifted\" aria-label=\"Two copies of the header row of Products, counted from 1 under each column. Before: Code, Product, Origin, Roast, Grams, List price, Unit cost, and the column number 6 of the VLOOKUP points at List price. After a Supplier column is inserted after Grams, the number 6 points at the new, empty Supplier column, and List price has become column 7.\"><text x=\"12.0\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">before</text><rect x=\"60.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"66.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Code</text><rect x=\"134.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"140.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Product</text><rect x=\"208.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"214.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Origin</text><rect x=\"282.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Roast</text><rect x=\"356.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"362.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Grams</text><rect x=\"430.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"436.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">List price</text><rect x=\"504.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"510.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Unit cost</text><text x=\"97.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"171.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><text x=\"245.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"319.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text><text x=\"393.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5</text><text x=\"467.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">6</text><text x=\"541.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7</text><text x=\"12.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">after</text><rect x=\"60.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"66.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Code</text><rect x=\"134.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"140.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Product</text><rect x=\"208.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"214.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Origin</text><rect x=\"282.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Roast</text><rect x=\"356.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"362.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Grams</text><rect x=\"430.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"436.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Supplier</text><rect x=\"504.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"510.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">List price</text><rect x=\"578.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"584.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Unit cost</text><text x=\"97.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"171.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><text x=\"245.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"319.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text><text x=\"393.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5</text><text x=\"467.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">6</text><text x=\"541.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7</text><text x=\"615.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">8</text><text x=\"60.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">VLOOKUP(…, 6, FALSE) brings back List price</text><text x=\"60.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the same 6 now brings back the empty Supplier: 0 on every row</text></svg>", "caption": "The column number is a count typed once. Insert a column inside the table and the count points at a different field, with no error."}
```

An `XLOOKUP` or an `INDEX` formula pointed at `Products!$F$2:$F$7` is a reference, and inserting a
column moves it to `G`, where the prices went. Try it on a copy, or undo the insertion right away.

## Trap 2: the default is the wrong match

The fourth argument is optional, and when it is left out it means `TRUE`: an **approximate**
match. Approximate matching assumes the first column is sorted in ascending order and returns the
row of the largest key not greater than the one you asked for. The product codes are not sorted.
On unsorted keys an approximate match can land on a row that is merely close in the sort order:
some rows come out right, others carry a neighbour's price, and there is no error to say which is
which.

So `VLOOKUP` for a code is always written with `FALSE` at the end. Section 06 shows where the
approximate match is exactly what you want, on a table built for it.

## Trap 3: it cannot look left

The searched column is always the first column of the table, so the value brought back is always to
its right. Asked which code belongs to `Decaf 250 g`, `VLOOKUP` would have to search column B and
return column A, and it cannot. The usual workaround was to copy the code column to the right of
the names, a second copy of the data that drifts from the first. `XLOOKUP` and `INDEX` with `MATCH`
search any column and return any other.

## When you still write it

Write `VLOOKUP` when the workbook will be opened in an Excel older than 2021, where `XLOOKUP` gives
`#NAME?`, or when you are extending a file already built on it and consistency matters more. In
either case write all four arguments, and prefer `INDEX` and `MATCH`, the next section, which work
in every version and have none of the three traps.

`HLOOKUP` is the same function turned on its side, searching the first **row** of a table and
returning a value from a row below it. It has the same three traps, and in a sheet of one row per
record you will rarely need it.
