---
title: IFERROR, and the errors it should not hide
version: 1
---

**`IFERROR` replaces any error with a value you choose, and "any" is both its use and its danger.**
An error in a cell is Excel telling you that something it was asked to do could not be done. Some
of those are expected and harmless; most are a symptom of something wrong in the data or the
formula. `IFERROR` cannot tell the two apart, so the person who writes it has to.

## The errors

| error | what Excel could not do | an example on this data |
|---|---|---|
| `#DIV/0!` | divide by zero, or by an empty cell | `=H3/L3` in lesson 2 section 03 |
| `#VALUE!` | use a value of the wrong kind | a price times the text `Wholesale` |
| `#N/A` | find something it was asked to look up | a product code that is not in `Products`, lesson 4 |
| `#REF!` | reach a cell that was deleted | lesson 2 section 06 |
| `#NAME?` | recognise a name in the formula | a function name typed wrong |

Every one of them spreads: a formula that uses a cell holding an error gives an error too. That is
deliberate. A total over a column with one `#VALUE!` in it shows `#VALUE!`, not a total that is
quietly short.

## An error you expect

Revenue divided by bags gives the price back, so a column of `=H2/E2` is a cheap check that column
H is intact: on every row it should equal `Price`. In J2:

```localised
=H2/E2
```

J2 shows **104**, the price of S1001. Now suppose the column is filled one row further, to J110,
ready for the next sale. Row 110 is empty, and J110 shows `#DIV/0!`. That error is expected and
means nothing: there is no sale there yet. This hides it:

```localised
=IFERROR(H110/E110,"")
```

and J110 shows nothing.

## The error you did not expect

The next sale is typed into row 110, and somebody writes `5 bags` in `Bags`. That is text, and
`=H110/E110` would show `#VALUE!`, a signal that the row needs fixing. Under `IFERROR`, J110 shows
nothing, exactly as it did when the row was empty. The sale is in the sheet and invisible to every
check.

The same blindness turns a typo into a silent zero. Type `E2O`, with the letter O, where you meant
`E2`:

```localised
=IFERROR(H2/E2O,0)
```

`E2O` is not a cell, so Excel looks for a name `E2O`, does not find one, and the inner formula is
`#NAME?`. `IFERROR` turns that into 0 on every row of the column. Every check computed from it is
now zero, and nothing in the sheet says why.

## Test for what you expect

The repair is to ask the question you meant, rather than catching everything. The expected case
was an empty row, so test for an empty row:

```localised
=IF(E110="","",H110/E110)
```

An empty row shows nothing, as before. A row with `5 bags` shows `#VALUE!`, because nothing caught
it. The formula is longer by a few characters, and every unexpected error still reaches your eyes.

When the expected error is a failed lookup, `IFNA` is the narrow version: it replaces `#N/A` and
lets every other error through. `=IFNA(H110/E110,"")` still shows `#DIV/0!` on the empty row,
because a division by zero is not a missing value. Lesson 4 uses `IFNA` where it belongs, around
lookups.

A rule of thumb that covers most cases: **catch the error you can name, and show it as something
visible.** `"not found"` in a cell is information; `0` in a total is a wrong number.
