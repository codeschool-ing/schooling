---
title: Defect numbers that mean something
version: 1
---

Once reports live in a tracker, counting them is free, and somebody will. The first number anybody
reaches for is the count: how many defects were found, how many are open, how many each tester
filed. **A count of reports measures the reporting, not the product**, and the moment it is used to
judge people, the reporting changes to suit it. The numbers worth keeping are the ones that answer
a question the team actually has, and that nobody can improve without improving the work.

## Three that earn their place

**Age of the open defects, by severity.** How long has each open report been waiting since it was
filed? Read by severity, it answers *are we leaving serious things undone?* An open critical
defect that is two days old is a team at work; one that is two months old is a decision nobody
took. On boxoffice, the oldest open report is the traceback, found by lesson 4 on release 1.0 and
still open on 1.1 at P2. Its age says something the priority alone does not: it has been
outranked at every triage so far, and at some point a report that always loses should either win
once or be deferred on purpose.

**Reopen rate.** Of the defects marked fixed, how many came back from the retest? It answers *do
our fixes hold?* A high rate means fixes go out untested, or reports are unclear enough that the
developer fixes something other than what was meant, and reading the reopened reports tells the two
causes apart. It is a ratio, so it needs a period and a denominator: *6 of the 40 fixed last
quarter came back, 15%*. boxoffice has two fixes so far, the six-ticket rule and the member
discount, and neither was reopened. That is 0%, and two is far too few to mean anything; the honest report of it says *two
fixes, none reopened* and draws no conclusion.

**Escaped defects.** Of the defects found in a period, how many were found by customers after the
release instead of by the team before it? It answers *what is our testing missing?*, and the useful
part is not the number but the list: each escaped defect is a question about why no case, session
or check reached it. A defect the theatre's manager finds in the acceptance session of lesson 12
has not escaped. One a customer finds at the door on opening night has.

All three share a property: **the only way to make the number look better is to do the work
better.** You cannot lower the age of a critical defect without fixing it or deliberately deferring
it, and both are visible.

## Theatre

Some numbers look like management and reward the wrong work. They are worth recognising, because
they are often already on a dashboard when you join.

**Defects found per tester.** It rewards splitting one defect into several reports, which is
exactly what section 04 of this lesson spent its time undoing: *payed* and *useed* filed separately
count twice. It punishes the tester who spends a morning making one report reproducible, and the one
who tests the stable part of the product where defects are rare and the risk is high. It also
quietly turns testers against each other, since a defect one of them reports is one the other
cannot.

**Total open defects, with no severity.** Thirty trivial wording defects and one critical refund
defect make thirty-one, and so do thirty-one critical ones. A chart of the total going down can
mean the team fixed the critical one, or that it closed thirty misspellings and left the refund
alone.

**A target of zero open defects at release.** It sounds like quality. In practice it produces
defects rejected that should have been deferred, deferred that should have been fixed, and,
worst, not filed at all, by testers who have learnt what a new report does to the chart. The
deferred list of section 03's triage exists because some defects are not worth fixing now; a
target of zero makes that honest decision look like failure.

**Defects per developer.** It tells developers that a report is an accusation, and lesson 15
already said what happens to a report read as one: it is argued with instead of acted on.

## A number is a question

The rule underneath is old and has a name, Goodhart's law: when a measure becomes a target, it
stops being a good measure. **Before reporting a number, write down the question it answers and
what you would do differently if it went up.** *Reopen rate went from 5% to 20% this quarter, so we
will read every reopened report and look for the common cause* is a number doing its job. *We found
212 defects* is a number looking for a question, and lesson 19 is about what to put in front of the
people who read these reports instead.
