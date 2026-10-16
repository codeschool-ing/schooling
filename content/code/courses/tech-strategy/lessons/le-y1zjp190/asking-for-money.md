---
title: Asking for money
version: 1
---

The usual engineering request for money describes the technology: "we need to refactor the
reservation module", "we need a load-testing environment", "we need two more people on Platform".
Each is true, and each reaches a finance reader as a cost with no return attached. **Otávio refuses
requests like these for a plain reason: he cannot compare them with anything.** Every other request on his desk says what it returns.

The fix is to write the request in the units of the budget: a line, an amount, a start date, and
what the company gets back.

## What a finance reader needs

Six questions cover almost every request, and the request answers them in this order:

| question | what a good answer looks like |
|---|---|
| Which line? | one of the four, named |
| How much, from when? | reais a year, starting in a month somebody can put in a plan |
| What does it return? | money saved, money earned, or a risk reduced, with a number where there is one |
| What waits? | the work that does not happen because this does |
| What happens without it? | the cost of saying no, in the same units |
| What is the smallest version? | the part worth doing even if the rest is refused |

The fourth question is the one engineering requests leave out most often, and the one a CFO checks
first. **Most requests are not for new money at all**; they are for people already on the payroll
to stop doing one thing and start another. That is still a cost, and it is paid in whatever those
people stop doing. Lesson 13 gives it a name and a price.

## Coreto's request

Lesson 1's strategy needs a Reservations team: four engineers from Checkout and Payments, from
1 March, removing the row locks from the seat-hold path. Davi writes the request with the numbers
lesson 5 produced:

> **Request: a Reservations team from 1 March**
>
> Line: People. No new hires: four engineers move from Checkout and Payments. Their cost,
> R$ 1,056,000 a year, is already in the budget.
>
> What it returns: the seat-hold debt is paid down in the team's first two quarters. Lesson 5
> priced its principal at 320 hours, R$ 48,000, and its interest at 31 hours a sprint across the
> teams that touch it: R$ 120,900 a year that stops being paid. At that rate the work pays for
> itself in 10.3 sprints.
>
> What waits: Checkout and Payments lose four people's capacity. Pix in instalments and the
> partner API move back; lesson 13's ordering shows by how much.
>
> Without it: big on-sales keep failing in the seat-hold code, about twelve times a year at
> risk, and every team keeps paying the interest.
>
> Smallest version: two engineers for one quarter, building the owner's review rule and the
> load test, with the rest decided on the results.
>
> How we will know: the on-sale load test passes at a traffic level agreed with Platform, and
> checkout errors on on-sale days fall.

Read it as Otávio would. The cost is people the company already pays, so the decision is about
where they work, not whether to spend. The return has a number and a payback period. **R$ 48,000 of
work to stop paying R$ 120,900 a year** is a sentence a CFO can repeat to his own board without an
engineer in the room.

## The number it leaves out

The interest is the smaller part of the case. What makes the seat-hold work urgent is the on-sale
that fails, and Davi's request says that in words — "about twelve times a year at risk" — because he
has not yet priced it. A failed on-sale has a cost in refunds, lost fees and venues that leave, and
putting a probability and an amount on it is lesson 20's subject. Until then, the request is honest
about which part is measured and which part is argued.

That honesty is worth keeping. **A request that inflates its return to win is spending trust it
will need for the next one**, and the CFO who discovers one invented number discounts every number
that follows. Architect-communication lesson 4 is about translating a technical risk into a
business one; this lesson's job is the budget around it.

## When to ask

A request competes with every other request for the same year's money, and the competition happens
while the budget is being made. A request that arrives in the middle of the year asks Otávio to
reopen a decision he has already defended, so it starts with a disadvantage the same request would
not have had a season earlier.

**Ask when the budget is drawn up, and ask in its terms**: per year, in reais, against a line Otávio
already has. A request that does all of that and is still refused has at least produced a decision
somebody can explain, which is more than the request for "a refactoring" ever does.
