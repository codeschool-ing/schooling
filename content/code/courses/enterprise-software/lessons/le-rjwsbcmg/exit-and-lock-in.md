---
title: The price of leaving
version: 1
---

"Avoid vendor lock-in" is said in every architecture meeting and decides nothing, because every
option locks Serra Alta into something. A SaaS product locks it into a vendor's contract and data
model. An SAP extension locks it further into SAP, where it already lives. A build locks it into
seven people's code and the handful of them who stay. **Lock-in is not a property an option has or
lacks; it is a cost of switching, and a cost has a price.** Once it has a price it can go on the sheet
beside the others, and the argument becomes one about a number somebody can check.

This section prices the exit line for all three options, explains what each part of it pays for, and
shows where the contract and the architecture can make it smaller.

## What leaving costs

An exit is counted as what it would cost Serra Alta to leave at the end of the period — 31 December
2029 — **excluding the next system's own costs**, which belong to the next system's sheet. What is
left is the price of getting out:

| part | what it pays for |
|---|---|
| data export | getting every farm, every collection and every lab result out, in a form another system can load |
| overlap | the old system kept running while the next one runs in parallel, usually three months |
| integrations to rebuild | the interfaces that spoke to the old system and must now speak to the next one |
| retraining | the 300 drivers and 30 office staff, on whatever replaces what they learned |
| termination fees | anything owed for leaving before the end of a term |
| notice | not a cost in itself, but it decides when the others can be avoided |

For option A, at the end of month 36:

| part | worked out as | reais |
|---|---|---|
| data export | the vendor's priced service for the full history, in its documented format | 30,000 |
| overlap | three months of subscription at the year-3 price: 3 × R$ 26 × 2,100 farms | 163,800 |
| integrations to rebuild | 60% of the integration line: 0.6 × R$ 240,000 | 144,000 |
| retraining | drivers and office staff | 60,000 |
| termination fees | none: leaving at the end of a renewal term | 0 |
| **exit** | | **397,800** |

The overlap is the largest part, and it surprises people. **A collection system cannot be switched
off on a Friday and replaced on the Monday**: lesson 13's parallel run needs the old system computing
the same farm payments as the new one, month by month, until the two agree. For those three months
Serra Alta pays both.

## The contract decides half of it

Three clauses in A's contract decide what the exit costs, and **they are negotiated at signature,
when Serra Alta can still walk away, or not at all**.

*The export.* The vendor exports the current farm master as a CSV file at any time, free. The full
history — thirty-six months of collections and lab results — comes as a paid service, R$ 30,000, in a
documented format with a data dictionary that names every field and its unit. Without that
dictionary the export is a file of numbers whose meaning somebody has to rediscover, which is lesson
14 again at the worst moment. The contract also says the vendor keeps Serra Alta's data for 90 days
after the end and then deletes it, so the export has a deadline.

*The notice.* The first term is 24 months. To leave at its end, Serra Alta must give six months'
notice, by the end of month 18 — June 2028, the month Sebastião retires. Miss that date and the
contract renews for year 3, R$ 655,200 committed whatever Serra Alta then decides. **The notice
period is the part of lock-in that shows up as a date**, and it belongs in somebody's calendar with
their name on it, not in the contract's appendix.

*Termination before the term.* Leaving early means paying the rest of the term. If Serra Alta left
at the end of year 1, it would owe year 2's twelve months anyway: R$ 25 × 2,000 farms × 12 =
R$ 600,000. That is the price of a two-year term, and it buys the R$ 25 price; a one-year term would
have cost more per farm and less to leave.

## The architecture decides the other half

The 60% in the integrations line is not a guess about the vendor. It is a consequence of how Serra
Alta builds its interfaces. Lesson 13 introduced the **anti-corruption layer** to keep Coleta's
model out of the new one. Serra Alta's integration plan uses the same pattern on the other side: SAP,
the lab and Rota talk to Serra Alta's own model of a farm, a collection and a payment, and only the
layer talks to the product. Leaving the product means rewriting the side
of the layer that faces it, not every interface behind it.

Without the layer, every interface would be written against the vendor's API, and all of the
integration line would be rebuilt on exit: R$ 240,000 instead of R$ 144,000. **The R$ 96,000
difference is lock-in removed by design**, paid for once in the integration work and collected on the
day Serra Alta leaves — or never collected, and still worth having, because it is also what lets
Serra Alta negotiate a renewal as somebody who could leave.

## B and C have exits too

| part | A: buy | B: extend SAP | C: build |
|---|---|---|---|
| data export | 30,000 | 40,000 | 10,000 |
| overlap | 163,800 | 0 | 57,000 |
| integrations to rebuild | 144,000 | 90,000 | 180,000 |
| retraining | 60,000 | 60,000 | 60,000 |
| **exit** | **397,800** | **190,000** | **307,000** |

B has the smallest exit, for a reason worth understanding. Leaving
B means taking the farm payment out of SAP. SAP itself stays, so there is no subscription to overlap,
and the farms remain vendor records whatever replaces the calculation. Getting the history out of
custom tables costs R$ 40,000, and 60% of B's smaller integration line, R$ 90,000, is rebuilt.
Serra Alta is already locked into SAP for its finance, its sales and its stock; **lock-in it already
holds costs nothing extra to add to**. B's lock-in shows in other lines instead: the custom code that
has to be tested again at every S/4HANA upgrade (R$ 150,000 in year 3), and the two people in Edson's
team who will understand it.

**C's data is its own**, in a PostgreSQL database whose schema Serra Alta wrote, so the export costs
R$ 10,000 of somebody's time. Its overlap is three months of running its own system — R$ 9,000 of
infrastructure and R$ 10,000 of operation a month, R$ 57,000. Its integrations line is the largest
of the three, so 60% of it, R$ 180,000, is the largest rebuild. The lock-in the table cannot show is
the one section 04 of this lesson named: the few people who understand the code.

## Why the exit is counted whole

A common objection: Serra Alta does not intend to leave, so why add R$ 397,800 to A? Some sheets
multiply the exit by a probability of leaving — a 20% chance, say — and add a fifth of it.

Serra Alta's sheet counts it whole, for two reasons. The probability is a guess, and multiplying a
real number by a guessed one hides the guess inside a precise-looking result. And **the exit line is
what the option costs to stay out of a corner**: an option whose door costs more gives the vendor
more power at every renewal, whether or not anybody ever walks through it. Counting it whole treats
lock-in as what it is — a risk with a price — and lets section 06 of this lesson compare three
options that each carry one.
