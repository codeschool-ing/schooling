---
title: People, environment, schedule and the criteria
version: 1
---

The scope and the risks say what to test. The rest of a plan says what the testing needs and when
it ends, and **the part most often left vague is the end**. This section covers the remaining
questions and finishes with the whole plan for boxoffice 1.0 on one page.

## People and skills

A plan names who tests, by role if not by name, and what each person needs to know. For a small
team the answer is short and still worth writing: one tester for two weeks, the developer for an
hour a day to answer questions and fix what is found, and the theatre's manager for one afternoon
of acceptance testing at the end, the subject of lesson 12. Writing the manager's afternoon into
the plan is what makes it happen; an acceptance test that depends on somebody remembering to ask
is usually skipped.

Skills belong here too. If the plan says the pages will be checked with a screen reader, somebody
has to know how to use one, and if nobody does, the plan says who will learn and when.

## The environment

The **test environment** is everything the application runs on and everything that talks to it
while it is being tested: the machine, the operating system, the version of the application, the
browsers and devices, the accounts, the data, and anything outside it, such as a mail server. Each
of those can make a test pass or fail by itself, which is why lesson 21 is about environments that
disagree.

For boxoffice the environment is the one section 03 of this lesson set up, with three decisions
added. The version tested is the file as section 04 shows it, 1.0. The browsers are the four named
in R8. And e-mail is the outbox, so the plan says that the real mail server is not tested, which
the scope already did.

## The schedule

A test schedule is tied to the project's schedule, because testing waits for things: a build to
exist, a feature to be finished, an environment to be ready. So **a test schedule is written in
dependencies first and dates second**. "Booking tests start when booking is deployed to the test
environment" survives a two-day delay in development; "booking tests start on the 12th" does not,
and leaves the tester waiting with a date that has stopped meaning anything.

## Entry, exit and suspension criteria

**Entry criteria** say when testing can start: the build starts, the environment answers, the
requirements for the feature are written. Starting before they hold produces failures that are
about the environment rather than the product, and a day of reports nobody can act on.

**Exit criteria** say when testing is finished, and they are written now, while nobody is tired.
A useful one is checkable by somebody who did not do the testing. *"Testing is complete when
quality is acceptable"* is not checkable. *"Every case for risks A to C has run and passed, no
open defect is of critical or major severity, and the manager has signed off the acceptance
session"* is, and its words, severity and sign-off, are lessons 15 and 12.

**Suspension criteria** say when to stop and wait instead of continuing: if the application does
not start, or if more than a quarter of the cases in one area fail, testing in that area pauses
until a new build arrives. They exist because a tester who keeps going on a broken build spends the
day writing reports about one defect in twenty disguises. Lesson 8's smoke test is the usual way of
checking them on each new build.

## The whole plan, on one page

| | boxoffice 1.0, test plan |
|---|---|
| scope | R2 to R9, as section 06 lists them. Out: payment, load, the real mail server |
| risks | A price, B overselling, C refunds, D confirmation e-mail, E phone layout; tested in that order |
| approach | manual, against the requirements; case design techniques of lessons 4 and 5 for A to C; exploratory sessions of lesson 11 for each area; smoke on every build |
| people | Ana, tester, two weeks; Rui, developer, an hour a day; the theatre's manager, one afternoon |
| environment | boxoffice 1.0 on the tester's laptop; Chrome, Firefox, Safari and Edge, current versions; a phone 360 pixels wide; e-mail read in the outbox |
| schedule | cases written in week 1 as each feature arrives; risks A to C run first; acceptance session on the last afternoon |
| entry | the build starts and `/health` answers; R1 to R9 written |
| exit | all cases for A to C run and passed; no open critical or major defect; acceptance signed off |
| suspension | the build does not start, or a quarter of one area's cases fail |
| deliverables | the cases, the defect reports, a one-page summary at the end (lesson 19) |

Nine rows, and every one of them can be disagreed with. That is what the first section of this
lesson asked of a plan, and a plan this size takes an hour to write and saves the arguments that
otherwise happen on release day.
