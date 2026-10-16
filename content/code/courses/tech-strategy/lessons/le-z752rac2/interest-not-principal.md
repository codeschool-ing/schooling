---
title: The interest, not the principal
version: 1
---

Ask a team for its technical debt and it hands you a list with a size beside each item: 320 hours to
fix the seat-hold locking, 200 for the old reporting replica, 120 for the PDF ticket generator. That
size is the debt's **principal**, what it would cost to pay the thing off. It is the number every
debt register carries, and on its own it persuades nobody, because nothing in it says what happens
if the work is never done.

Lesson 4's metaphor came from Ward Cunningham, and it had two parts. Shipping code you know is not
right is borrowing; every hour spent working around it afterwards is **interest**. The principal is
paid once, and only if somebody decides to pay it. The interest is paid whether anybody decides or
not, sprint after sprint, by whoever happens to touch the code.

## Two numbers for each debt

| | principal | interest |
|---|---|---|
| what it is | the hours to pay the debt off | the extra hours spent each sprint because it is still there |
| when it is paid | once, if somebody decides to | every sprint, without anybody deciding |
| who sees it | whoever estimates the fix | nobody in particular: it is spread across everyone who works near the code |
| what it answers | how much would it cost? | how much is it costing? |

Coreto has four debts that the team leads agree are real. Here they are with both numbers, in hours
and in reais at the R$ 150 engineer-hour from lesson 1:

| debt | principal | interest a sprint |
|---|---|---|
| Seat-hold locking in the reservation module | 320 h (R$ 48,000) | 31 h (R$ 4,650) |
| Hand-rolled PDF ticket generator | 120 h (R$ 18,000) | 6 h (R$ 900) |
| Flaky end-to-end suite | 80 h (R$ 12,000) | 14 h (R$ 2,100) |
| Old reporting replica | 200 h (R$ 30,000) | 4 h (R$ 600) |

Read only the principal column and the reporting replica looks like Coreto's second-biggest problem.
Read the interest column and it is the smallest, at 4 hours a sprint. **The flaky end-to-end suite,
the cheapest debt to fix, charges three and a half times the replica's interest** — 14 hours against
4.

## Why the principal misleads

A bank loan has a date on which it falls due. A debt in code has none. Nothing happens on the day a
team decides not to fix the replica, and nothing happens the day after. So a list sorted by principal
is a list of how expensive each fix looks, and the most expensive fixes look like the biggest
problems. They are only the biggest bills somebody might one day choose to pay.

**Debt in code nobody touches charges no interest.** Interest is paid on change: an engineer pays it
when they open the module, work around the oddity, wait for the slow test or fix the incident it
caused. A tangled module that nobody has edited for years costs nothing this sprint, however
unpleasant it is to read, and paying off its principal buys nothing back. Lesson 4 drew the line
between debt and a mess; this is the same line, drawn in money.

The reverse holds too. A debt with a modest principal sitting in code that every team edits every
week is expensive, and a register that lists only principals will rank it near the bottom.

## The language the money is spent in

A principal is a request: give us 320 hours. An interest is a fact about the present: we already
spend 31 hours a sprint on this, and will keep spending them. Davi took the seat-hold debt to Otávio
Lins, the CFO, in the second form:

> The seat-hold locking costs us 31 engineer-hours every sprint — R$ 4,650 a sprint, R$ 120,900 a
> year — and it keeps costing that until we spend 320 hours, R$ 48,000, once.

Otávio read that as a recurring cost set against a one-off investment, which is the shape of most
decisions that reach a CFO's desk. Described as "320 hours of refactoring", the same debt reads as
engineers wanting to tidy up. **The arithmetic is the same in both versions, and only the second
answers the question a budget asks**: what happens if this money is not spent?

## What the hours leave out

Hours are not the whole of the interest. The seat-hold debt also fails during big on-sales, and a
failed on-sale costs Coreto sales and venues in a way no time log records. Lesson 20 prices that kind
of risk, as a probability multiplied by a loss, and adds it to the case.

This lesson keeps to the part that can be counted in hours. Most teams never write that part down at
all, and it is already enough to rank the four debts differently from the way their principals rank
them. The next section is where the 31 hours came from, because interest has to be measured, and the
measuring is most of the work.
