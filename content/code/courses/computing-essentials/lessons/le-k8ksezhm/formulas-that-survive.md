---
title: Formulas that survive a row being inserted
version: 1
---

A formula written today is read in eighteen months by somebody who does not remember what it was
for — often you. Three habits decide whether that reading goes well.

## Name the things

A **named range** gives a cell or a range a word. `=B2*VAT` instead of `=B2*$C$1`, and the name
travels: it means the same thing on every sheet and it does not move when a row is inserted above
it.

Define them in *Formulas, Name Manager* or the name box to the left of the formula bar. Three
minutes at the start of a sheet, and every formula afterwards reads as a sentence.

**A table, from lesson nine, does this for columns automatically** — `=SUM(Sales[Amount])`. Use
both: the table for the data, names for the assumptions.

## Keep the nesting shallow

`IF` inside `IF` inside `IF` is where spreadsheets go to die. Three levels is where a person stops
being able to read it, and five is where nobody can change it safely.

The replacements are all short:

| instead of | use |
|---|---|
| nested `IF` on ranges of a number | `IFS`, or a lookup table with an approximate match |
| nested `IF` on an exact list of values | `SWITCH`, or `XLOOKUP` against a small table |
| the same subexpression three times | `LET`, which names it once |
| a long formula nobody can read | two columns, with the middle step visible |

**That last row is the one to reach for first.** A helper column is not a failure; it is the
working shown. A column you can look at is a column somebody can check, and it can be hidden once
the sheet is finished.

## Handle errors honestly

`#N/A`, `#VALUE!`, `#REF!` and `#DIV/0!` are not noise. Each one names a different fault:

| | means |
|---|---|
| `#N/A` | a lookup found nothing. Usually a real fact about the data |
| `#VALUE!` | arithmetic on something that is not a number. Often the text-in-a-column problem |
| `#REF!` | a reference to a cell that no longer exists. Something was deleted |
| `#DIV/0!` | a division by an empty or zero cell |
| `#NAME?` | a function or a name the program does not know. Often a typo, sometimes a foreign function |

**Wrapping everything in `IFERROR` is the commonest way to hide a real problem.** `IFERROR(x, 0)`
turns *I could not find this customer* into *this customer bought nothing*, and the total is wrong
by exactly as much as the lookup failed.

Use `IFNA` rather than `IFERROR` when you only mean the lookup case, and give it a visible value
— `IFNA(x, "not found")` — rather than a zero that disappears into a sum.

## And the one that is always worth writing

**`=ROUND(x, 2)` at the point where a person reads a number**, and never inside the chain. The
floating-point remark from lesson nine is why: a total of rounded values and a rounded total are
different numbers, and the one a person can check by hand is the second.
