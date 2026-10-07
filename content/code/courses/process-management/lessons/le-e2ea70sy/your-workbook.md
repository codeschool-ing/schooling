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
| **LibreOffice Calc in a virtual machine** | the virtual machine's own disk and memory, on top of Calc | worth it only if you already work inside a Linux virtual machine; install Calc there exactly as below |
| **online**: Google Sheets, or Excel for the web | nothing installed; needs an account (Google or Microsoft) and a connection | the function names and the separator follow the spreadsheet's locale |

**LibreOffice Calc is the recommended path**, for three reasons. It is free and open source on Windows, macOS and Linux. It works with no account and no connection. And it is the spreadsheet that computed every value this course quotes: each value shown beside a formula is what LibreOffice 24.2 returned for it.

To install it, download it from libreoffice.org, or use your system's package manager — on Debian or Ubuntu, `sudo apt install libreoffice-calc` installs Calc alone. The other paths give the same numbers, and so does an installed Microsoft Excel, which is paid; the formulas in this course use only functions all of them have.

## When the installation fails

If the installer will not run — no administrator rights on a work computer, an operating system older than the current LibreOffice supports, or no room on the disk — do not fight it. Take the online path, which needs only a browser, and come back to the installed one later; the numbers are the same.

On Debian or Ubuntu, if `apt` answers that it cannot find the package, its list of packages is out of date. `sudo apt update` refreshes the list, and the install command then works.

Whichever path you end up on, check it before going on: type `=1+1` in an empty cell and press Enter. A **2** means the spreadsheet calculates. If the cell shows the formula itself, it is formatted as text; clear its formatting (in LibreOffice, **Format → Clear Direct Formatting**) and type it again.

## The first sheet

Open a new spreadsheet and type the header row: **Item**, **Started**, **Finished**, **Days**. Under it, one row per finished item, with dates written as year-month-day — `2026-03-02` — which every spreadsheet in every language reads as a date. These are the twenty items the Agenda team finished in March 2026, and the rest of this lesson computes from them:

| Item | Started | Finished |
|---|---|---|
| AG-101 | 2026-03-02 | 2026-03-03 |
| AG-104 | 2026-02-26 | 2026-03-04 |
| AG-097 | 2026-02-27 | 2026-03-05 |
| AG-108 | 2026-03-04 | 2026-03-06 |
| AG-110 | 2026-03-07 | 2026-03-09 |
| AG-095 | 2026-02-21 | 2026-03-10 |
| AG-112 | 2026-03-09 | 2026-03-11 |
| AG-106 | 2026-03-03 | 2026-03-12 |
| AG-099 | 2026-02-22 | 2026-03-12 |
| AG-109 | 2026-03-05 | 2026-03-13 |
| AG-115 | 2026-03-13 | 2026-03-17 |
| AG-113 | 2026-03-12 | 2026-03-18 |
| AG-102 | 2026-03-05 | 2026-03-19 |
| AG-117 | 2026-03-16 | 2026-03-20 |
| AG-111 | 2026-03-10 | 2026-03-20 |
| AG-119 | 2026-03-19 | 2026-03-23 |
| AG-114 | 2026-03-18 | 2026-03-24 |
| AG-118 | 2026-03-20 | 2026-03-25 |
| AG-116 | 2026-03-17 | 2026-03-26 |
| AG-120 | 2026-03-25 | 2026-03-27 |

 In the Days column, the cycle time of the first item is:

```localised
=C2-B2+1
```

The `+1` is a convention, and it matters: the Agenda team counts both the day an item started and the day it finished, so an item started and finished on the same day took one day, not zero. Whatever convention you choose, use one for every item and say which one when you quote a number.

Copy the formula down the column and the spreadsheet adjusts the row numbers by itself. The next section is what to do when it does not work.
