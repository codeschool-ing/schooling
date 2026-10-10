---
title: Scenarios, and the cases inside them
version: 1
---

The words *scenario* and *case* are often used as if they meant the same thing, and in a hurried
conversation they can. In a set of tests they do different jobs. **A test scenario is one sentence
saying what needs testing; a test case says how**, with the state, the data, the steps and the
result. *A member books tickets* is a scenario. TC-BOOK-01 is one of the cases that test it.

## Why write scenarios first

A scenario costs a sentence, and a case costs ten minutes. That difference is the reason to write
the scenarios first. A list of fifteen scenarios fits on half a page. The theatre's manager can read
it in five minutes and answer the one question that matters at this stage: **is anything
missing?** Asking that question of a hundred finished cases is too late, because the effort has
already gone into what was there.

Scenarios also come in the user's words rather than the tester's. *Somebody books tickets for
tonight's show an hour before it starts* is a scenario the manager recognises at once, and the
manager is the person who knows that it happens every Saturday. Nobody needs to know what a
precondition is to say that a scenario is missing.

The standard for test documentation calls the step before a case a **test condition**, an item or
event that could be checked by one or more cases. Many teams say scenario for the same thing, and
this course does too.

## One scenario, several cases

A scenario becomes as many cases as there are different outcomes worth checking. *Somebody creates
an account* becomes at least two: one where the account is created, and one where it is refused
because the e-mail address already belongs to somebody.

These two kinds have names. **A positive case** checks that the application does what it should
with input it should accept; it is sometimes called the happy path. **A negative case** checks
that the application refuses what it should refuse, and refuses it the way the requirements say.
R7 asks boxoffice to answer wrong input with a sentence saying what is wrong, so every negative
case on boxoffice has an expected result of that shape.

**A negative case is not a case that fails.** TC-SIGNUP-02 below tries to create an account with an
e-mail address that is already taken. Its expected result is a refusal, so it passes when
boxoffice refuses, and fails if boxoffice creates a second account with the same address. The
input is negative; the verdict is as open as any other.

## The scenarios for R2 to R4

This lesson tests sign-up, confirmation and booking, which are R2, R3 and R4 of lesson 1's list.
Four scenarios cover them, and the third column names the cases section 04 writes:

| scenario | requirement | cases |
|---|---|---|
| SC-01 Somebody creates an account | R2 | TC-SIGNUP-01, TC-SIGNUP-02 |
| SC-02 A new account is confirmed from its e-mail | R3 | TC-CONFIRM-01, TC-CONFIRM-02 |
| SC-03 Somebody with an account books tickets | R4 | TC-BOOK-01, TC-BOOK-02 |
| SC-04 A new visitor signs up, confirms and books at the member price | R2, R3, R4, R5 | TC-SIGNUP-01, TC-CONFIRM-01, TC-BOOK-03 |

SC-04 is an **end-to-end scenario**: it follows one person through several features in the order
they would use them. It mostly reuses cases the other scenarios already need and adds one, TC-BOOK-03,
because the new visitor's booking is the only place where confirming an account changes a price.
End-to-end scenarios find the defects that live between features, where each feature works on its
own and the hand-over between them does not.

## What these four leave out

Four scenarios do not test R2 to R4 completely, and a list that pretends otherwise is the gap
lesson 1 warned about. Three things are deliberately missing from this lesson.

**Which wrong values to try.** A name of 41 characters, a password of 7, a quantity of 0 or 7 or
the word *two*: each is a negative case, and choosing which of the endless wrong values are worth a
case is a technique of its own. Lesson 4 is that technique.

**The second half of R3.** A link valid for 24 hours, and a new link that stops the old one from
working, both need time to pass or a second e-mail to arrive. Lesson 22 is about testing e-mail,
and those cases are written there.

**Time.** R4 closes booking one hour before the show. Lesson 3 section 04 shows why a case that
touches the clock has to say what time it is run at.

Writing the omissions down is what makes them decisions. When the manager reads this list, they
can see that 41-character names are not here yet, and why.
