---
title: What a load costs, and what to do about it
version: 1
---

The four measurements, side by side, with the factor between the methods on this machine:

| decision | slow way | fast way | factor |
| --- | --- | --- | --- |
| writing rows | one `INSERT` per row | `COPY` | about 60 |
| finding a day | reading the whole table | an index on the date | about 650 |
| bringing the table up to date | rebuilding it whole | replacing a 30-day window | about 75 |
| answering for a month | reading six years | reading the month | about 120, in pages read |

Not one of them needed a faster machine, a different database or a cluster. Each is a decision about
**how much work to ask for**. Each was also made somewhere in this course for a reason other than
speed: `COPY` because the raw loader had to be one transaction, the window because the table drifted,
the mart because reports should not join fact tables. Performance mostly comes from not doing work,
and the work most worth not doing is the work a design asks for without anybody noticing.

The order to tackle a slow or expensive pipeline in is the order of this lesson. **Measure** first,
with `\timing` and `EXPLAIN ANALYZE`, and believe the measurement over the intuition. Then **write in
bulk**, **find by an index**, **rebuild only what changed** and **read only what is needed** — and
measure again, because each fix moves the bottleneck somewhere else. Bigger hardware comes after
those, if at all.

And every saving has a price that the earlier lessons already named. An index slows the load that
fills the table. A window misses what falls outside it. A mart is one more thing to keep right.
**Make the trade on purpose, with the numbers in front of you**, and write the reason down where the
next person will look: in the model, beside the setting it explains.
