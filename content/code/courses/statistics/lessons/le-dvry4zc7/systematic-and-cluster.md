---
title: Systematic and cluster samples
version: 1
---

Two more methods turn up in practice, each with a strength and a trap.

## Systematic sampling

A **systematic sample** takes every *k*-th member of a list, after a random start. To sample 40 of 400 orders, pick a random start between 1 and 10 and take every 10th order from there: the 7th, 17th, 27th and so on.

It is easy to carry out — a clerk with a printed list can do it — and on most lists it behaves like a simple random sample.

**The trap is a list with a rhythm.** If Horta's daily records are sampled every 7th day, every chosen day is the same day of the week. Start on a Monday and the sample is all Mondays, and Mondays are not typical days for a grocer. Whenever the list has a cycle — days of the week, shifts, the order in which a machine fills bags from two nozzles — a step that matches the cycle produces a sample that is badly biased and looks perfectly orderly.

## Cluster sampling

A **cluster sample** picks whole groups at random and then takes members from the chosen groups only. To survey customers in person, Horta could pick a few neighbourhoods at random and visit customers only there. Travel costs fall dramatically.

The price is variability. Clusters are usually internally similar — neighbours are alike — so a few clusters carry less information than the same number of members spread across the population. On the 120 deliveries, taking 20 from one randomly chosen neighbourhood gives sample means with a standard deviation of **9.22 minutes**, against 2.20 for a simple random sample of 20 and 1.04 for a stratified one.

## Strata versus clusters

The two look alike, since both split the population into groups, and they work in opposite ways.

| | stratified | cluster |
|---|---|---|
| groups used | all of them | a few, chosen at random |
| members taken | some from every group | from the chosen groups only |
| best when groups are | alike inside, different from each other | each a small copy of the population |
| effect on precision | better than simple random | usually worse, but cheaper |

Large national surveys often combine them: clusters of areas first, strata within them, and random selection at the last step.
