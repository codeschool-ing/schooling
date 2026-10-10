---
title: Why adding up estimates gives the wrong date
version: 1
---

The usual way to answer "when will these thirty items be done?" is to estimate each item and add the estimates. It feels rigorous: thirty careful numbers, one sum. It is wrong in three separate ways, and each one pushes the date in the same direction, earlier than reality.

## The estimates leave out the waiting

An estimate says how much work an item needs. Lesson 2 found that most of an item's time on a board is waiting: in the backlog, in a review queue, for a deployment, behind its owner's other items. Under the Billing team's old rules, items needing about two days of work took a median of 18. **Adding estimates of work forecasts the work and forgets the waiting**, and the waiting was most of it.

## Items do not happen one after another

The sum assumes items are done in a line. A team does several at once, so the total time is not the sum of the items' times; dividing by "how many people we have" is the usual correction, and it brings back lesson 12's mistake of assuming everybody is fully available. The relationship between how many items are open, how fast they finish and how long they take is Little's law, and it says the date depends on **throughput**, not on any item's duration.

## Uncertainty does not add the way numbers do

Suppose every item has a 50% chance of finishing within its estimate. The chance that **all thirty** do is a fraction of a percent. Adding the medians gives a total that is very unlikely to be met. Adding pessimistic estimates instead, say each item's 85th percentile, overshoots in the other direction, because the slow items and the fast ones partly cancel. **Percentiles do not add.** The only way to get the 85th percentile of a total is to look at the distribution of totals, and that needs a simulation.

## What to use instead

The team already has the one number that includes all the waiting, all the parallel work and all the interruptions: **how many items it actually finished, day by day**. A forecast built from that history does not need anybody to know how the waiting happened. It only needs the future to resemble the recent past, which the rest of this lesson tests, and a way to turn a history of days into a distribution of futures. That way is called Monte Carlo, after the casino, because it works by drawing at random.
