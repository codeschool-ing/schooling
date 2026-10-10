---
title: The anatomy of a defect report
version: 1
---

A defect report is often written as a message to a colleague: *"booking is broken when you type
letters, can you look?"* It reads fine to the person who wrote it, because they remember the rest.
**A report is written for somebody who was not there**: a developer next week, a tester on another
team, or you in three months with the details forgotten. Everything that reader needs to see the
failure again, and to judge how much it matters, has to be on the page. The one person who could
answer their questions is the person they are trying not to interrupt.

That is the same test lesson 3 applied to a case, turned the other way round. A case says *do this
and you should see that*. A report says *I did this, I should have seen that, and I saw something
else*. The fields below are what that sentence needs once it is taken apart.

## The fields

| field | what it holds | the question it answers |
|---|---|---|
| **title** | what fails, where, and under what condition, in one line | can somebody find this again by searching, and tell it from its neighbours? |
| **environment** | the version under test, the system, the browser or client, anything set up for the test | is the reader looking at the same thing you were? |
| **preconditions** | the state before the first step: data, accounts, a fresh start | where does the reader start from? |
| **steps** | numbered actions, each one thing, with the exact values typed | what did you do? |
| **expected** | what should have happened, and the requirement that says so | why is this a defect and not a preference? |
| **actual** | what did happen, word for word where there are words | what exactly is wrong? |
| **evidence** | the transcript, a log line, a screenshot | can the reader see it without running anything? |
| **severity** | how much harm the defect does | how bad is it? |
| **priority** | how soon it should be fixed | in what order does it get fixed? |

Trackers add their own fields, an id, the reporter, a date, a component, and lesson 17 shows how
the nine above land in four of them. The nine are the part a tracker cannot fill in for you.

Two of them deserve a sentence each before the example. **The title is what most people will ever
read of your report**: it is the line in a list of forty, the subject of a notification, the text
somebody searches before filing a duplicate. "Error on booking page" matches every defect the page
will ever have. "Booking with a quantity that is not a whole number answers 500 with a Python
traceback" matches one. **The expected result cites the requirement**, because without it the
report is your opinion against the developer's, and with it the report is the requirement against
the program.

## A whole report

Lesson 4 found that boxoffice 1.0 answers a word in the tickets field with an error page. Release
1.1 changed the quantity rule and left that line alone, so the defect is still there, and lesson 14
added one more reason to care: the page shows the program's own code and file paths to whoever
typed the word. Here is the report Ana writes for it, against 1.1:

| field | |
|---|---|
| title | Booking with a quantity that is not a whole number answers 500 with a Python traceback |
| environment | boxoffice 1.1 (`/health` answers `ok boxoffice 1.1`), Python 3.13.16, Ubuntu 24.04; reproduced with curl 8.5.0 and in Chromium |
| preconditions | boxoffice freshly started, so the seeded account `member@example.org` exists and nothing is booked |
| steps | 1. Open `http://127.0.0.1:8000/book?show=S2`. 2. In E-mail, type `member@example.org`. 3. Leave the show as Hamlet. 4. In the tickets box, type `two`. 5. Press Book. |
| one-line reproduction | `curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book` prints `500` |
| expected | the booking form again, with a sentence saying the tickets must be a number from 1 to 6, as a quantity of `7` gets (R4, R7: wrong input is answered with a sentence, never with an error page) |
| actual | status 500; the page is a Python traceback ending `ValueError: invalid literal for int() with base 10: 'two'`, with the program's file path and line numbers, and none of the theatre's page around it |
| reproducibility | every time; also with the quantity empty and with `2.5` |
| evidence | the transcript and the server's log line, section 05 of this lesson |
| severity | major |
| priority | for triage to set, lesson 16 |
| found in | 1.0, by lesson 4; still present in 1.1 |

Nothing in it is an opinion until the severity, and even that has a scale behind it, which section
04 of this lesson gives. Nothing in it guesses at the cause either. The traceback names a line of
code, and the developer will read it there. A report that says *"the int() call needs a
try/except"* has started fixing a program its writer does not own, and is wrong as often as it is
right.

## What a report leaves out

**One defect per report.** The traceback and the misspelt *"cannot be useed"* lesson 11 found are
two defects, fixed by different lines, on different days, perhaps by different people. Put in one
report, one of them is fixed, the report is closed, and the other is forgotten with it.

**No adjectives about the program or the people.** *"Booking is completely broken again"* is wrong
on two counts: booking works for every whole number, and *again* accuses somebody without a fact
behind it. The reader of a report is the person whose work it describes, and a report written as
an accusation is read as one and argued with instead of acted on.

**No story.** The order you noticed things in, what you were trying to test that morning, what you
thought it might be: none of it helps somebody reproduce the failure, and all of it pushes the
steps further down the page.
