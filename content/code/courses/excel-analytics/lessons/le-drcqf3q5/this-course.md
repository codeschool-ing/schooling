---
title: What this course does, and where its numbers come from
version: 1
---

**Most companies already own the tool this course teaches, and most of them use a tenth of it.**
Excel is where sales are totalled, budgets argued over and reports pasted together every Monday.
The same program can import a file and clean it the same way every month, join three tables
without a single lookup formula, and answer "how did this quarter compare with the same quarter
last year" from a pivot table that refreshes itself. This course goes from the first to the second.

It climbs in five steps, and each one rests on the one before:

| lessons | what you learn to do |
|---|---|
| **1 to 6** | lay data out so it can be analysed, and write the formulas analysis is made of: references, logic, lookups, conditional totals, cleaning text and dates |
| **7 to 9** | give the data structure: tables that grow, entry that is checked, formatting that says something |
| **10 to 12** | summarise it: pivot tables, slicers, charts |
| **13 and 14** | import and shape it with **Power Query**, so that the cleaning is a recipe rather than an afternoon |
| **15 to 18** | model it with **Power Pivot** and **DAX**, build a dashboard on the model, and know when the job has outgrown Excel |

## One business, all the way through

Every lesson works on the same data: eighteen months of sales of **Café Serra**, a coffee roaster
that does not exist, which you paste into a workbook in section 05 of this lesson. Using one
business means a number found in lesson 5 can be checked against a pivot table in lesson 10 and a
DAX measure in lesson 16, and the three had better agree. When they do not, something in the
analysis is wrong, and finding which is part of the course.

## How formulas are written here

Excel translates its function names into the language it is set to, and in some languages it also
changes the comma between arguments into a semicolon. This course prints formulas the way an Excel
set to **English** spells them:

```localised
=SUMIFS(E2:E109, G2:G109, "Online")
```

If your Excel is in another language, the function has another name and the same arguments, and
Microsoft's support pages list each function under both names. The Portuguese version of this
course prints every formula in the Portuguese spelling.

Cell addresses, sheet names and the text inside quotes never change with the language. The column
headers of the data are in English in every version of the course, because they are data, and data
does not change when its reader does.

## Where the numbers come from

**This course was written on a computer that has no Excel**, and it says so rather than pretending
otherwise. Every number it quotes was nevertheless computed, never typed:

- the results of formulas, in lessons 1 to 12, by a spreadsheet program, LibreOffice Calc, with
  each formula entered exactly as the lesson prints it, in a workbook holding the data you paste.
  Calc implements these functions under the same names and arguments as Excel. XLOOKUP, which the
  version used does not have, was computed by a separate Excel-compatible calculator;
- the pivot tables, by Calc's own pivot table, and checked against the formulas of lesson 5;
- the results of Power Query steps and DAX measures, in lessons 13 to 16, by a script that applies
  the same steps to the same data, because neither has an engine outside Excel. Those lessons say
  so where it happens.

What could not be produced honestly is a picture of Excel's own screens, so there are none. The
figures draw the idea instead: the shape of a table, the path of a lookup, the steps of a query.
The menus are named in words, with the path to each command, and where Microsoft has moved a
command between versions the lesson says where to look.

## The questions

Each lesson ends with questions, and many ask for the number a formula returns on your data. They
carry no mark. A wrong answer shows you why it was wrong, and that is the most useful thing a
question has to give, so read the explanation even when you were right.
