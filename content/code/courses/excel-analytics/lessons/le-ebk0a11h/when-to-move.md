---
title: Signals that the job has outgrown the workbook
version: 1
---

**Moving away from Excel is not a verdict on Excel; it is what happens when a job needs something a
file cannot give.** The question is never "is this spreadsheet too big?" in the abstract. It is
whether the work now needs many writers, a history, rules that hold, or one answer shared by many
readers. Each of those has a symptom you can see from inside the workbook.

## The signals

| what you notice | what it means | what the job needs |
|---|---|---|
| a file nears the edge of a sheet, or every edit makes you wait | size | the data model now; a database once it keeps growing |
| two or more people need to **enter** data in the same file | many writers | a database |
| you need to know who changed a number, when and why, and to undo just that | a history | a database |
| a rule must hold whoever enters the data, paste included | constraints | a database |
| another system needs to read or write the same data | integration | a database |
| the same file goes out by e-mail every week to people who only **read** it | distribution | a BI platform |
| the same KPI is defined in three workbooks and gives three answers | one definition | a BI platform's shared model |
| refreshing and sending the report is somebody's Monday morning | a schedule | a BI platform's scheduled refresh |

The table splits cleanly in two, and the split is the useful part. **Problems with writing point at
a database. Problems with reading point at a BI platform.** Café Serra could have either kind
without the other: a second shop entering sales needs a database long before anyone needs a
published dashboard, and a group of investors reading the monthly numbers needs a published
dashboard while one person still types every sale.

## Moving is not all or nothing

The data moving does not mean Excel goes. The common arrangement is that the records live in a
database and Excel reads them. Power Query connects to a database as lesson 13 described, loads the
rows into the data model, and the pivot tables, measures and dashboard of lessons 15 to 17 work as
before, on data that many people wrote safely. What leaves the workbook is the job of **holding** the
records. The job of **asking questions** of them often stays exactly where it was.

## When the workbook is the right answer

Most analysis never meets any of the signals, and moving it would only add cost. Excel is the right
tool when:

- one person, or a small team taking turns, owns the data and the question;
- the data fits comfortably, and arrives as a file or a query rather than being typed by many people;
- the answer is needed today, and the question may never be asked again;
- the reader is the person who built it, or a few people who can be sent a PDF.

That describes Café Serra as it stands: 108 sales, one owner, one dashboard read once a month. The
course has used Excel for the business because Excel is the right size for it. The signals are for
the day that stops being true, so that the move is a decision made in advance rather than a
scramble after the file has already lost something.
