---
title: When the key is not found, or is found empty
version: 1
---

**A lookup can fail loudly, with `#N/A`, or quietly, with a value that is not there.** The loud
failure is the useful one: it marks the row. This section is about keeping it loud, finding out
why it happened, and the quiet failure that lesson 1 promised, the customer with no city.

## `#N/A`: nothing matched

Every lookup in this lesson answers `#N/A` when the key is not in the searched column. There is no
`CER2K`, so:

```localised
=VLOOKUP("CER2K",Products!$A$2:$G$7,6,FALSE)
```

shows `#N/A`. In a column of lookups, an `#N/A` means one of two things: the key is genuinely
missing from the other table, a product sold that was never added to `Products`, or the two keys
look the same and are not. The first is a fact to fix in the data. The second is more common.

## Keys that look the same

**A space at the end.** `CER1K ` with a trailing space is six characters, and `CER1K` is five.
They look identical in a cell, and `=XLOOKUP("CER1K ",Products!$A$2:$A$7,Products!$F$2:$F$7)`
answers `#N/A`. `LEN` counts the characters and shows the difference:

```localised
=LEN(D2)
```

answers **5** for the `CER1K` in D2; the same code with a space would answer 6. Spaces arrive with
pasted data more than with typing, and lesson 6 removes them with `TRIM`.

**A number stored as text.** A key column of numbers, such as order numbers `1001`, `1002`, can
arrive from another system as text. The text `1001` never matches the number 1001, as lesson 3
section 02 showed for a comparison, and a lookup is a comparison done for you.

**Not case.** `cer1k` finds `CER1K`: lookups ignore case, like comparisons. A key that differs only
in its capitals is not the reason for an `#N/A`.

## Catching it, narrowly

When a missing key is expected, say what it means, and catch nothing else. `XLOOKUP` has the
fourth argument for it, as section 03 showed. For `VLOOKUP` and `INDEX` with `MATCH`, the narrow
catch is `IFNA`, from lesson 3:

```localised
=IFNA(VLOOKUP(D2,Products!$A$2:$G$7,6,FALSE),"not in Products")
```

On this data every product is in `Products`, so every row shows its list price; a sale of a product
that was not would say `not in Products`, in words. `IFERROR` would say the same thing about a typo
in the formula, and lesson 3 section 05 showed where that leads.

## The quiet failure: a key found, a value empty

Customer `C00`, everybody who buys in the shop or on the web without an account, has no `City`: the
cell is empty, on purpose. Bring the city of each sale into `Sales`. For row 4, sale S1003 by `C00`:

```localised
=XLOOKUP(C4,Customers!$A$2:$A$12,Customers!$D$2:$D$12)
```

It answers **0**. Not an empty cell, not an error: the number zero. A lookup that lands on an empty
cell returns 0, and `VLOOKUP` and `INDEX` do the same. **70** of the 108 sales are by `C00`, so a
column of cities built this way has 70 rows saying `0`, and a count of sales by city would show a
city called 0 at the top of the list.

The usual repair is to join the result to the empty text, which turns an empty cell into empty text
and leaves every real city alone:

```localised
=XLOOKUP(C4,Customers!$A$2:$A$12,Customers!$D$2:$D$12)&""
```

It shows nothing for `C00`, and `São Paulo` for `C04`. The price is that the result is always text,
which is right for a city and wrong for a number: on a numeric column, test for the empty cell with
`IF` instead, and decide what an empty value should mean there. Zero is a claim that a value was
measured and found to be zero, and an empty cell never said that.

## Before lesson 5

None of the lookup columns is needed again: clear everything from column J to the right on `Sales`,
keep `Revenue` in column H, and save. Lesson 5 answers questions about the whole table at once
rather than row by row.
