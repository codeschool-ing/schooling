---
title: When the spreadsheet disagrees with you
version: 1
---

Most of the trouble a money spreadsheet gives comes from four mistakes, and each shows a different
symptom. The values below are what LibreOffice Calc returned when each mistake was made on purpose
in a small sheet: a column of interest hours, a column of rates, and their product.

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Debt | Interest | Rate | Cost |
| 2 | Seat-hold | 31 | 150 | `=B2*C2` |
| 3 | PDF tickets | 6 | R$ 150 | `=B3*C3` |
| 4 | Switching | 210000 | 10 | `=B4*C4` |

Row 2 is right, and D2 shows **4650**. Rows 3 and 4 each carry a mistake.

## A number that is really text

C3 was pasted from a document as `R$ 150`. To the spreadsheet that is text that happens to contain
digits, and arithmetic on text fails:

```localised
=B3*C3      #VALUE!
```

**The error spreads.** A total over a column containing one `#VALUE!` is itself an error, so one
pasted cell takes down every summary built on it:

```localised
=SUM(D2:D3)      #VALUE!
```

The giveaway, before any formula runs, is alignment: numbers sit on the right of their cell and
text sits on the left. Type money as a bare number — `150` — and let the cell's format add the
currency sign if you want one (in LibreOffice, **Format → Cells → Currency**).

## A function the spreadsheet does not know

A spreadsheet answers `#NAME?` when it does not recognise a function name. The usual cause is a
formula copied from somewhere written for a spreadsheet in another language:

```localised
=SOMA(D2:D2)      #NAME?
```

`SOMA` is the Portuguese name of `SUM`, typed into a LibreOffice running in English. Excel and the
installed LibreOffice use the names of their own language. Google Sheets has a setting to always
use English function names. Every formula in this course is shown in both spellings: the English
in the English lesson, the Portuguese in the Portuguese one.

## A separator that is not a separator

In a spreadsheet set to Portuguese, the decimal mark is a comma. Type a Portuguese decimal into an
English spreadsheet and it is not read as a number at all:

```localised
=B4*0,10      Err:509
```

`Err:509` is LibreOffice's code for a missing operator: it read `0` and then a comma it did not
expect. Other spreadsheets name the error their own way, or, worse, read the number as something
else. In English the formula is `=B4*0.10`; in Portuguese it is `=B4*0,10`, and the separator
between a function's arguments changes with it, from a comma to a semicolon.

## An answer that is quietly wrong

The last mistake produces no error at all. Row 4 multiplies a switching cost of R$ 210,000 by a
probability. The probability is ten percent, and C4 holds `10`:

```localised
=B4*C4      2100000
```

That is a hundred times too large: **R$ 2.1 million where the answer is R$ 21,000.** Nothing on the
screen says so, and a number that size, once it reaches a slide, decides things. Written as a
percentage, the same product is right:

```localised
=B4*10%      21000
```

The only defence is the one this course uses for every number: **check one row by hand** before
trusting the column. If a probability, a share or a growth rate is involved, check that the cell
holds `0.1` or `10%` and not `10`. Lesson 10 uses exactly this product, and its whole argument
depends on the size of the answer.
