---
title: Excel in practice, and the two rules that prevent most of it
version: 1
---

## The dollar sign, which is the one piece of syntax

A reference like `C1` **moves when the formula moves.** Copy `=B2*C1` down a column and it becomes
`=B3*C2`, then `=B4*C3` — which is right for the first part and wrong for the second, if `C1` is
the tax rate everything is multiplied by.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two panels showing the same formula copied down three rows. On the left, without dollar signs, both references move: B2 times C1 becomes B3 times C2 and then B4 times C3, so the rate drifts away from the cell that holds it. On the right, with dollar signs around C1, only the first reference moves and every row multiplies by the same rate.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The same formula, copied down three rows</text><rect x=\"24\" y=\"36\" width=\"322\" height=\"182\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">copied down as written</text><text x=\"44\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B2*C1</text><text x=\"44\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B3*C2</text><text x=\"44\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B4*C3</text><text x=\"44\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the rate walks away from its cell</text><rect x=\"374\" y=\"36\" width=\"322\" height=\"182\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"394\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">copied down with two dollar signs</text><text x=\"394\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B2*$C$1</text><text x=\"394\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B3*$C$1</text><text x=\"394\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">=B4*$C$1</text><text x=\"394\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">every row uses the rate in C1</text><text x=\"24\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A dollar sign freezes what follows it. The reference stops moving when the formula does.</text></svg>", "caption": "This is the whole of what the dollar sign does, and it is the difference between a column of totals and a column of nonsense that looks plausible."}
```

`F4` cycles a reference through the four forms while you are typing it: `C1`, `$C$1`, `C$1`,
`$C1`. The middle two freeze one direction and are what you want in a multiplication table.

## The two rules

**Never type a number into a formula.** `=B2*0.17` is a spreadsheet where the rate is written in
eighty places and cannot be found. Put the rate in a cell, label the cell, and refer to it. When
the rate changes you change one thing, and anybody can see what the sheet assumes.

**One thing per column, one record per row.** A column called `address` holding a street, a city
and a postcode cannot be sorted by city or filtered by postcode. Splitting it afterwards is a
morning; putting it in three columns to begin with is free.

## The functions that cover most of it

| | what it does |
|---|---|
| `SUM`, `AVERAGE`, `COUNT` | the three everybody already knows |
| `IF` | a value that depends on a condition. The workhorse |
| `COUNTIF`, `SUMIF` | count or total only the rows that match something |
| `XLOOKUP` | find a row by a value and bring back a column of it |
| `TEXT`, `LEFT`, `RIGHT`, `TRIM` | pulling one piece out of a messy column |
| `IFERROR` | show something sensible instead of `#N/A` |

**`XLOOKUP` replaces `VLOOKUP`** and is worth learning in its place: it looks in any direction, it
does not break when a column is inserted, and it takes a not-found value instead of an error. If
you learned `VLOOKUP`, the only thing to keep from it is the idea.

## Tables, which are the feature people skip

Select a range and press `Ctrl+T`. The range becomes a **table**, and four things change:

- **Formulas fill down automatically** when a row is added.
- **Filters and sorting** appear on every column.
- **References become names** — `=SUM(Sales[Amount])` instead of `=SUM(D2:D847)`, which stays
  correct when rows are added.
- **The range grows** when you type under it, so every chart and formula pointing at it grows too.

That last property is the one that matters, because the commonest spreadsheet error is a formula
still covering the first eight hundred rows of a sheet that now has nine hundred.

## Three habits that show up as correctness

- **Freeze the top row** — *View, Freeze Panes* — so the headings stay visible. Scrolling into
  anonymous columns is how the wrong column gets edited.
- **Never sort one column on its own.** Select the whole range, or use a table. Sorting a single
  column separates it from the rows it described, silently and irreversibly.
- **Check the total against something.** A `COUNT` beside a `SUM` catches the text-in-a-number-
  column problem from the last section, and it is the only check that costs nothing.
