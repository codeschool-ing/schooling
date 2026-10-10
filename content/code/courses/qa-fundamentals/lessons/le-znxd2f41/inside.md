---
title: Testing from the inside
version: 1
---

**White-box testing chooses its tests by looking at the code: its decisions, its branches, the paths
through it.** Where black box asks *what should this do?*, white box asks *what can this do?*, and
answers by reading. The name is the obvious opposite of black box, and some books prefer **glass box**
or **clear box**, which describe it better: you are not painting the box white, you are seeing through it.

## You do not have to write code to read it

The commonest objection from testers who do not program is that white box is a developer's job. Part of
it is. The part this lesson teaches is not, and you have been doing it since lesson 1: reading
`tickets.py` with the notes beside it, well enough to say what each part decides. That is enough to ask
the white-box questions:

- **which lines exist that no test has made run?**
- **which decisions have only ever gone one way?**
- **which combinations of decisions has nothing ever exercised?**

Answering them needs a tool that watches the program run and records what happened, and Python has one
built in. Nobody has to change a line of `tickets.py`.

## Four ways of measuring the inside

The questions above have names, each stricter than the one before. They are called **coverage**
criteria: measures of how much of the code's structure a set of tests has exercised.

| criterion | covered when every… | for `tickets.py` |
|---|---|---|
| **statement** (or line) | line has run at least once | each of the lines in `price` |
| **branch** (or decision) | decision has gone both ways at least once | each `if` true once and false once |
| **condition** | part of a combined decision has been true and false | none here: every `if` tests one thing |
| **path** | route from the start of the function to a `return` has been taken | every combination of the six `if`s that can happen |

Each one is satisfied by more tests than the one above it, and finds defects the one above cannot. The
next two sections measure the first and reason about the second and the last.

## What white box is good at

Its great strength is the mirror of black box's weakness. Black box only tests the behaviour somebody
thought of; white box tests **the behaviour that exists**, whether anybody thought of it or not. If
`tickets.py` contained a line that gave a discount on one particular date, no rule would point at it, and
a white-box tester would find the line by reading, and a coverage tool would report that no test had
run it.

It is also the natural approach for the people who wrote the code, at the moment they write it. Rafael
does not need a specification to know that his `if age < 12` should be tried with 11 and with 12. He can
see the line.

## What it is bad at

Its weakness is the mirror of black box's strength. **White box tests the code that exists, and so it
cannot see code that is missing.** `tickets.py` has no line that checks whether a time is written with a
leading zero, no line that refuses an age of minus five, no line that caps the reductions at half. None
of those absences shows up in any coverage report, because a report can only describe lines that are
there. Lesson 6 found all three from the outside.

That is the reason the two approaches are used together, and the reason lesson 8 exists.
