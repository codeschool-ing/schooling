---
title: One request, end to end
version: 1
---

**The first thing to do with a failure is to look at one of them whole.** Take the first failed checkout
of the incident, and everything with its `OperationId`:

```kql
// one-request.kql: everything recorded for the first failed checkout of the incident
let op = toscalar(
    AppRequests
    | where Name == "POST /checkout" and not(Success) and DurationMs > 2000
    | top 1 by TimeGenerated asc
    | project OperationId);
union
    (AppRequests | where OperationId == op | extend Kind = "request", Target = "shop-api"),
    (AppDependencies | where OperationId == op | extend Kind = "dependency")
| project TimeGenerated, OperationId, Kind, Name, Target, ResultCode, DurationMs
```

```

```

`toscalar()` runs the inner query and turns its single value into a constant, which `let` names `op`.
`union` stacks rows from two tables, with `Kind` added so each row says what it is; a column one table
lacks, like `Target` for requests, is filled in so both sides line up.

Read the three rows as a timeline. The request arrived at 17:05:12 and answered 500 after 3,130 ms. Its
one dependency, the `INSERT orders` against the SQL database, took 3,000 ms of that and returned `-2`.
There is no payment call: the order was never written, so the code never reached the payment step.
**The request's 500 is the symptom; the timeout is the cause, one level down.** Application Insights'
*transaction search* and *end-to-end transaction details* in the portal draw exactly this, as a Gantt
chart; the query is the same data without the drawing.

In a real application the request row also has the same timestamp as its first dependency, or nearly:
`TimeGenerated` on a request is when it started. The generated week records them at the same instant,
which is a simplification of this course's data, not of Application Insights.
