---
title: From one failure to all of them
version: 1
---

One request is a story; a cause has to hold for the incident. **Join every failed request of the hour to
the calls it made**, and group by what those calls answered:

```kql
// cause.kql: what the failed requests' calls answered, during the incident
AppRequests
| where TimeGenerated between (datetime(2026-10-15 17:00) .. 1h) and not(Success)
| join kind=inner AppDependencies on OperationId
| summarize failed_requests = dcount(OperationId) by DependencyType, Target, DependencyResult = ResultCode1
```

```

```

`join kind=inner` keeps only the failed requests that made calls; a column both tables have, `ResultCode`,
comes back from the right side as `ResultCode1`, which the query renames. `dcount()` counts distinct
operations, so a request with two calls is counted once.

**103 failed requests, every one of them with a SQL call that timed out.** None of the failures in that
hour involved the payment provider, and none was a failed request with a healthy SQL call. That is the
cause, stated as a count rather than an impression. The second query widens to the week, and teaches something
about percentiles on the way: **the SQL dependency's daily 95th percentile hardly moved**, 61 ms on Thursday
against 60 on the other days, because 103 slow calls among 8,872 are barely more than one in a hundred. The
failures column is the one that sees Thursday. Lesson 15 asks what changed at 14:02 that afternoon.

The method is the one to keep: **start from the symptom table, join to the cause table on the operation,
and let the grouping say whether the explanation covers everything.** An explanation that covers 80 of 103
is a partial one, and the other 23 are the next question.
