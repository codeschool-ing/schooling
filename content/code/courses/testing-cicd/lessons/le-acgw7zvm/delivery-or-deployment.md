---
title: When to deploy every change, and when not to
version: 1
---

Continuous deployment is not the goal for every team, and the reasons not to adopt it are specific.
The useful question is not *are we mature enough?* but **what would go wrong if every green commit
reached users within the hour?**

## Where continuous deployment fits

It fits when four things are true:

1. **Releasing is cheap and reversible.** Going back is a command (lesson 11), and users barely see
   a bad release before it is gone.
2. **The tests carry the confidence.** Everything a person at the gate would check is checked by the
   pipeline.
3. **Changes are small.** A deploy contains one or two merges, so when something breaks, the cause is
   obvious.
4. **Production is watched.** Errors and latency are measured, and somebody, or something, reacts
   (lessons 10 and 11).

For a web service like `shipquote`, all four can be arranged, and teams that arrange them deploy
many times a day.

## Where it does not

- **Mobile apps.** A release goes through a store's review, and users update when they choose. What
  is deployed continuously is the build to testers; what reaches the store is a decision. In the
  `mobile` track, `mobile-delivery` covers staged rollout in the stores.
- **Software installed by customers**, from desktop applications to firmware: nobody can roll back a
  device in somebody's pocket.
- **Regulated changes**, where a named person must approve a release by law or by contract.
- **Coordinated launches**, where a change must go live at a given moment. That is often better
  solved by deploying early behind a **feature flag**, lesson 10, and switching it on at the moment,
  which separates deploying from releasing.

## The test that settles it

Whatever the team chooses, one property matters more than the label: **could you release `main` right
now, safely, in minutes?** If yes, the team has continuous delivery, and whether a person or a rule
presses the button is a choice it can revisit. If no, because releasing takes a weekend, a freeze or a
checklist that only one person understands, then neither label applies, and the work is to make
releasing boring.
