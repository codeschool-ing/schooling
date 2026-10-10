---
title: The mirror, applied to the ticket shop
version: 1
---

**The four test levels are worth knowing whatever process a team uses**, because they describe what is
being checked rather than when. Applied to Cine Aurora, each level has a different subject, a different
basis and, usually, a different person running it.

## One test at each level

| level | the subject | an example | its basis | usually run by |
|---|---|---|---|---|
| **unit** | one piece, alone | `price(60, False, "thu", "20:00")` should be 1800 | the module's design: `price` returns centavos | the developer who wrote it |
| **integration** | two pieces together | an order for an adult and a child on a Thursday evening stores a total equal to the two prices added | the architecture: `orders.py` asks `tickets.py` for each price | developers, or a tester with grey-box knowledge |
| **system** | the whole shop | a customer chooses a session on the website, picks three seats, pays, and receives a receipt for R$ 90,00 | the system's specification | testers |
| **acceptance** | the shop as Célia and the customers need it | on a Sunday morning, a family buys for the 9:30 session at the same price the box office charges | the users' needs | the product owner, users, or testers on their behalf |

Notice where the defects of this course would have been found. The sixty-year-old at the unit level, if
anybody had chosen sixty. The refused orders stored, at the integration level, where the order and the
database meet. The 9:30 session only at the acceptance level, because only there does a real session time
typed by a real person reach the price rule. **Each level catches defects the levels below it cannot see**,
which is why skipping one is never free.

## The traceability matrix

A V-model project keeps a table that links every requirement to the tests that check it, and every test to
the requirement it comes from. It is called a **traceability matrix**, and in regulated work it is often
the document an auditor asks for first. A fragment for the price rule:

| requirement | unit tests | system tests | acceptance tests |
|---|---|---|---|
| R1: evening R$ 36,00 from 17:00, matinée R$ 28,00 before | 16:59 and 17:00 | a session at 16:30 and one at 19:00 bought on the website | the Sunday 9:30 session |
| R2: students, over-60s and under-12s pay half | 11, 12, 59, 60, 61; a student | a family with a child on the website | a pensioner buys online |
| R3: Wednesday half price | an adult on Wednesday | a Wednesday purchase | — |
| R4: one to six tickets per order | — | 0, 1, 6 and 7 tickets | — |
| R5: half price is the most any ticket is reduced | a student on Wednesday | a family on Wednesday | — |

Read it in both directions. **Along a row**, it shows how well a requirement is covered: R4 has no unit
test and no acceptance test, which may be fine or may be a gap. **Down a column**, every test has a reason:
a test that traces to no requirement is either testing something nobody asked for or testing a requirement
nobody wrote down, and both are worth a question.

The matrix also shows what lesson 6 found from the outside: R5 did not exist until Lia's question created
it. A matrix built from the first four sentences would have looked complete and had nothing to say about
students on Wednesdays.

## Beyond the V

The levels and the matrix outlive the model they were drawn in. An agile team still has unit, integration,
system and acceptance tests; it runs them all every week instead of once a year. The `testing-cicd`
course treats the four levels in depth as they appear in a pipeline, and `manual-testing` lesson 13 gives
an overview of unit and integration testing from a tester's side. What belongs here is the mirror itself:
**for every description of the system, ask which test will check the system against it, and who will run
that test.**
