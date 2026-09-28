---
title: loanbook in two minutes
version: 1
---

Here is loanbook's version, written out in full. Spoken at a calm pace it takes a little under two
minutes. Read it aloud once, with a clock, before reading the notes below it.

```localised
A school's IT room lends projectors and laptops to teachers, and the only record was a paper sheet
on the door. It was wrong in both directions: things marked out were on the shelf, and one morning
two teachers turned up for the same projector, each sure she had booked it.

I built loanbook to replace the sheet: one page that shows what is out, who has it and when it is
due back. The interesting part was that morning. If two people press Lend at the same moment, a check
in the code reads "available" twice and lets both through. So I let the database refuse instead: a
partial unique index allows one open loan per item, and the second request gets a clear message
saying who has it. I wrote a test for it, and then removed the index to make sure the test failed.

The cost is that there are no accounts. A borrower is a name typed in, so anybody who can open the
page can lend. For one staffroom that was the right trade; for several schools it would be the first
thing to change.

It is deployed on a server in a container, behind HTTPS, and it came back on its own when I killed
it. The README has the decisions, and the next thing I would build is e-mail reminders for late loans.
```

Look at what the script does not contain: the word *Python* appears nowhere, and *SQLite* only inside
*the database*. A listener who wants the stack will ask, and the question is an opening. What the script
does contain is **one story, one decision with its reason, one cost, and three pieces of evidence**:
the test that was made to fail, the deploy that survived a crash, and a README a reviewer can open.

Yours will have different sentences and the same four paragraphs.
