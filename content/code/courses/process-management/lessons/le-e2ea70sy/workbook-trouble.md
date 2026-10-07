---
title: When the workbook disagrees with you
version: 1
---

Most of the trouble a first spreadsheet gives comes from four mistakes, and each one shows a different symptom. The values below are what LibreOffice Calc returned when each mistake was made on purpose in a copy of the sheet; Excel and Google Sheets use the same error names.

## A date that is really text

A date pasted from another system, or typed with an apostrophe in front, can arrive as **text that looks like a date**. The giveaway is that it sits on the left of its cell, where text goes, while real dates sit on the right like numbers. Arithmetic on it fails:

```localised
=C3-B3+1      #VALUE!
```

Worse, the error spreads. A summary over a column that contains one `#VALUE!` is itself an error:

```localised
=MEDIAN(D2:D4)      #VALUE!
```

The fix is to re-enter the date, or to convert the whole column with the spreadsheet's *Text to Columns* command, and then check that every date in the column sits on the right.

## A function the spreadsheet does not know

A spreadsheet answers `#NAME?` when it does not recognise a function name. The usual cause is a formula copied from a source written for a spreadsheet in another language:

```localised
=PERCENTIL.INC(D2:D4,0.85)      #NAME?
```

That is the Portuguese name, typed into a LibreOffice running in English. Excel and the installed LibreOffice use the names of their own language, so a Portuguese installation expects `PERCENTIL.INC` and an English one `PERCENTILE.INC`. Google Sheets has a setting to always use English function names. The lessons show both spellings.

## A separator that is not a separator

In a spreadsheet set to Portuguese, the decimal mark is a comma, so the separator between a function's arguments is a semicolon: `=PERCENTIL.INC(D2:D21;0,85)`. In English it is a comma: `=PERCENTILE.INC(D2:D21,0.85)`. Typing the English form into a Portuguese spreadsheet produces an error or, worse, a number read wrongly. The semicolon is accepted by LibreOffice in either language, which makes it the safer habit.

## An answer that is quietly wrong

The last mistake produces no error at all. Leave the `+1` off the cycle-time formula and the item that started on 4 March and finished on the 6th shows **2** days instead of 3. Every number computed from the column is then a day short, and nothing on the screen says so. The only defence is the one this course uses for every number: **check one row by hand** before trusting the column, and write down the convention next to the result.
