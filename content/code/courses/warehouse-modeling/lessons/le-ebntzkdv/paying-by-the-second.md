---
title: Paying by the second
version: 1
---

Snowflake bills compute in **credits**, consumed while a virtual warehouse runs, whatever it is doing. Its
documentation, read on 6 October 2026, gives the two rules that shape a bill:

- an **X-Small warehouse consumes 1 credit per hour** of running, and each size up **doubles** it: Small 2,
  Medium 4, Large 8, X-Large 16;
- credits are billed **per second, with a minimum of 60 seconds** each time a warehouse starts or resumes.

The price of a credit depends on the edition and the region, and is not a number this course can quote for
every reader; the arithmetic below is in credits.

| warehouse | credits per hour | a query of 2 minutes | the same work, if the size halves the time |
|---|---|---|---|
| X-Small | 1 | 0.033 | — |
| Small | 2 | 0.067 | 0.033 (1 minute) |
| Medium | 4 | 0.133 | 0.033 (30 seconds, billed as 60: 0.067) |

The last column is the subtle part. **If a query parallelises perfectly, doubling the size halves the time
and the cost stays the same**: twice the credits per hour for half as long. Lesson 7's Amdahl's law says it
will not parallelise perfectly, so in practice a larger warehouse costs somewhat more per query and returns
the answer sooner. And the 60-second minimum means a warehouse resumed for a three-second query is billed
for a minute.

Three habits follow from that billing model, and none of them is about SQL:

- **Suspend when idle.** A warehouse that runs all night with nothing to do costs the same as one that is
  busy. Auto-suspend after a minute or so of idleness is the usual setting.
- **Size for the work, not the worst day.** Resize up for the month-end load, back down afterwards.
- **Separate warehouses for separate workloads**, so a heavy batch job does not make the dashboards wait, and
  each team's credits can be seen on its own.

**What the model contributes is the same as anywhere**: a query that reads less runs for less time, and
in Snowflake time is the bill. Clustering, narrow queries and pre-built aggregates all reduce seconds.
