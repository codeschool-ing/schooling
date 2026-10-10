---
title: Where test data comes from
version: 1
---

Every case in this course has needed data before it could run: an account to book with, a show
with seats left, an order in the right state. Most of it was there because boxoffice starts with
it, and the rest was typed by hand in the step before. **Test data is everything a case needs to
exist before it starts, and everything it creates while it runs**, and where it comes from decides
whether the case can be trusted, repeated, and run by somebody else.

## Four sources

**Built in.** The data the application starts with. Boxoffice has three shows and one account, the
member `member@example.org`, and every case in lesson 18's spreadsheet leans on them. Built-in data
is the cheapest there is and the most fragile: a case that expects Hamlet to have 80 seats left is
a case about the starting state as much as about booking.

**Made by hand for a case.** The account TC-02 signs up, `teste1@example.org`, exists because that
case needs a new address. Hand-made data is chosen for a reason, which makes it the right source
for the techniques of lessons 4 and 5: the 40-character name, the seventh ticket, the member who
books five. Nobody would type two hundred of them.

**Generated.** Data a program invents to a rule, in any quantity, the same every time it runs.
Section 03 of this lesson writes one for boxoffice, and it signs up five accounts in less time than
it takes to type one.

**Copied from production.** Data real customers created, with every case nobody thought of in it.
It is also their personal data, which section 04 of this lesson is about.

Most real testing mixes all four, and a case's precondition is where it says which one it relies on.

## What good test data has

**It is known.** Before a case runs, somebody can say exactly what is there. "Some accounts" is not
known; "the five accounts in accounts.csv" is. When a case fails, the first question is whether
the product is wrong or the data was not what the case assumed, and only known data can answer it.

**It belongs to nobody.** An address a test signs up with may receive mail, so an invented address
at a real provider may reach a real stranger. Boxoffice's outbox keeps every message, which is why
this course could be careless and is not: every address in it is at `example.org`, one of a few
domains reserved for examples that never deliver anywhere. Lesson 22 is about what happens to test
e-mail in environments that do send it.

**It covers what the case is about.** A case about the student discount needs a student booking; a
case about a full show needs a show with no seats. Data for the case comes from the case, and the
technique that chose the values chooses the data too.

**It can be put back.** A case that books six tickets for Hamlet leaves Hamlet with six fewer. Run
it fourteen times and the fifteenth finds a show with no seats left and fails for a reason that has
nothing to do with what it checks. Section 05 of this lesson is about getting back to a known
state, and why boxoffice makes that unusually easy.

## Data that runs out

Some data is used up by the case that uses it. An order can be paid once; once it is paid, the case
for paying it cannot run on that order again. A confirmation link is meant to work once. Seats run
out. **Consumable data** is the commonest reason a case passes on Monday and fails on Tuesday with
nothing changed in the product, and the fix is never to edit the case until it passes. It is to
make the case create what it consumes, or to start each run from a state where it exists.
