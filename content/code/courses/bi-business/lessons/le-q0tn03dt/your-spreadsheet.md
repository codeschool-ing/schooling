---
title: Your tools: a spreadsheet, and nothing to install besides
version: 1
---

This course is about judgement — which question, which number, which comparison — and judgement about
numbers is learnt by computing a few of them yourself. From lesson 2 on, a lesson that has numbers in
it gives you a small table to type and the formulas to write, with the value each formula should
return beside it. **No machine is provided for the course, and none is needed: everything happens on
your own computer, in a spreadsheet.**

There is no database, no programming language and no BI tool to install. Those come in the courses
after this one in the `bi` track, each with its own setup. Besides the spreadsheet you need a place to
write a few paragraphs — any text editor or word processor you already have — and paper for the odd
sketch, which works better than any drawing program for a first try.

## The spreadsheet: three paths

| path | what it costs your computer | what to watch |
|---|---|---|
| **LibreOffice Calc**, installed — recommended | an installation of a few hundred megabytes; runs offline | function names follow the language the program runs in |
| **LibreOffice Calc in a virtual machine** | the virtual machine's own memory and disk, on top of Calc | worth it only if you already work inside one; install Calc there exactly as below |
| **online**: Google Sheets, or Excel for the web | nothing installed; needs an account (Google or Microsoft) and a connection | function names and separators follow the file's locale setting |

**LibreOffice Calc is the recommended path.** It is free and open source, runs on Windows, macOS and
Linux, and works with no account and no connection. It is also the spreadsheet that computed every
value this course prints beside a formula: each one is what LibreOffice Calc 24.2 returned. Download it
from libreoffice.org, or use your system's package manager; on Debian or Ubuntu,
`sudo apt install libreoffice-calc` installs Calc on its own.

The other paths give the same numbers, and so does an installed copy of Microsoft Excel, which is
paid. The formulas in this course use only functions all of them have — `SUM`, `AVERAGE`, `MEDIAN`,
`ROUND`, `MIN`, `MAX` and `IF` — and arithmetic. If you have done `computing-essentials` lesson 12,
you have already used most of them.

## Check it before going on

Type `=1+1` in an empty cell and press Enter. A **2** means the spreadsheet calculates. If the cell
shows the formula itself, the cell is formatted as text: clear its formatting (in LibreOffice,
**Format → Clear Direct Formatting**) and type it again.

## The first sheet: who sells what

Varanda's sales for 2025, in thousands of reais, by store and for the online shop. Type the two
columns into a new sheet, starting in A1:

| | A | B |
|---|---|---|
| 1 | Store | Sales |
| 2 | Savassi | 11880 |
| 3 | Pampulha | 10560 |
| 4 | Contagem | 12480 |
| 5 | Betim | 8840 |
| 6 | Nova Lima | 9450 |
| 7 | Sete Lagoas | 6720 |
| 8 | Divinópolis | 6460 |
| 9 | Ipatinga | 7040 |
| 10 | Juiz de Fora | 8960 |
| 11 | Online | 15610 |

Type the numbers bare, with no thousands separator and no currency sign; the next section says why.
In A12 type `Total` and in B12 the sum of the column:

```localised
=SUM(B2:B11)      98000
```

**R$ 98.0 million**, the year's sales. Now each line's share of it, as a percentage rounded to one
decimal. In C1 type `Share`, and in C2:

```localised
=ROUND(B2/B$12*100,1)      12.1
```

Copy C2 down to C11. The `$` before the 12 keeps the formula pointing at the total as it moves down;
without it, C3 would divide by B13, which is empty. Your column should show **12.7** for Contagem and
**15.9** for the online shop: the online shop sells more than any single store.

Add the shares up as a check:

```localised
=SUM(C2:C11)      99.9
```

Not 100, because each share was rounded on its own, and the ten roundings did not cancel out. That
is not a mistake, and a report that shows rounded shares adding to 99.9 is honest; one where somebody
nudged a share to make the column say 100 is not. Save the file somewhere you will find it again —
each lesson that computes adds a sheet to it.
