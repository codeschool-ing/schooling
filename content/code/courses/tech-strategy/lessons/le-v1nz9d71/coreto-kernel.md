---
title: Coreto's second draft
version: 1
---

Davi threw the first draft away and spent a week with the incident log, the deploy history and the
team leads — asking this time what hurt rather than what they wanted. What he found was not six
problems of equal weight. **It was one problem showing up in six places.**

## The diagnosis

Coreto's business is concentrated in moments. A popular show goes on sale at 10:00 on a Tuesday, and
a large part of the month's revenue for that venue arrives in the next half-hour. Coreto runs about
twelve of those big on-sales a year, and they are where the company's reputation is made or lost.

The incident reports all pointed at the same code. When a buyer picks a seat, `coreto-core`'s
reservation module holds it while they pay, and it does so by locking rows in the database. Under an
on-sale's load the locks queue, checkout times out, and buyers see seats vanish and reappear. Every
team edits that module — Checkout, Box Office, Mobile and Payments all have features that touch a
seat hold — so nobody owns it, and each change is reviewed by whoever happens to be nearby.

Davi wrote the diagnosis in three sentences:

> Coreto earns its reputation in about twelve big on-sales a year, and those are exactly when it
> fails. The failures come from the seat-hold code in the reservation module, which every team
> changes and no team owns. Everything else on the teams' lists is real, and none of it costs us a
> venue the way a failed on-sale does.

It is checkable: the incident log either confirms that the on-sale failures trace to seat holds, or
it does not. And it ranks: it says outright that the other problems are smaller.

## The guiding policy

> Protect the on-sale first. Until the seat-hold path survives an on-sale's load, work on that path
> comes before any other technical investment, and nothing ships to it without evidence from a
> load test.

Ask what this rules out, and the answers are concrete. **The microservices migration does not
start this year** — not because microservices are wrong, but because a company-wide migration
would take every team's attention away from the one path that matters. The front-end framework
waits. A cloud-cost project can go ahead only if it does not touch the reservation path during the
on-sale season.

## The coherent actions

1. **Give the reservation module an owner.** Four engineers from Checkout and Payments form a
   Reservations team from 1 March. Changes to the seat-hold code need their review.
2. **Build the load test before changing the code.** The Platform team builds a repeatable test
   that replays an on-sale's traffic, so every change to the path can be measured against it.
3. **Pay down the seat-hold debt.** The new team spends its first two quarters removing the row
   locks from the hold path, measured by the load test.
4. **Freeze the path during on-sales.** No deploys to the reservation module in the 24 hours
   before a big on-sale, by rule rather than by asking.

These reinforce each other. The owner makes the review rule possible; the load test makes the debt
work measurable and makes the deploy freeze less necessary over time; the freeze buys safety while
the work is under way. Remove any one and the others work worse. Compare that with the first draft,
where removing line 5 would change nothing about lines 1 to 4.

## What happened to the goals

Some of the first draft survived, demoted from strategy to consequence. **"Reach 99.99% availability"
became a way to know whether the strategy is working**, measured on on-sale days rather than
averaged over a month. "Pay down technical debt" became one specific debt with a team on it.
"Migrate to microservices" left the document, and Davi wrote down that it had — lesson 3 is about
that list of things a strategy will not do, and why it belongs on the page.

The second draft upset two team leads, whose projects now wait a year. That is the price of a
document that chooses, and a first draft that upset nobody had not paid it.
