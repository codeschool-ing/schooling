---
title: Your tools: a spreadsheet and a text editor
version: 1
---

Half of this course is money. A debt priced as interest per sprint, a comparison three years out,
a total cost of ownership, a cost of delay — each is arithmetic with a right answer, and you will
learn it faster by computing it than by reading somebody else's table. The other half is writing:
a one-page strategy in lesson 3 and decision records in lesson 17.

**No machine is provided for this course, and none is needed.** Everything happens on your own
computer, with two ordinary tools and an optional third:

- a spreadsheet, for every number from lesson 5 on;
- a plain-text editor, for the pages you write — anything that saves a plain `.txt` or `.md`
  file: Notepad on Windows, TextEdit in plain-text mode on macOS, gedit or Kate on Linux, or a
  programmer's editor you already use;
- a diagram tool, if you like drawing on a screen. Paper works as well. diagrams.net is free,
  runs in a browser or as a desktop application, and needs no account.

## The spreadsheet: three paths

| path | what it costs your computer | what to watch |
|---|---|---|
| **LibreOffice Calc**, installed — recommended | an installation of a few hundred megabytes; works offline | the function names follow the language the program runs in |
| **LibreOffice Calc in a virtual machine** | the virtual machine's own disk and memory, on top of Calc | worth it only if you already work inside a Linux virtual machine; install Calc there exactly as below |
| **online**: Google Sheets, or Excel for the web | nothing installed; needs an account (Google or Microsoft) and a connection | the function names and the separators follow the spreadsheet's locale |

**LibreOffice Calc is the recommended path.** It is free and open source on Windows, macOS and
Linux, it works with no account and no connection, and it is the spreadsheet that computed every
value this course shows beside a formula: each one is what LibreOffice 24.2 returned. Download it
from libreoffice.org, or use your system's package manager — on Debian or Ubuntu,
`sudo apt install libreoffice-calc` installs Calc alone.

The other paths give the same numbers, and so does an installed Microsoft Excel, which is paid. The
formulas in this course use only functions all of them have: `SUM`, `ROUND`, `INDEX`, `MATCH`,
`MIN`, `LARGE` and `IF`.

## Check it before going on

Type `=1+1` in an empty cell and press Enter. A **2** means the spreadsheet calculates. If the cell
shows the formula itself, the cell is formatted as text; clear its formatting (in LibreOffice,
**Format → Clear Direct Formatting**) and type it again.

## The first sheet: what a meeting costs

Every strategy argument in this course ends up as hours multiplied by a rate, so start there. Coreto
counts an engineer-hour at **R$ 150**, the loaded cost: salary, taxes, benefits and equipment
divided by the hours actually worked. Type this header and one row:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | People | Hours | Rate | Cost |
| 2 | 8 | 1 | 150 | |

In D2, the cost of one meeting of eight engineers for an hour:

```localised
=A2*B2*C2      1200
```

And in an empty cell, the same meeting held every week — four a month, twelve months:

```localised
=D2*4*12      57600
```

**A weekly one-hour meeting of eight engineers costs Coreto R$ 57,600 a year.** Nobody approves
that number, because nobody ever sees it written down; it is spent one hour at a time. A good part of
this course is the habit of writing such numbers down before deciding, and the spreadsheet is
where they get written.

Save the file somewhere you will find it again. Each lesson that computes adds a sheet to it. The
next section is what to do when a formula answers with an error instead of a number.
