---
title: What a cell holds, and what it shows
version: 1
---

**A cell holds one value of one type, and what you see is only how it is displayed.** That
distinction decides whether a total is right, and it fails silently: a number stored as text looks
like a number, sits in the column like a number, and is left out of every sum.

Excel keeps four kinds of value in a cell, plus errors:

| kind | example | how Excel shows it unformatted |
|---|---|---|
| **number** | `14`, `104` | against the right edge of the cell |
| **text** | `CER1K`, `Wholesale` | against the left edge |
| **logical** | `TRUE`, `FALSE` | centred |
| **error** | `#N/A`, `#DIV/0!` | centred, and passed on to every formula that uses the cell |

The alignment is a free test. Sales!E2 should sit to the right; if a column of numbers hugs the
left edge, it holds text.

## A date is a number with a format

There is no fifth kind for dates. **Excel stores a date as a count of days, in which 1 January 1900
is day 1**, and the format only decides how that number is drawn. Click Sales!B2, which shows
`2025-01-02`, and change its format to **General** on the Home tab: it becomes **45659**. Change it
back and the date returns. Nothing about the cell changed except the drawing.

That is why `=COUNT(B:B)` answered 108 in the previous section: the dates are numbers, and `COUNT`
counts numbers. It is also why you can subtract one date from another and get a number of days,
and why lesson 6 can take the month out of a date with one function.

## Asking a cell what it holds

Three functions answer the question directly, and each returns `TRUE` or `FALSE`. In an empty cell
of `Sales`, such as J2:

```localised
=ISNUMBER(B2)
=ISNUMBER(D2)
=ISTEXT(D2)
```

The first is `TRUE`, because B2 is a date and so a number. The second is `FALSE` and the third
`TRUE`: `CER1K` is text, as a product code should be. On the `Customers` sheet,

```localised
=COUNTBLANK(D2:D12)
```

answers **1**: the one customer with no city, `C00`.

## The number that is text

Now the failure. Suppose somebody had typed Sale S1001's 14 bags with an apostrophe in front,
`'14`, which is what people do to stop Excel changing a value. The cell still shows 14. But the
apostrophe makes it text, and:

```localised
=COUNT(E:E)
```

drops from 108 to **107**, while `=SUM(E:E)` drops from 591 to **577**, short by exactly the 14
bags nobody can see are missing. Excel marks such a cell with a small green triangle in its corner
and offers **Convert to Number** when you click the warning beside it, but only one cell at a time
is noticed by anybody, and only if somebody looks.

Numbers arrive as text far more often from outside than from typing: a file exported by another
system, a column copied from a web page, codes with a leading zero that somebody protected. Lesson 6
is about bringing them back. For now the habit is enough: **after any paste, count the numbers in a
column that should hold numbers**, and compare with the number of rows.

## Format is not rounding

One more trap of the same family. Format a cell holding `103.5` to show no decimals and it reads
`104`, but a formula that uses it still gets 103.5. The displayed value and the stored value can
differ, and formulas always use the stored one. When a total looks one real off from the column
above it, this is the usual reason, and `ROUND`, which lesson 2 uses, is the way to make the stored
value what you mean.
