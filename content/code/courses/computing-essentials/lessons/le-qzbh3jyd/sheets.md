---
title: Sheets, and the four functions that exist nowhere else
version: 1
---

The model is Excel's and so are the traps. A cell holds a value, a formula computes one, a type
is decided as you type, and leading zeros still vanish — the apostrophe fix from the last lesson
works here unchanged.

What is different is that **the sheet is on a network**, and four functions exist because of it.

## The four

| | what it does |
|---|---|
| `IMPORTRANGE` | pulls a range out of **another spreadsheet**, live |
| `QUERY` | runs a small database query over a range — select, where, group by |
| `IMPORTHTML`, `IMPORTXML` | pull a table out of a **web page**, and keep it current |
| `GOOGLEFINANCE` | a share price or an exchange rate, as a value |

**`IMPORTRANGE` is the one that changes how people work.** One sheet holds the data and six
sheets read from it, so there is one copy rather than six that drifted apart. It asks permission
once, from the target sheet, and then it is live.

**`QUERY` is the one worth learning properly.** `=QUERY(A:D, "select B, sum(D) where C = 'SP'
group by B")` replaces a pivot table, a filter and three helper columns with one cell, and it
updates itself.

And `ARRAYFORMULA` deserves a line of its own: it applies a formula down a whole column at once,
so there is one formula at the top instead of nine hundred copies. A column that grows keeps
working, which is the same problem Excel's tables solve by a different route.

## Where Sheets is worse, and by how much

| | |
|---|---|
| **size** | 10 million cells against Excel's million rows *per sheet*. Sheets slows down long before its limit |
| **speed on large data** | noticeably worse, because the work is on a server |
| **statistical depth** | Excel has more, and the Analysis ToolPak has more again |
| **macros** | Apps Script is JavaScript and is genuinely good; it is not VBA and will not run VBA |
| **offline** | arranged in advance, and slower |

**The honest boundary is somewhere around fifty thousand rows with formulas in them.** Below
that, Sheets is pleasant and the collaboration is worth more than the speed. Above it, the
browser starts to feel it and Excel is the right tool.

## The locale trap, which is the Brazilian one

A spreadsheet has a **locale**, set in *File, Settings*, and it decides the decimal separator, the
thousands separator and the date order. It is set from where the account is, not from where the
data came from.

So a CSV exported from a Brazilian system, with `1.234,56` in it, opened in a sheet set to the
United States, produces either text or a number a thousand times too large — and a date column
written `03/04` lands on the wrong month without any warning.

**Set the locale before importing anything**, and check one row of the result against the source.
It is thirty seconds and it is the difference between a number and a story about a number.

## And one habit that pays

`Ctrl+Alt+M` leaves a comment on a cell. A sheet somebody else has to use is a sheet with notes
on the three cells that are not obvious — the rate, the assumption, the column that must not be
sorted. That is documentation that travels with the thing it documents, which is the only kind
that gets read.
