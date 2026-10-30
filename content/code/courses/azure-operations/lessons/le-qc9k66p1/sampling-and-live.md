---
title: Sampling, ItemCount, and live metrics
version: 1
---

**A busy application does not send every request to Application Insights; it sends a sample.** The SDKs
and the OpenTelemetry distribution can keep, say, one operation in four, and every row they do send then
carries **`ItemCount = 4`**: this row stands for four. Sampling is decided per operation, so a kept request
keeps all its dependencies and a dropped one drops them all, which is what keeps the previous section's
joins correct.

The cost of forgetting `ItemCount` is easy to show. `SampledRequests` is the week as a 25% sample would
have stored it, built from the full table by keeping one operation in four:

```kql
// sampled.kql: the same week as a 25% sample would have stored it
.set-or-replace SampledRequests <|
AppRequests
| where abs(hash(OperationId, 4)) == 0
| extend ItemCount = 4
```

```

```

`count()` on the sample says 62,764 requests; `sum(ItemCount)` says 251,056, close to the true 249,717.
**Every count over sampled data is `sum(ItemCount)`, never `count()`.** The failures show the other side
of sampling: 346 in all became 85 rows standing for 340, an estimate within 2% here. For a rare event, a handful a day, the estimate can be badly off or a failure can vanish from the sample altogether.
That is why the shop samples its successful `GET /products` requests and keeps every failure and every
checkout: ingestion sampling rules and the SDK's settings can exclude telemetry types from sampling.

## Live metrics

**Live metrics** is Application Insights' view of the last minute: requests, failures, dependency calls
and CPU, per second, streamed from the application's SDK straight to the portal **without passing through
the workspace and without sampling**. It costs nothing in ingestion and keeps nothing: close the page and
the data is gone. Its use is the moment of a deployment or a swap, lesson 3's fifteen minutes, when you
want to see the failure rate the second it moves rather than a few minutes later in a query. It needs a
running application and a portal, so it was **not run** for this course.
