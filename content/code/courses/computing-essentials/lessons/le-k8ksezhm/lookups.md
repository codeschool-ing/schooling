---
title: Lookups, which is how two tables become one answer
version: 1
---

The single most useful thing a spreadsheet does: **take a value from one table and find the row
it belongs to in another.** A product code and a price list. An employee number and a department.
An order and a customer.

## `XLOOKUP`, and why it replaced the other two

```
=XLOOKUP(what to find, where to look, what to bring back, what if not found)
```

Four arguments in the order a person would say them. It looks left as happily as right, it does
not break when somebody inserts a column, and the fourth argument is what turns a `#N/A` into a
sentence.

`VLOOKUP` did the same job with a **column number** — `=VLOOKUP(A2, D:H, 3, FALSE)` — and that
`3` is the whole problem: it counts columns from the left of the range, so inserting a column
anywhere in `D:H` silently changes which column comes back. The formula still works. It returns
the wrong thing.

If `XLOOKUP` is not available — an older Excel, some compatibility modes — the robust
alternative is `INDEX` and `MATCH` together:

```
=INDEX(the column to bring back, MATCH(what to find, the column to search, 0))
```

More typing, same immunity to inserted columns, and available everywhere.

## The argument that ruins more work than any other

**Exact match or approximate match.**

`VLOOKUP`'s fourth argument defaults to *approximate*, which assumes the lookup column is sorted
and returns **the nearest value below** what you asked for. On an unsorted list of product codes
that is a random row, returned confidently, with no error.

- **Exact** is what you want for codes, names, identifiers — anything where *close* is meaningless.
  `FALSE` or `0` in `VLOOKUP`, and the default in `XLOOKUP`.
- **Approximate** is what you want for bands: a tax table, a postage table, a grade boundary.
  Sorted ascending, and it is genuinely the right tool.

**Writing `FALSE` every time is the habit**, and `XLOOKUP` making it the default is the reason to
switch.

## What `#N/A` is telling you

It means *this value is not in that list*, which is almost always a real finding:

- **a trailing space** — `"SP "` and `"SP"` are different strings. `TRIM` fixes the column;
- **a number stored as text** — the lesson-nine problem, with the alignment giveaway;
- **a genuinely missing row**, which is the most important case and the one `IFERROR` hides.

So: **count them.** `=COUNTIF(the results, "#N/A")` beside the table, or a filter on the column.
Three unmatched rows out of nine hundred is a note in the `notes` sheet; three hundred is a
different data problem entirely, and the total is meaningless until it is understood.
