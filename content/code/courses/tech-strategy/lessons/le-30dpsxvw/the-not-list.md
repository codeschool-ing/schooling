---
title: What we will not do
version: 1
---

A guiding policy rules things out in principle. **The not list names them**, so that nobody has to
work out from the policy what it excludes. It is the shortest section of the page and the one that
costs the most to write, because it is where the choice stops being abstract and lands on
somebody's project.

## The case for leaving it implicit

The usual instinct is to leave the list off. The policy says "protect the on-sale first"; surely
everybody can see that a microservices migration does not fit, and writing it down only rubs it in
for the people whose project it was. A page that says what the company will do, and stays silent
about the rest, reads as positive and starts no arguments.

**It starts them later, one team at a time, without anybody seeing.** Lesson 2 showed what happened
at Coreto in the quarter after the strategy went out: a GraphQL gateway for the mobile app, and
Catalogue search moving to its own service. Each was a sensible project. Each was the microservices
migration arriving by a side door, and each survived into the roadmap because nobody had written
down that the migration was off for the year, including one service at a time. Once that line was
on the page, both projects were recognisable at a glance. Before it, a reasonable person could read
the policy and conclude that one small service did no harm.

An implicit exclusion is decided by every team separately, and they decide differently.

## What makes a good line on the list

A line belongs on the not list when it passes three tests.

**Somebody reasonable wants it.** "We will not neglect security" excludes nothing anybody
proposed; it is fluff with a negation in front. A line earns its place by disappointing a real
person with a real proposal. Every line on Davi's list cost somebody. The microservices migration
was the year's project for Rafaela's Platform team. The front-end framework pilot was the one
Catalogue had volunteered for. The rewrite of the reservation module was what Mateus, the Checkout
tech lead, had been arguing for since the last failed on-sale.

**It names the thing.** "We will deprioritise some modernisation work" leaves every team free to
decide that its own modernisation is not the kind meant. "Move to a new front-end framework" does
not.

**It says how long, or until what.** "Not this year" and "unless the change has passed the load
test" tell a team when to bring the proposal back and what would change the answer. A bare "no"
reads as permanent, and it gets argued with as if it were.

| weak line | what is wrong | a line from Davi's page |
|---|---|---|
| We will not neglect reliability. | nobody proposed neglecting it | Rewrite the reservation module from scratch. |
| We will limit architectural change. | names nothing; every team exempts itself | Start the migration to microservices, including one service at a time. |
| No changes to reservations. | no scope and no end; blocks the work the strategy needs | Change the reservation path in the on-sale season for cost or for features, unless the change has passed the load test. |

The last row is the subtle one. A line that forbids too much forbids the strategy's own actions:
the Reservations team has to change the reservation path, that is its whole job. The line on the
page excludes changes made for other reasons, in the season when they are dangerous, without the
evidence the policy asks for.

## Telling people before the page does

**Nobody whose project is on the not list should learn it from the page.** Davi talked to Rafaela
and to Mateus before the strategy went out, each on their own, and told them what the page would
say and why. Rafaela argued for keeping one service extraction; Mateus argued that a rewrite would
be faster than removing the locks one by one. Neither argument changed the page. Both conversations
changed how the page was received, because neither of them was surprised in front of their team.

The skills for those conversations belong to other courses of this track: lesson 8 of
`architect-communication` is saying no with an alternative, and lesson 24 of `people-leadership` is
managing up and across. Lesson 19 of this course comes back to saying no when the request arrives
from outside engineering. What is particular to the strategy page is the order: the conversation
first, the publication after.

## What the list does over the year

The list goes on working after the page is published, in three ways.

It **settles arguments before they start**. When a proposal for a new service arrives in May, the
answer is on the page, it is the same answer for every team, and nobody has to hold a meeting to
give it.

It **makes the roadmap checkable**. The trace in lesson 2 found its orphans because there was a
line to compare them with. Without the not list, the gateway would have needed an argument; with
it, it needed a glance.

It **marks what is coming back**. "Not this year" is a promise that the question will be asked
again, and the end-of-year review should ask it. If the seat holds are fixed by then, the
microservices question reopens with a new diagnosis behind it, and Rafaela's proposal is the first
one on the table.

A not list that nobody ever complains about has probably been written to avoid complaint, which is
the same failure as the first draft in lesson 1. The useful version upsets a few people on the day
it is published, and saves the company that argument many times over during the year.
