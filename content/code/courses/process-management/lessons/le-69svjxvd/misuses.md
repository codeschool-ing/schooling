---
title: Four ways points are misused
version: 1
---

Story points are a planning tool for one team. Most of the harm associated with them comes from using them for something else, and four misuses account for most of it.

## Comparing teams

Team A's velocity is 40 and team B's is 25. Is A more productive? **The question has no answer.** Each team's points are calibrated against its own reference stories; team A's 2-point story may be team B's 1. Comparing velocities across teams compares two private units of measurement. Ranking teams by velocity produces a predictable result: within a few Sprints, every team's velocity rises, and nothing else changes.

## Making velocity a target

Asking a team to raise its velocity by 10% next quarter is asking it to give the same work bigger numbers. It will, without anybody lying: estimates drift upwards a little each time a number is in doubt. This is **Goodhart's law** — when a measure becomes a target, it ceases to be a good measure — and lesson 13 meets it again in delivery metrics. Velocity is useful for forecasting precisely because nobody is trying to change it.

## Converting points to hours

A fixed rate — one point equals six hours — turns story points into time estimates with an extra step, and brings back every weakness relative sizing was meant to avoid. It also creates a second hidden target: a 5-point story that took 40 hours becomes a story somebody has to explain. If an organisation needs estimates in time, it should ask for estimates in time, openly.

## Points per person

Attributing points to individuals — this developer finished 14 points, that one 6 — measures who picked up which stories, not who contributed what. The developer who spent the Sprint unblocking others, reviewing, and fixing the incident that took the service down scores zero. Measuring people by points teaches them to stop doing exactly the work that makes a team effective, which is why `delivery-metrics` gives a whole lesson to the trap of measuring an individual's productivity.

## What velocity is for

Velocity has one legitimate use: **a team forecasting its own future from its own past**, as this lesson's fourth section did. Any other use should be treated as a warning sign, and an architect or lead who sees one is in a good position to say so, because the people misusing the number usually believe they are being rigorous.
