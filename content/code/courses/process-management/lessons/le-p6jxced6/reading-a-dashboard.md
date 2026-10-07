---
title: Reading a dashboard without being fooled
version: 1
---

Most teams end up with a dashboard: cycle time, throughput, the four DORA numbers, perhaps a burndown. A dashboard is useful when the people reading it ask the right questions of it, and a few habits make the difference.

## Ask which question each chart answers

Every chart on the dashboard should be able to finish the sentence *we look at this to decide…*. Cycle time: when to promise an item. Throughput: how much to plan for next quarter. Change failure rate: whether the release process needs work. A chart that finishes no such sentence is decoration, and it costs attention every time somebody reads past it.

## Look at trends and spreads, not points

A single week's number is mostly noise: the Agenda team's throughput moved between 4 and 6 in four ordinary weeks. **A trend over several months is information**; a single point is not. The same applies to spread: a median cycle time of 7 days with an 85th percentile of 11.6 is a different team from one with a median of 7 and an 85th percentile of 30, and a dashboard that shows only the median hides the difference.

## Pair every number with its counterweight

This lesson's third section paired throughput with cycle time, and the DORA metrics come in a pair of pairs. The habit generalises: **for every number that can be improved by a shortcut, show the number the shortcut would damage**. Deployment frequency beside change failure rate; velocity beside escaped defects; tickets closed beside tickets reopened.

## Read the outliers

The items far above the 85th-percentile line, the changes that took more than a day to deploy, the one failure that took three hours to restore: these are where the stories are. A dashboard review that spends its time on averages and none on the outliers learns very little; one that reads the three worst items each month finds most of what is worth fixing.

## Remember what it cannot see

Delivery dashboards measure how work flows through a team. They cannot see whether the work was worth doing, whether the users are happier, whether the system is becoming harder to change. The last of those is the subject of lesson 14, and it is the one a delivery dashboard hides most effectively: a team taking on technical debt can show improving numbers for months, until the cost arrives all at once.
