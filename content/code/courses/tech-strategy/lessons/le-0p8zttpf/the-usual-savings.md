---
title: The usual savings, and the one that pays first
version: 1
---

Once teams can see their share of the bill, the first savings appear almost on their own, and they
are rarely clever. The common belief is that cloud savings come from a large project — a new
architecture, a migration to a cheaper service, a hard negotiation over discounts. Those exist, and
they come last. **The first savings come from paying for things nobody uses**, and finding them
takes a list and an afternoon.

## Coreto's staging environments

The first showback put Checkout at R$ 67,191 for the month, and Mateus Araújo, Checkout's tech
lead, went through his team's resources line by line. The largest surprise was not in production.
The staging environments — copies of the system that teams test against before a release — ran
twenty-four hours a day, seven days a week, and were used in working hours. Across the teams,
staging that sat idle at night and over the weekend cost **R$ 9,800 a month**.

That is R$ 117,600 a year, for machines nobody was looking at. The fix was a schedule: staging
turns off in the evening and on in the morning, and a team that needs it at night switches it on
for itself.

Put the saving in proportion, using the numbers from lesson 11. R$ 117,600 is 4.6% of the year's
cloud bill of R$ 2,544,000, and 6.8% of the R$ 1,738,400 that a 10% budget cut would have asked
for. **Worth doing the same week, and nowhere near a budget strategy.** Both halves of that sentence
matter: the saving is real money for an afternoon's work, and nobody should present it as the
answer to a request of a different size.

## The list, in the order to work through it

| saving | what it is | effort | when |
|---|---|---|---|
| idle resources | environments, disks, old snapshots and test machines nobody uses, or uses only in working hours | low: a list, an owner, a schedule | first |
| rightsizing | machines and databases larger than their real load, usually sized for a peak long past | low to medium: measure the load, resize, watch | second |
| commitments | paying in advance for a year or more of steady capacity, in exchange for a lower rate | low effort, a real financial commitment | third, and only for what is left |
| architecture | changing how a service is built so it needs less | high: engineering time, priced as lesson 11 prices it | last, and only with the arithmetic done |

**The order is the lesson.** Commit to a year of capacity before removing the idle machines and you
have signed a contract for the waste. Rightsize before turning things off and you spend effort
tuning machines that should not exist. Architecture comes last because it is the only line where
the saving has to beat a large cost in engineering hours, and lesson 11's arithmetic applies: two
engineers for a quarter is R$ 132,000 of time before anything has been saved.

A commitment is the one item on the list whose mechanism changes most often. Every provider offers
some way to pay less in exchange for promising to use more, the names and terms change every few
years, and the details belong to your provider's current documentation rather than to a course. The
principle is stable: **commit to what the unit cost says you will use, after the waste is gone.**

## Why savings come back

The staging schedule saved R$ 9,800 in its first month. Left alone, a saving like that decays:
somebody needs staging on for a late release and leaves it on, a new team creates an environment
outside the schedule, the next incident adds a replica that is never removed. **A saving that
depends on people remembering is a saving for a quarter.**

This is the operate phase from the first section of this lesson, and at Coreto it took three
forms. Staging is off by default, so leaving it on takes an action rather than forgetting one. Every
new resource without a tag shows up in the untagged percentage the next month, with Davi and
Rafaela's names beside it. And the bill has a standing slot in the monthly meeting of team
leads, opened with two numbers: the cost per ticket, and each team's share.

None of that is expensive. It is the difference between FinOps as a project, which ends, and FinOps
as a habit, which keeps the bill readable after the people who first read it have moved on to
other work. The drill that follows puts the four sections together.
