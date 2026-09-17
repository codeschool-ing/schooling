---
title: One table, and everything that can go wrong in it
version: 1
---

Lesson 1 ended with a procedure: name the things, one table each, ask "several?" in both
directions. It works, and it is a habit rather than a rule — so when two people disagree about a
design, neither of them can say who is right.

Normalisation is that advice with a proof attached. Before the rules, here is the table they are
about. A course-booking system, all in one place:

| enrolment_id | student_email | student_name | course_code | course_title | teacher | teacher_room | grade |
|---|---|---|---|---|---|---|---|
| 1 | ana@ex.com | Ana Lopes | SQL101 | Databases | Reis | B-204 | 17 |
| 2 | bruno@ex.com | Bruno Sá | SQL101 | Databases | Reis | B-204 | 14 |
| 3 | ana@ex.com | Ana Lopes | NET200 | Networks | Dias | A-110 | 15 |
| 4 | celia@ex.com | Célia Reis | SQL101 | Databases | Reis | B-204 | 18 |

Every question this system is asked can be answered from it, and for a while nothing goes wrong.

## Four things that can go wrong, and they have names

The point of normalisation is not tidiness. It is that a table in this shape permits four
specific accidents, and a table in third normal form does not. Learn the four and the rules
become obvious rather than memorised.

**An update anomaly.** Teacher Reis moves to room B-310. Three rows say `B-204` and all three have
to change together. Change two and the database now holds two answers to "where does Reis teach?",
with nothing to say which is right. *One fact, several places, free to disagree* — the same defect
as lesson 1's email address, and the reason it is the same is that it is the same defect.

**An insertion anomaly.** A new course, CRY300, is created and nobody has enrolled yet. There is
nowhere to put it. The table's row is an *enrolment*, so recording a course means inventing a fake
student — or waiting, and letting the first enrolment carry the course into existence. Neither is
a thing anybody chose.

**A deletion anomaly.** Ana withdraws from NET200 and row 3 is deleted. **The course NET200 has
now ceased to exist**, along with the fact that Dias teaches it and where. Nobody meant to delete
a course. They deleted an enrolment, and a fact that was only ever stored beside it went with it.

**A redundancy that grows.** `Databases` is written three times, and will be written once per
enrolment forever. That is storage, which is cheap, and it is also three chances to type it
differently, which is not.

All four come from one thing, and it is worth saying before any formal definition:

> **The table is about more than one kind of thing.** A row is an enrolment, a student, a course
> and a teacher at once, so facts about students, courses and teachers can only be stored where an
> enrolment happens to put them.

## What normalisation actually does

It **decomposes**: it splits one table into several, so that each fact is stored once, and it
does so in a way that loses nothing — the original table can be reconstructed by joining the
pieces back together.

That last clause is not decoration. A split that loses information is not normalisation, it is
damage, and the forms are defined so that following them cannot do it.

Three steps, each removing one kind of repetition:

| form | removes | one-line test |
|---|---|---|
| **1NF** | several values crammed into one cell | is every cell a single value? |
| **2NF** | facts that depend on only part of the key | does every column need the *whole* key? |
| **3NF** | facts that depend on another ordinary column | does every column depend on the key *directly*? |

There is a well-worn sentence for the last two, and it is genuinely the best summary anybody has
written:

> **Every non-key column depends on the key, the whole key, and nothing but the key.**

`the key` is 1NF's doing. `the whole key` is 2NF. `nothing but the key` is 3NF.

## What this lesson is not going to do

It is not going to give you the textbook definitions first and examples afterwards. That order is
why most people can recite "no partial dependencies" and cannot use it.

Instead, each of the next three sections takes the table above and asks one question: **what can
go wrong here that could not go wrong if it were split?** The normal forms turn out to be the
answers. You will meet the formal definition at the end of each section, by which point it will
be a name for something you have already seen rather than a thing to memorise.

And then — because this is the half that gets left out of most teaching — the last sections do the
opposite. There are good reasons to deliberately break third normal form, there is a test for
whether yours is one of them, and there is a case that looks like breaking it and is not.
