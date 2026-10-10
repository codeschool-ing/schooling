---
title: Reviews, or testing that runs nothing
version: 1
---

A common picture of testing is that it starts when there is something to run. Some of the cheapest
testing there is runs nothing at all. **Static testing examines a work product without executing
it**: a requirement, a design, a test case, a piece of code. Its most common form is the review, a
person reading a document with a question in mind, and the document that repays a review best is
the one every other piece of work is built from, the requirements.

A review of R1 to R9 is verification in the sense of section 02 of this lesson. It checks the
requirements against themselves and against each other, before the product is checked against
them.

## What a review looks for

A requirement that can be tested has four properties, and a review reads each sentence for them:

- *one reading*: two careful people reading it come away with the same rule;
- *complete*: it says what happens in every case it covers, including the awkward ones;
- *consistent*: it agrees with the other requirements, and uses their words the same way;
- *testable*: somebody could decide pass or fail from it, without asking its author.

The last one is the tester's own question, and the others are mostly found by trying to answer it.
Reading R5 to write a case for it is where most testers notice that they do not know what the case
should expect.

## Ana reviews R1 to R9

Ana reads each requirement as if she had to write its cases that afternoon, and writes down every
place where she would have to guess. Four of her findings:

| | the words | the question |
|---|---|---|
| R5 | "Students pay half." | How is somebody shown to be a student, and by whom: a box ticked when booking, a card shown at the door? |
| R5 | "Students pay half." | Half of what, the ticket or the order? A member booking for herself and two student children could pay either way. |
| R4 | "Booking for a show closes one hour before it starts." | R1 says times are São Paulo time; R4 does not say in whose time the hour is counted. Is the cut-off 19:00 in São Paulo for a customer booking from Lisbon as well? |
| R8 | "current Chrome, Firefox, Safari and Edge" | Which versions are current: the newest of each, or the last two? Lesson 7 has to know. |

None of them is a defect in boxoffice. Each is a place where the requirement lets two people build
or test two different things, and **the review's output is a list of questions for the person who
owns the requirements**, the theatre's manager, each with the id, the words and the readings.
"R5 is unclear" gives the manager nothing to answer. "R5, per ticket or per order, and here is what
each would charge" can be answered in one line.

## What the program did with the question

An ambiguity left in a requirement does not stay open. Whoever writes the code has to pick a
reading, usually alone and without saying so. Restart boxoffice, and book three Hamlet tickets as
the member, first with the Student box ticked and then without:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=3&student=on' http://127.0.0.1:8000/book | grep -A2 msg
<p class="msg">Order 1001 reserved.</p>
<p>Hamlet, 3 ticket(s), 50% off:
<strong>R$ 120,00</strong></p>
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=3' http://127.0.0.1:8000/book | grep -A2 msg
<p class="msg">Order 1002 reserved.</p>
<p>Hamlet, 3 ticket(s), 10% off:
<strong>R$ 216,00</strong></p>
```

The Book page has one Student box for the whole order, so Rui answered the second R5 question: half
applies to the order. With the box ticked, Bia's own ticket is half price too, R$ 120,00 for the
three. Without it, her two children pay the member price, R$ 216,00. If half price was meant per
ticket, the family should pay R$ 72,00 for Bia and R$ 40,00 for each child, R$ 152,00, and the
page has no way to ask for that. And the first R5 question is answered as well: anybody who ticks
the box is a student.

Which of the three totals is right is the theatre's decision, not Rui's and not Ana's. The point of
the review is that **the question reaches the person who can decide it before somebody writes it
into the code by guessing**. Found in a review, it costs an e-mail to the manager. Found after the
release, it costs an argument at the door with a family holding three half-price tickets.
`qa-fundamentals` lesson 3 puts numbers on how that cost grows.

## Kinds of review

Reviews range from a colleague reading a page to a meeting with a moderator and a checklist. The
names in the standards, from least to most formal: an *informal review*, one person reading and
sending comments; a *walkthrough*, the author leading others through the document; a *technical
review*, peers judging it against its purpose; and an *inspection*, with defined roles, a
checklist, and figures kept about what was found. A theatre's nine requirements need the first
kind and an hour. A bank's payment rules justify the last.

The same reading applies to things other than requirements. Lesson 3's test, whether a stranger
could run a case without asking a question, is a review of a test case. Developers review each
other's code, and static analysis tools read code for patterns that are usually mistakes, without
running it. A tester takes part in the first two and mostly hears about the third.
