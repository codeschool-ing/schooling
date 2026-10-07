---
title: Setting up your workbook
version: 1
---

From this lesson on, the course computes things — a cycle time, an estimate, a velocity range, the value of a risk — and you should compute them too, on your own computer. You need two things: **a board** and **a spreadsheet**. Nothing in this course is hosted for you, and nothing needs to be.

## The board

Any surface with columns will do. Sticky notes on a wall or a sheet of A3 paper work as well as a tool, and for learning they work better, because moving a paper card is a decision you notice. If you prefer software, a free tier of any board tool is enough. What matters is that you can draw columns, write a limit on each and move cards between them.

## The spreadsheet: three paths

| path | what it costs your computer | what to watch |
|---|---|---|
| **LibreOffice Calc**, installed — recommended | an installation of a few hundred megabytes; works offline | the function names follow the language the program runs in |
| **Google Sheets**, in a browser | nothing installed; needs a Google account and a connection | the function names and the separator follow the spreadsheet's locale |
| **Microsoft Excel**, installed or in the browser | the installed version is paid; Excel for the web is free with a Microsoft account | the function names follow the language of the installation |

**LibreOffice Calc is the recommended path**, for three reasons. It is free and open source on Windows, macOS and Linux. It works with no account and no connection. And it is the spreadsheet that computed every value this course quotes: the file `workbook.py` beside the course lays the data out, asks LibreOffice 24.2 to recalculate it, and prints what each formula returned.

To install it, download it from libreoffice.org, or use your system's package manager — on Debian or Ubuntu, `sudo apt install libreoffice-calc` installs Calc alone. Either of the other two paths gives the same numbers; the formulas in this course use only functions all three have.

## The first sheet

Open a new spreadsheet and type the header row: **Item**, **Started**, **Finished**, **Days**. Under it, one row per finished item, with dates written as year-month-day — `2026-03-02` — which every spreadsheet in every language reads as a date. In the Days column, the cycle time of the first item is:

```localised
=C2-B2+1
```

The `+1` is a convention, and it matters: the Agenda team counts both the day an item started and the day it finished, so an item started and finished on the same day took one day, not zero. Whatever convention you choose, use one for every item and say which one when you quote a number.

Copy the formula down the column and the spreadsheet adjusts the row numbers by itself. The next section is what to do when it does not work.
