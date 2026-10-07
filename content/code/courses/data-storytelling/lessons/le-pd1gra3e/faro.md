---
title: The case this course carries
version: 1
---

Every lesson in this course works on the same analysis, so that the techniques are seen on something
that stays still. It is Faro's, and it is invented: the company, the people and the counts are this
course's own, generated so that they behave like real subscription data.

## The question and the data

**The question:** why do new subscribers cancel in their first ninety days?

**The data:** every subscriber who joined Faro between January and June 2025, 6,113 people, followed for
ninety days after their first box. For each one, the analysis recorded the region (the city of São Paulo,
called *capital*, or the rest of the state, *interior*), whether the first delivery arrived by the date
promised at checkout, and whether the subscription was cancelled within ninety days.

Aggregated by month, region and first delivery, it is twenty-four rows. This is the whole table, and you
will use it from the next section on:

```
cohort,region,first_delivery,subscribers,cancelled_90d
2025-01,capital,on time,546,83
2025-01,capital,late,92,33
2025-01,interior,on time,329,65
2025-01,interior,late,96,45
2025-02,capital,on time,515,80
2025-02,capital,late,87,34
2025-02,interior,on time,280,55
2025-02,interior,late,91,37
2025-03,capital,on time,570,95
2025-03,capital,late,85,34
2025-03,interior,on time,293,56
2025-03,interior,late,85,35
2025-04,capital,on time,516,78
2025-04,capital,late,81,33
2025-04,interior,on time,290,59
2025-04,interior,late,90,38
2025-05,capital,on time,563,94
2025-05,capital,late,78,29
2025-05,interior,on time,301,67
2025-05,interior,late,104,49
2025-06,capital,on time,534,88
2025-06,capital,late,75,30
2025-06,interior,on time,318,61
2025-06,interior,late,94,42
```

## What it says

| | subscribers | cancelled in 90 days | rate |
|---|---|---|---|
| first delivery late | 1,058 | 439 | **41.5%** |
| first delivery on time | 5,055 | 881 | **17.4%** |
| all new subscribers | 6,113 | 1,320 | 21.6% |

So **17.3% of new subscribers got their first box late, and those customers cancelled at 2.4 times the
rate of the others**. That is the finding.

## The people

Five people meet this analysis over the course, and each one wants something different from it:

- **Marina**, the data analyst who did the work and has to get it acted on.
- **Paulo**, director of operations, who chairs the meeting and owns the budget for delivery.
- **Sandra**, head of logistics, whose team's measure is the share of all deliveries made on time:
  94.5% in the same six months.
- **Renata**, the finance director, who thinks in margin and payback.
- **Ligeiro**, the regional carrier that makes most of Faro's deliveries, an outside company with its
  own contract and its own targets.

Sandra's 94.5% and Marina's 17.3% are both correct, and lesson 2 starts from the fact that they seem to
contradict each other.
