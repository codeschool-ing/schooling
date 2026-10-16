---
title: What Power Query is, and why not just open the file
version: 1
---

**Power Query fetches data, changes it, and writes down every change as a step, so that next
month the whole list runs again on the new file with one click.** That is the entire idea, and
everything in lessons 13 and 14 is a detail of it.

## The habit it replaces

Most people meet a CSV file by double-clicking it. Excel opens it, and then the work starts: the
prices came in as text, the dates are in the wrong order, there is a cancelled order to delete
and a column nobody needs. Somebody fixes it by hand, copies the rows under last month's, and
saves. Next month the file arrives again and the same afternoon is spent again, by memory, with a
different mistake each time.

Power Query turns that afternoon into a recipe. You open the file through it once, make the same
fixes with its commands, and each fix is recorded in a list called **Applied Steps**. When the
next file arrives, **Data › Refresh All** fetches it and replays the list. The fixes are no longer
somebody's memory; they are written down, in order, and they run the same way every time.

## Where it lives

Everything starts on the **Data** tab, in the group **Get & Transform Data**, under **Get Data**.
That menu lists the places Power Query can read: files, folders, other workbooks, databases, web
pages. This lesson takes them in that order.

Choosing a source opens the **Power Query Editor**, a window of its own with four parts worth
knowing by name:

| part | what it shows |
|---|---|
| the preview | the first rows of the data as it stands after the selected step |
| **Applied Steps** | on the right, under **Query Settings**: the list of everything done so far, oldest at the top |
| the formula bar | the selected step written in **M**, Power Query's own language |
| the ribbon | the commands, which add a step each time you use one |

Click any step in the list and the preview goes back to that moment. Nothing is lost by looking:
the later steps are still there, and clicking the last one returns you to the end.

## Three things it is not

**It is not a formula.** A cell formula recalculates whenever a cell it reads changes. A query
runs when you ask it to, with **Refresh**, and between refreshes its result sits still. Section 08
of this lesson is about when and how it refreshes.

**It is not a macro.** No code runs in your workbook and nothing is recorded as clicks on the
screen. Each step says what to do to the data, such as "keep the rows whose status is paid", and
Excel works out how.

**It does not change the source.** Power Query reads the file and never writes to it. The CSV in
your folder after a hundred refreshes is byte for byte the one you saved, and the result lives
somewhere else: in a table on a sheet, or in a query that feeds another.

## How this lesson's numbers were made

**Nothing in lessons 13 and 14 was run in Excel.** The computer this course was written on has no
Excel, as lesson 1 section 02 says, and Power Query has no engine outside it. The files you will
create are printed in the lesson, and every number a step produces here was computed by a script
that applies the same steps to the same files. The menus and dialogs are named from Microsoft's
documentation. Where the code Excel writes for you may differ from the code printed here in a
detail, such as the path of a file or the order of two options, the lesson says so.

That has one consequence for you: when your number differs from the page, check your file first.
A missing line or an extra space in a file you typed is the commonest reason, and the files are
small enough to compare by eye.

## Windows and the Mac

Excel for Windows has every connector in this lesson. Excel for Mac has gained Power Query in
stages and reads text files, CSV files and workbooks, but some of the others are missing from its
**Get Data** menu. If one this lesson uses is not there, the Windows path from lesson 1 section 02
is the way to follow it.
