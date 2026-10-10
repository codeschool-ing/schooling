---
title: A roadmap is not a strategy
version: 1
---

The most common thing presented as a technical strategy is a roadmap: a row of quarters with
projects in them, perhaps with a vision statement on the slide before. It looks like a plan, it has
dates, and it can be executed. **What it cannot do is say why.** A roadmap answers "what, and
when". A strategy answers "why this, and not that". The two questions need each other, and neither
document can answer the other's.

## Coreto's roadmap before the strategy

Before Davi's draft, Coreto's engineering roadmap for the year read like this:

| quarter | project |
|---|---|
| Q1 | extract authentication from the monolith into a service |
| Q2 | pilot the new front-end framework in Catalogue |
| Q3 | cloud cost reduction |
| Q4 | move Catalogue search to its own service |

Every item was real work, staffed and estimated. Now ask of it the questions lesson 1 asked of the
first draft. **Why authentication first?** Because the Platform team had wanted to do it for a
while. Why Catalogue for the framework pilot? Because Catalogue had volunteered. What does the
roadmap say about the on-sales that fail at checkout? Nothing at all: the one problem that cost
Coreto venues is absent from the year's plan, and nobody could have pointed that out by reading the
roadmap, because a roadmap does not state a problem to be checked against.

**A roadmap with no strategy behind it can be executed
perfectly and still be the wrong year.** Each quarter delivers what it promised, the slide turns
green, and the challenge that mattered is exactly where it was.

## What a roadmap does well

None of this makes a roadmap a bad document. It does three things a strategy does not.

It **sequences**. The strategy says the load test comes before the work on the row locks; the
roadmap puts each in a quarter and shows the dependency.

It **lines engineering up with everybody else**. Sales promises a festival that the on-sale will
hold; product plans a feature around it; finance plans hiring around the Reservations team. They
all plan against the roadmap, because it has dates and the strategy does not.

It **absorbs change cheaply**. When the load test takes a month longer than planned, the roadmap
moves and the strategy does not. That is the right way round. A strategy rewritten every time a
date slips was never a strategy; it was the roadmap again.

Lesson 11 of the `delivery-metrics` course covers putting honest dates on a roadmap, with confidence intervals
rather than single days. This course is about the document above it.

## The same work, derived from the strategy

After the strategy, Coreto's roadmap changed in what it contained and in how each line could be
defended:

| quarter | project | why, from the strategy |
|---|---|---|
| Q1 | Reservations team formed; Platform builds the on-sale load test | actions 1 and 2 |
| Q2 | remove row locks from the seat-hold path, measured by the load test | action 3 |
| Q3 | finish the row locks; deploy freeze before big on-sales automated | actions 3 and 4 |
| Q4 | cloud cost work, off the reservation path | permitted by the policy, outside the on-sale season |

Authentication left the roadmap and so did the framework pilot. **The Platform team lost its
project, and the roadmap can now say why**: the policy puts work on the on-sale path ahead of other
technical investment, and the Platform team's time went to the load test. That answer exists only
because a strategy exists above the roadmap. Without one, the only available reason is who asked
first or who asked loudest.

## Three ways to tell them apart

When somebody hands you a document called a strategy, three quick checks tell you which one you are
holding.

| check | a strategy | a roadmap |
|---|---|---|
| Does it name a problem somebody could check? | yes, in the diagnosis | rarely; it names deliverables |
| When a date slips, does it change? | no | yes |
| Can it explain why something is *absent*? | yes; the policy rules it out | no; absence has no reason on a roadmap |

The third check is the sharpest. Ask why the front-end framework is not on this year's plan. A
strategy has an answer, and it is the same answer for every team. A roadmap on its own has only a
shrug, or a different story each time somebody asks.

## The opposite failure

The reverse also happens. A strategy can be written, signed and admired, and never reach a roadmap
at all: no quarter carries its actions, no team's sprint contains its work. That strategy is
decoration, and it is harder to spot than the first failure, because the document itself looks
fine. The only way to find it is to follow the work down from the strategy and up from the
backlog, which is the next section.
