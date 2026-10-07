---
title: Ways of paying it down
version: 1
---

Once a debt is agreed to be worth paying, there are several ways to pay it, and they suit different debts. Choosing the wrong one is a common reason that repayment efforts fail.

## Continuously, in the code you touch

The **Boy Scout rule**, popularised by Robert C. Martin: leave the code a little cleaner than you found it. Every change to a messy module includes a small improvement — a clearer name, a duplicated rule pulled into one place, a missing test added. It costs a few percent on each change and needs no negotiation, because it happens inside work already agreed.

It works well for debt spread thinly through code the team changes often, which is where most of the interest is paid. It does nothing for debt in code nobody touches, which, as this lesson's second section argued, mostly costs nothing anyway.

## A reserved share of capacity

Lesson 12 described **capacity allocation**: a fixed share of each Sprint, often around a fifth, kept for technical work the team chooses. It suits a steady stream of medium-sized items — the deployment automation, a library upgrade — that are too big for the Boy Scout rule and too small to argue for one at a time.

## A dedicated piece of work

Some debt is large enough to be a project of its own: replacing the flaky test infrastructure, splitting the single database by clinic. These go into the backlog as items with their own business case, prioritised with WSJF or RICE against features, as lesson 12 showed, and are delivered like any other large item: broken into slices, each of which leaves the system working.

## Replacing a system piece by piece

The largest debts sometimes mean replacing a whole system. The approach that works in most cases is the **strangler fig**, named by Martin Fowler in 2004 after a plant that grows around a tree until it replaces it. You build the new system alongside the old, route one piece of functionality at a time to the new one, and retire the old one when nothing uses it. The system keeps working throughout, and each step can be stopped if priorities change. The `tech-strategy` course gives it a lesson of its own, its seventh, together with the rewrite that is almost never worth it.

## What does not work

Two approaches fail often enough to name. **The cleanup Sprint** — one Sprint a quarter given to debt — is usually spent on what is most annoying rather than what costs most, and the habits that created the debt continue in between. **The big rewrite** — stopping features for months to rebuild — loses the business's patience before it finishes, and often reproduces the old system's problems, because the knowledge embedded in the old code is lost. Both treat debt as an event; it is better treated as a flow, paid down at about the rate it accumulates.
