---
title: A spreadsheet first, and when it stops being enough
version: 1
---

Most teams that own a case tool started with a spreadsheet, and that is not a mistake to be
ashamed of. **A spreadsheet is a case tool with one table: one row per case, one column per run.**
It costs nothing, anybody can open it, and for one tester and one product it does everything
section 01 of this lesson asked of a tool. This section gives you boxoffice's cases in that form,
reads it the way a tool would, and then lists the signs that a team has outgrown it.

## Boxoffice's cases, as a file

The file below is seventeen cases for boxoffice, the ones this course has run so far, with the
results of two runs: one on release 1.0 and one on 1.1. It is CSV, comma-separated values, the
plain-text form every spreadsheet program opens and saves. Create a new file in your `boxoffice`
directory, paste the block into it with the copy button and save it. Save it as `cases.csv`,
exactly that name, because lesson 19 reads it:

```
id,requirement,title,steps,expected,1.0,1.1
TC-01,R1,Shows are listed,Open the home page,"Three shows, each with date and time, price and seats left",passed,passed
TC-02,R2,Sign up,"Sign up as Teste Um, teste1@example.org, password abcd1234","Account created, and an e-mail in the outbox",passed,passed
TC-03,R2,E-mail already used,"Sign up as Bia, member@example.org, password abcd1234",There is already an account with that e-mail.,passed,passed
TC-04,R4,Book one ticket,"As member@example.org, book 1 ticket for Hamlet",Order 1001 reserved.,passed,passed
TC-05,R4,Book six tickets,"As member@example.org, book 6 tickets for Hamlet",Order 1001 reserved.,failed: You can book 1 to 6 tickets.,passed
TC-06,R4,Seven tickets refused,"As member@example.org, book 7 tickets for Hamlet",You can book 1 to 6 tickets.,passed,passed
TC-07,R4,Seats go down,"As member@example.org, book 1 ticket for Hamlet, open the home page",Hamlet has 79 seats left,passed,passed
TC-08,R5,Member discount,"As member@example.org, book 2 tickets for Hamlet","10% off, R$ 144,00",passed,passed
TC-09,R5,Largest discount only,"As member@example.org, book 5 tickets for Hamlet","15% off, R$ 340,00","failed: 25% off, R$ 300,00",passed
TC-10,R5,Student pays half,"As member@example.org, tick Student, book 2 tickets for Hamlet","50% off, R$ 80,00",passed,"failed: 10% off, R$ 144,00"
TC-11,R7,Quantity in words,"As member@example.org, book Hamlet typing the word two as tickets",A sentence saying what is wrong,"failed: error 500, a traceback","failed: error 500, a traceback"
TC-12,R6,Pay an order,"Book 1 ticket for Hamlet, press Pay",State: paid,passed,passed
TC-13,R6,No refund after use,"Book 1 ticket for Hamlet, press Pay, Use, Refund","Refused, and the state stays used",failed: refunded,failed: refunded
TC-14,R6,Message for a refused move,"Book 1 ticket for Hamlet, press Use",An order that is reserved cannot be used.,,failed: says cannot be useed
TC-15,R6,No refund once started,"Book and pay for The Seagull before 19:00, press Refund after 20:00","Refused, and the state stays paid",,failed: refunded
TC-16,R8,Shows on a phone,Open the home page in a window 360 pixels wide,Nothing scrolls sideways,failed: scrolls sideways,failed: scrolls sideways
TC-17,R9,Every field labelled,"Open the Book page, check the label of each field",Every field has a label,,failed: Tickets has no label
```

Open it in LibreOffice Calc, Google Sheets or Excel to see it as a table. One trap: Excel set up
for Portuguese expects a semicolon between columns, and opens this file with everything in column
A. Import it instead, from **Data**, **From Text/CSV**, and choose the comma as the delimiter.

Every case starts from a fresh boxoffice, stopped and started again, which is why two of them can
both expect order 1001. The first five columns are the case. The last two are runs, and each cell
holds one of three things: `passed`; `failed:` followed by what happened instead; or nothing,
which means the case was not run on that release.

## Reading it the way a tool would

**Down a run column, it is a run.** The 1.1 column has ten passes and seven failures, and every
failure names what was seen. Lesson 19 turns that column into a report.

**Across a row, it is the history of one case.** TC-05 failed on 1.0 and passed on 1.1: that is
the fix lesson 9 made to the six-ticket limit. TC-10 passed on 1.0 and failed on 1.1: that is the
regression lesson 10 found, the student discount that 1.1 broke. Neither fact is visible in a
single run.

**The empty cells are history too.** TC-14, TC-15 and TC-17 have no result on 1.0 because they did
not exist yet: they were written after lessons 11 and 14 found the defects they check, on 1.1. A
case written from a defect is the usual way a suite grows, and the empty cell records honestly
that 1.0 was never asked.

**A filter on the requirement column is traceability.** Filter for R5 and you get the three
discount cases and their results; filter for R3 and you get nothing, which tells you that the
confirmation link has no case in this file at all. A gap you can see is the most useful thing a
coverage view ever shows.

## The signs that a team has outgrown it

None of these is a reason to buy a tool on the first day. Each is a reason when it starts costing
time every week.

**The columns multiply.** Two releases are two columns. Four browsers on each, as lesson 7 asks,
are eight, and the third release makes twelve. A tool keeps runs as objects and draws the columns
only when you ask for them.

**Two people edit at once.** A spreadsheet on a shared drive either locks or merges, and a
results file that two testers saved over each other loses one of them in silence.

**The cell holds two things.** `failed: refunded` is a status and a piece of evidence in one
string. Nothing stops somebody typing `Failed` or `fail`, and then a count of failures is wrong
by however many spellings there are. Nor is `refunded` a link to the defect report lesson 15 would
write; a tool stores the status as one of a fixed list and the defect as a link.

**The case changes and the history does not say so.** If TC-13's steps are rewritten next month,
the 1.0 result beside it now describes steps that were never run on 1.0. A spreadsheet keeps the
latest text; a tool keeps the version of the case each result was recorded against.

**Somebody asks who and when.** An auditor asking who marked TC-12 passed on 1.1, and on what day,
gets no answer from a cell.

**A useful rule of thumb: when the spreadsheet needs written rules about how to edit it, those
rules are the features of a case tool**, and the team is maintaining them by hand. Until then, a
file like this one, kept with the project and read by everybody, is a perfectly good place to
start, and the day the team moves to one of the four tools in this lesson, this file is what it
imports.
