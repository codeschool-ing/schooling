---
title: INDEX and MATCH
version: 1
---

**`MATCH` finds the position of a key, and `INDEX` returns whatever sits at a position. Together
they are a lookup that works in every version of Excel.** Before `XLOOKUP` existed, this pair was
how careful people avoided `VLOOKUP`'s traps, and it is still what to write for a workbook that will
be opened in an older Excel.

## MATCH: where is it?

`MATCH` takes the key, a single column to search, and a match type, and returns a position. Type it
in any empty cell on row 2 of `Sales`:

```localised
=MATCH(D2,Products!$A$2:$A$7,0)
```

It answers **4**: `CER1K` is the fourth code in A2:A7. The 0 asks for an exact match, and like
`VLOOKUP`'s fourth argument it is optional and dangerous to leave out, because the default is an
approximate match on sorted data. Always write the 0 for a code.

## INDEX: what is there?

`INDEX` takes a range and a position, and returns the value at that position:

```localised
=INDEX(Products!$G$2:$G$7,4)
```

answers **61**, the fourth unit cost, which is `CER1K`'s.

## The two together

Put the `MATCH` where the 4 was, and the position is found for every row instead of typed:

```localised
=INDEX(Products!$G$2:$G$7,MATCH(D2,Products!$A$2:$A$7,0))
```

Replace K2 with it and fill down. Every cost is the same as `XLOOKUP` gave, and `=SUM(L2:L109)`
still answers **21104**: two formulas, written differently, agreeing on the same data. That
agreement is the check, and it is worth making whenever you rewrite a formula you already trust.

Read the pair from the inside out, the way lesson 3 read a nested `IF`. `MATCH` answers "which
row?", and `INDEX` answers "what is in that row of this column?". The column searched and the
column returned are two separate references, so the second can be to the left of the first, and
inserting a column in `Products` moves each reference with its data. That is why the pair has none
of `VLOOKUP`'s three traps.

## Two MATCHes: a row and a column

`INDEX` also takes a whole table with a row position and a column position. Find each with its own
`MATCH`, one down the codes and one across the headers, and the formula looks up a product and a
field by name:

```localised
=INDEX(Products!$A$1:$G$7,MATCH("MOG250",Products!$A$1:$A$7,0),MATCH("Unit cost",Products!$A$1:$G$1,0))
```

It answers **30**: the unit cost of the Mogiana Reserve. Both ranges start at row 1 this time,
because the second `MATCH` searches the header row; the positions are counted within the ranges
given, so the three ranges have to start at the same row and column. Put `MOG250` and `Unit cost`
in cells of their own, refer to those cells instead of typing the words, and you have a small
lookup panel: change either cell and the answer follows.

## Which one to write

| | `XLOOKUP` | `INDEX` and `MATCH` | `VLOOKUP` |
|---|---|---|---|
| works in Excel 2019 and earlier | no | yes | yes |
| returns a column left of the key | yes | yes | no |
| survives an inserted column | yes | yes | no |
| exact match unless told otherwise | yes | no, write the 0 | no, write `FALSE` |
| message for a missing key built in | yes | no, wrap it in `IFNA` | no, wrap it in `IFNA` |

Write `XLOOKUP` when everybody has it, `INDEX` with `MATCH` when somebody might not, and read
`VLOOKUP` when you find it.
