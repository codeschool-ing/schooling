---
title: Your lab is Excel on your own computer
version: 1
---

**Nobody learns a spreadsheet by watching one.** Every lesson here asks you to type the formula,
build the pivot table or step through the query yourself, on the data from section 05, and then
compare your number with the one on the page. So before anything else you need an Excel that can
do everything the course does. This section is about getting one, and the next is about what to do
when that goes wrong.

The platform runs no software for you. The lab is your own computer, or a virtual machine on it,
or a browser, and the choice decides how much of the course you can follow.

## What the course needs from Excel

| feature | first used in | needs |
|---|---|---|
| `XLOOKUP` and dynamic arrays | lesson 4 | Excel 2021, Excel 2024 or Microsoft 365 |
| pivot tables, slicers, timelines | lessons 10 and 11 | any recent Excel |
| **Power Query** | lessons 13 and 14 | Excel for Windows; partly on the Mac |
| **Power Pivot and DAX** | lessons 15 and 16 | **Excel for Windows only** |

The last row is the one that decides. Power Pivot exists only in Excel for Windows: not on the Mac,
not in the browser, and not in any free alternative. Lessons 15 and 16 build on it, and lesson 17's
dashboard is built on what they make.

## Three ways to have it

| path | what you get | what it costs you | lessons |
|---|---|---|---|
| **installed** (recommended) | Excel for Windows, from a Microsoft 365 subscription | the subscription, unless a school or employer already gives you one; a few gigabytes of disk | all 18 |
| **a virtual machine** | Windows running inside a Mac or a Linux computer, with Excel for Windows installed in it | a Windows licence as well as the subscription; 64 GB of disk and 4 GB of memory for Windows itself | all 18 |
| **online** | Excel for the web, in a browser | nothing beyond a free Microsoft account | 1 to 12, with gaps |

**Installed is the recommended path** when your computer runs Windows. It is the only one where
every lesson works as written, and it is what most companies run, so what you learn here is what
you will find at work. Many students already have it without knowing: a university or an employer
that uses Microsoft 365 usually includes the desktop apps, and signing in at office.com with that
account shows an **Install apps** button if yours does.

**On a Mac**, Excel for Mac covers lessons 1 to 12 the same way. Power Query has arrived on the Mac
in stages and covers part of lessons 13 and 14; Power Pivot does not exist there. For lessons 15 and
16, the **virtual machine** is the path: Windows 11 in a virtual machine (Parallels Desktop or UTM
on Apple silicon, VirtualBox on an Intel Mac or a Linux computer), with Excel for Windows installed
inside it. It costs a Windows licence and a computer with room for a second operating system:
Microsoft asks for 64 GB of storage and 4 GB of memory for Windows 11, and that memory is taken from
your own system while the machine runs, so 8 GB in the computer is the practical floor.

**Online**, Excel for the web needs nothing installed and no payment: a free Microsoft account opens
it at office.com. It handles the formulas, tables, validation, conditional formatting, pivot tables
and charts of lessons 1 to 12, with some commands missing or in a different place. It cannot create
a Power Pivot model, and its Power Query is far thinner than the desktop's, so it is a way to start
today rather than a way to finish the course. Free tiers change on their owner's terms, and nothing
in this course depends on this one.

Two programs that are not Excel are worth naming, because you may already have them. **LibreOffice
Calc** is free and installed; it covers lessons 2 to 6 and the pivot tables of lesson 10, and has
`XLOOKUP` from version 24.8. **Google Sheets** is free and online, with `XLOOKUP`, pivot tables and
slicers. Neither has Power Query or Power Pivot, and both spell some menus differently, so they are
a way to practise the formula lessons and not a way to follow the course.

## Checking the Excel you have

Three checks, in a new blank workbook, take a minute and save an evening later:

1. **The version.** Go to **File › Account** and look under **Product Information**. Microsoft 365,
   Excel 2021 or Excel 2024 is what you want; **About Excel** on the same page gives the build.
2. **A new function.** Type `=XLOOKUP(1,{1},{1})` in any cell. It should answer `1`. If it answers
   `#NAME?`, this Excel predates `XLOOKUP`, and the next section says what to do.
3. **The data tools.** Open the **Data** tab. You should see **Get Data** at its left end, which is
   Power Query. On Windows, check for a **Power Pivot** tab too; if it is missing, the next section
   turns it on.

When all three pass, go on to section 05 and make the workbook.
